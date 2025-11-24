from sqlmodel import Session, select, func
from typing import Any, List, Optional, Dict
import traceback
from feedback_models import Feedbacks, CreateFeedbackInput, UpdateFeedbackInput, BatchCreateFeedbackInput, FeedbackDetail
from db_tables import Profiles, TravelGroup
from fastapi import HTTPException
from datetime import date

# valid tags
predefined_tags = ['friendly', 'punctual', 'helpful', 'fun', 'organized', 'late', 'uncooperative']


# -------------------------
# Helper: fetch profile names in batch to avoid N queries
# -------------------------
def _get_profiles_map(session: Session, ids: List[int]) -> Dict[int, Dict[str, Any]]:
    """
    Return dict: profile_id -> { 'fullname': ..., 'auth_user_id': ... }
    """
    if not ids:
        return {}
    stmt = select(Profiles).where(Profiles.id.in_(ids))
    rows = session.exec(stmt).all()
    res = {}
    for r in rows:
        fullname = None
        # try several possible name fields
        if hasattr(r, 'fullname') and r.fullname:
            fullname = r.fullname
        elif hasattr(r, 'name') and r.name:
            fullname = r.name
        elif hasattr(r, 'display_name') and r.display_name:
            fullname = r.display_name
        else:
            fullname = f"user-{r.id}"
        res[r.id] = {
            "fullname": fullname,
            "auth_user_id": getattr(r, "auth_user_id", None)
        }
    return res


# -------------------------
# create feedback
# -------------------------
async def create_feedback_service(session: Session, sender_auth_uuid: str, payload: CreateFeedbackInput) -> Feedbacks:
    try:
        # get sender profile by auth_user_id (UUID string)
        stmt = select(Profiles).where(Profiles.auth_user_id == sender_auth_uuid)
        db_sender = session.exec(stmt).first()
        if not db_sender:
            raise HTTPException(status_code=404, detail="Sender profile not found")

        # recipient by profile.id (int)
        stmt2 = select(Profiles).where(Profiles.id == payload.rev_id)
        db_rev = session.exec(stmt2).first()
        if not db_rev:
            raise HTTPException(status_code=404, detail="Recipient profile not found")

        # validate tags content
        if payload.content:
            invalid_tags = set(payload.content) - set(predefined_tags)
            if invalid_tags:
                raise HTTPException(status_code=400, detail=f"Invalid tags: {invalid_tags}")

        # validate group membership if group_id provided
        if payload.group_id is not None:
            stmt_group = select(TravelGroup).where(TravelGroup.id == payload.group_id)
            group = session.exec(stmt_group).first()
            if not group:
                raise HTTPException(status_code=404, detail="Group not found")

            # safe get members (could be None)
            members = group.members or []
            member_uuids = [m.get('profile_uuid') for m in members if m.get('profile_uuid')]
            # both sender and recipient must be in member_uuids
            if sender_auth_uuid not in member_uuids:
                raise HTTPException(status_code=403, detail="Sender is not a group member")
            if getattr(db_rev, "auth_user_id", None) not in member_uuids:
                raise HTTPException(status_code=403, detail="Recipient is not a group member")

        new = Feedbacks(
            send_id = db_sender.id,
            rev_id = payload.rev_id,
            group_id = payload.group_id,
            group_image_url = payload.group_image_url,
            rating = payload.rating,
            content = payload.content or [],
            anonymous = payload.anonymous or False
        )
        session.add(new)
        session.commit()
        session.refresh(new)
        return new
    except HTTPException:
        raise
    except Exception as e:
        print(f"LỖI (create_feedback_service): {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail="Internal server error when creating feedback")


# -------------------------
# batch create
# -------------------------
async def batch_create_feedback_service(session: Session, sender_auth_uuid: str, payload: BatchCreateFeedbackInput) -> List[Feedbacks]:
    try:
        # ensure sender exists
        stmt_sender = select(Profiles).where(Profiles.auth_user_id == sender_auth_uuid)
        db_sender = session.exec(stmt_sender).first()
        if not db_sender:
            raise HTTPException(status_code=404, detail="Sender not found")

        # group exists
        stmt_group = select(TravelGroup).where(TravelGroup.id == payload.group_id)
        group = session.exec(stmt_group).first()
        if not group:
            raise HTTPException(status_code=404, detail="Group not found")

        members = group.members or []
        member_uuids = [m.get('profile_uuid') for m in members if m.get('profile_uuid')]
        if sender_auth_uuid not in member_uuids:
            raise HTTPException(status_code=403, detail="Sender không phải member")

        created = []
        for fb in payload.feedbacks:
            # validate recipient
            stmt_rev = select(Profiles).where(Profiles.id == fb.rev_id)
            db_rev = session.exec(stmt_rev).first()
            if not db_rev:
                raise HTTPException(status_code=404, detail=f"Recipient {fb.rev_id} not found")
            if getattr(db_rev, "auth_user_id", None) not in member_uuids:
                raise HTTPException(status_code=403, detail=f"Recipient {fb.rev_id} is not a member")
            fb.group_id = payload.group_id
            new = await create_feedback_service(session, sender_auth_uuid, fb)
            created.append(new)
        return created
    except HTTPException:
        raise
    except Exception as e:
        print(f"LỖI (batch_create_feedback_service): {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail="Lỗi khi tạo batch feedback")


# -------------------------
# list / get / update / delete (kept simple)
# -------------------------
async def list_feedbacks_service(
    session: Session,
    rev_id: Optional[int] = None,
    send_id: Optional[int] = None,
    q: Optional[str] = None,
    sort_by: Optional[str] = None,
    order: Optional[str] = "desc"
) -> dict:
    try:
        stmt = select(Feedbacks)
        if rev_id:
            stmt = stmt.where(Feedbacks.rev_id == rev_id)
        if send_id:
            stmt = stmt.where(Feedbacks.send_id == send_id)
        if q:
            # content is array: use simple containment check by converting to text search; fallback to Python filter later
            stmt = stmt.where(Feedbacks.content != None)

        # sort
        if sort_by == "created_at":
            stmt = stmt.order_by(Feedbacks.created_at.desc() if order.lower() != "asc" else Feedbacks.created_at.asc())
        elif sort_by == "rating":
            stmt = stmt.order_by(Feedbacks.rating.desc() if order.lower() != "asc" else Feedbacks.rating.asc())

        all_q = session.exec(stmt)
        all_list = all_q.all()

        # if q provided, simple python-level filter on content string presence
        if q:
            filtered = []
            for f in all_list:
                # content may be list of tags
                if f.content and any(q.lower() in (c or "").lower() for c in f.content):
                    filtered.append(f)
            all_list = filtered

        total_count = len(all_list)
        meta = {"total": total_count}
        if rev_id:
            avg_stmt = select(func.avg(Feedbacks.rating)).where(Feedbacks.rev_id == rev_id, Feedbacks.rating.isnot(None))
            average = session.exec(avg_stmt).one() or 0.0
            meta["average_rating"] = round(float(average), 1)
        return {"meta": meta, "data": all_list}
    except Exception as e:
        print(f"LỖI (list_feedbacks_service): {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail="Internal server error when listing feedbacks")


async def get_feedback_service(session: Session, fid: int) -> Feedbacks:
    try:
        stmt = select(Feedbacks).where(Feedbacks.id == fid)
        obj = session.exec(stmt).first()
        if not obj:
            raise HTTPException(status_code=404, detail="Feedback not found")
        return obj
    except HTTPException:
        raise
    except Exception as e:
        print(f"LỖI (get_feedback_service): {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail="Internal server error when getting feedback")


async def update_feedback_service(session: Session, fid: int, sender_auth_uuid: str, payload: UpdateFeedbackInput) -> Feedbacks:
    try:
        stmt_sender = select(Profiles).where(Profiles.auth_user_id == sender_auth_uuid)
        db_sender = session.exec(stmt_sender).first()
        if not db_sender:
            raise HTTPException(status_code=404, detail="Sender profile not found")

        stmt = select(Feedbacks).where(Feedbacks.id == fid)
        obj = session.exec(stmt).first()
        if not obj:
            raise HTTPException(status_code=404, detail="Feedback not found")

        if obj.send_id != db_sender.id:
            raise HTTPException(status_code=403, detail="Not allowed to update this feedback")

        if payload.rating is not None: obj.rating = payload.rating
        if payload.content is not None:
            invalid_tags = set(payload.content) - set(predefined_tags)
            if invalid_tags:
                raise HTTPException(status_code=400, detail=f"Invalid tags: {invalid_tags}")
            obj.content = payload.content
        if payload.anonymous is not None: obj.anonymous = payload.anonymous

        session.add(obj)
        session.commit()
        session.refresh(obj)
        return obj
    except HTTPException:
        raise
    except Exception as e:
        print(f"LỖI (update_feedback_service): {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail="Internal server error when updating feedback")


async def delete_feedback_service(session: Session, fid: int, sender_auth_uuid: str) -> bool:
    try:
        stmt_sender = select(Profiles).where(Profiles.auth_user_id == sender_auth_uuid)
        db_sender = session.exec(stmt_sender).first()
        if not db_sender:
            raise HTTPException(status_code=404, detail="Sender profile not found")

        stmt = select(Feedbacks).where(Feedbacks.id == fid)
        obj = session.exec(stmt).first()
        if not obj:
            raise HTTPException(status_code=404, detail="Feedback not found")

        if obj.send_id != db_sender.id:
            raise HTTPException(status_code=403, detail="Not allowed to delete this feedback")

        session.delete(obj)
        session.commit()
        return True
    except HTTPException:
        raise
    except Exception as e:
        print(f"LỖI (delete_feedback_service): {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail="Internal server error when deleting feedback")


# -------------------------
# New: get user groups then feedbacks with required fields
# -------------------------
async def get_user_groups_feedbacks_service(session: Session, user_auth_uuid: str) -> List[Any]:
    """
    Trả về list các group mà user (auth uuid) tham gia, kèm feedbacks theo định dạng:
    [
      {
        "group_id": ...,
        "group_name": ...,
        "group_image": ...,
        "feedbacks": [
            { "sender_name": ..., "receiver_name": ..., "rating": ..., "content": [...] },
            ...
        ]
      },
      ...
    ]
    """
    try:
        # 1) Lấy tất cả groups có chứa user_auth_uuid trong members hoặc owner
        stmt_groups = select(TravelGroup)
        all_groups = session.exec(stmt_groups).all()
        user_groups = []
        for g in all_groups:
            owner_matches = getattr(g, "owner_id", None) == user_auth_uuid
            members = g.members or []
            member_uuids = [m.get('profile_uuid') for m in members if m.get('profile_uuid')]
            if owner_matches or (user_auth_uuid in member_uuids):
                user_groups.append(g)

        results = []
        # 2) Lấy feedbacks cho mỗi group
        for g in user_groups:
            stmt_fb = select(Feedbacks).where(Feedbacks.group_id == g.id).order_by(Feedbacks.created_at.desc())
            fbs = session.exec(stmt_fb).all()
            # collect profile ids to batch fetch names
            profile_ids = set()
            for fb in fbs:
                if fb.send_id: profile_ids.add(fb.send_id)
                if fb.rev_id: profile_ids.add(fb.rev_id)
            profiles_map = _get_profiles_map(session, list(profile_ids))

            fb_list = []
            for fb in fbs:
                # sender name: hide if anonymous
                sender_name = "Ẩn danh" if fb.anonymous else profiles_map.get(fb.send_id, {}).get("fullname", f"user-{fb.send_id}")
                receiver_name = profiles_map.get(fb.rev_id, {}).get("fullname", f"user-{fb.rev_id}")
                fb_list.append({
                    "sender_name": sender_name,
                    "receiver_name": receiver_name,
                    "rating": fb.rating,
                    "content": fb.content or []
                })

            # group image field: try common names
            group_image = None
            if hasattr(g, "image_url") and g.image_url:
                group_image = g.image_url
            elif hasattr(g, "group_image") and g.group_image:
                group_image = g.group_image
            elif hasattr(g, "image") and g.image:
                group_image = g.image
            results.append({
                "group_id": g.id,
                "group_name": getattr(g, "name", f"group-{g.id}"),
                "group_image": group_image,
                "feedbacks": fb_list
            })

        return results

    except Exception as e:
        print(f"LỖI (get_user_groups_feedbacks_service): {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail="Lỗi khi lấy user groups feedbacks")


# -------------------------
# get_group_feedbacks_service kept but adjusted to use auth uuid -> rev profile
# -------------------------
async def get_group_feedbacks_service(session: Session, group_id: int, rev_auth_uuid: str) -> List[FeedbackDetail]:
    try:
        # Lấy rev profile by auth uuid
        stmt_rev = select(Profiles).where(Profiles.auth_user_id == rev_auth_uuid)
        db_rev = session.exec(stmt_rev).first()
        if not db_rev:
            raise HTTPException(status_code=404, detail="Recipient profile not found")

        # Lấy feedbacks
        stmt = select(Feedbacks).where(
            Feedbacks.group_id == group_id,
            Feedbacks.rev_id == db_rev.id
        ).order_by(Feedbacks.created_at.desc())
        feedbacks = session.exec(stmt).all()

        # batch fetch senders
        sender_ids = [fb.send_id for fb in feedbacks if fb.send_id]
        profiles_map = _get_profiles_map(session, sender_ids + [db_rev.id])

        details = []
        for fb in feedbacks:
            sender_name = None
            if not fb.anonymous:
                sender_name = profiles_map.get(fb.send_id, {}).get("fullname", f"user-{fb.send_id}")
            else:
                sender_name = "Ẩn danh"
            rev_name = profiles_map.get(fb.rev_id, {}).get("fullname", f"user-{fb.rev_id}")

            # convert Feedbacks -> FeedbackDetail (matching Pydantic) by dict
            obj = {
                "id": fb.id,
                "send_id": fb.send_id,
                "rev_id": fb.rev_id,
                "group_id": fb.group_id,
                "group_image_url": fb.group_image_url,
                "rating": fb.rating,
                "content": fb.content or [],
                "anonymous": fb.anonymous,
                "created_at": fb.created_at,
                "sender_name": None if fb.anonymous else sender_name,
                "rev_name": rev_name
            }
            details.append(obj)
        return details
    except Exception as e:
        print(f"LỖI (get_group_feedbacks_service): {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail="Lỗi khi lấy feedbacks group")
