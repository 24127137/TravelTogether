from sqlmodel import Session, select, func
from typing import Any, List, Optional, Dict
import traceback
from feedback_models import (
    Feedbacks, CreateFeedbackInput, UpdateFeedbackInput, FeedbackDetail,
    MyReputationResponse, GroupReputationSummary, 
    PendingReviewsResponse, PendingReviewGroup, UnreviewedMember
)
from db_tables import Profiles, TravelGroup
from fastapi import HTTPException
from datetime import date

# Valid tags
predefined_tags = ['friendly', 'punctual', 'helpful', 'fun', 'organized', 'late', 'uncooperative']


# ====================================================================
# Helper: fetch profile names in batch to avoid N queries
# ====================================================================
def _get_profiles_map(session: Session, ids: List[int]) -> Dict[int, Dict[str, Any]]:
    """
    Return dict: profile_id -> { 'fullname': ..., 'auth_user_id': ..., 'email': ... }
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
            "auth_user_id": getattr(r, "auth_user_id", None),
            "email": getattr(r, "email", None)
        }
    return res


# ====================================================================
# CREATE FEEDBACK (ĐÃ SỬA: thêm duplicate check + expired check)
# ====================================================================
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

            # ✅ NEW: Check if group is expired
            if group.status != "expired":
                raise HTTPException(
                    status_code=400, 
                    detail="Can only give feedback after the trip has ended (group must be 'expired')"
                )

            # safe get members (could be None)
            members = group.members or []
            member_uuids = [m.get('profile_uuid') for m in members if m.get('profile_uuid')]
            # both sender and recipient must be in member_uuids
            if sender_auth_uuid not in member_uuids:
                raise HTTPException(status_code=403, detail="Sender is not a group member")
            if getattr(db_rev, "auth_user_id", None) not in member_uuids:
                raise HTTPException(status_code=403, detail="Recipient is not a group member")

            # ✅ NEW: Check for duplicate feedback
            existing_feedback = session.exec(
                select(Feedbacks).where(
                    Feedbacks.send_id == db_sender.id,
                    Feedbacks.rev_id == payload.rev_id,
                    Feedbacks.group_id == payload.group_id
                )
            ).first()
            
            if existing_feedback:
                raise HTTPException(
                    status_code=400, 
                    detail="You have already reviewed this person in this group"
                )

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


# ====================================================================
# LIST FEEDBACKS (ĐÃ SỬA: thêm group_id filter)
# ====================================================================
async def list_feedbacks_service(
    session: Session,
    rev_id: Optional[int] = None,
    send_id: Optional[int] = None,
    group_id: Optional[int] = None,  # ✅ NEW: Added group_id filter
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
        if group_id:  # ✅ NEW: Filter by group
            stmt = stmt.where(Feedbacks.group_id == group_id)
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


# ====================================================================
# ✅ NEW: GET GROUP FEEDBACKS (Tất cả feedbacks trong group)
# ====================================================================
async def get_group_feedbacks_service(session: Session, group_id: int, user_auth_uuid: str) -> List[FeedbackDetail]:
    """
    Lấy TẤT CẢ feedbacks trong 1 group (sender → receiver).
    User phải là member hoặc owner của group.
    """
    try:
        # Validate user is member of this group
        user_profile = session.exec(
            select(Profiles).where(Profiles.auth_user_id == user_auth_uuid)
        ).first()
        if not user_profile:
            raise HTTPException(status_code=404, detail="User profile not found")

        group = session.get(TravelGroup, group_id)
        if not group:
            raise HTTPException(status_code=404, detail="Group not found")

        # Check membership
        members = group.members or []
        member_uuids = [m.get('profile_uuid') for m in members if m.get('profile_uuid')]
        is_owner = group.owner_id == user_auth_uuid
        is_member = user_auth_uuid in member_uuids
        
        if not (is_owner or is_member):
            raise HTTPException(status_code=403, detail="You are not a member of this group")

        # Get ALL feedbacks for this group
        stmt = select(Feedbacks).where(
            Feedbacks.group_id == group_id
        ).order_by(Feedbacks.created_at.desc())
        
        feedbacks = session.exec(stmt).all()

        # Batch fetch profiles
        profile_ids = set()
        for fb in feedbacks:
            if fb.send_id: profile_ids.add(fb.send_id)
            if fb.rev_id: profile_ids.add(fb.rev_id)
        profiles_map = _get_profiles_map(session, list(profile_ids))

        details = []
        for fb in feedbacks:
            sender_info = profiles_map.get(fb.send_id, {})
            receiver_info = profiles_map.get(fb.rev_id, {})
            
            obj = FeedbackDetail(
                id=fb.id,
                send_id=fb.send_id,
                rev_id=fb.rev_id,
                group_id=fb.group_id,
                group_image_url=fb.group_image_url,
                rating=fb.rating,
                content=fb.content or [],
                anonymous=fb.anonymous,
                created_at=fb.created_at,
                sender_name=None if fb.anonymous else sender_info.get("fullname", f"user-{fb.send_id}"),
                sender_email=None if fb.anonymous else sender_info.get("email"),
                receiver_name=receiver_info.get("fullname", f"user-{fb.rev_id}"),
                receiver_email=receiver_info.get("email")
            )
            details.append(obj)
        
        return details
    except HTTPException:
        raise
    except Exception as e:
        print(f"LỖI (get_group_feedbacks_service): {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail="Lỗi khi lấy feedbacks group")


# ====================================================================
# ✅ NEW: MY REPUTATION (User's received feedbacks grouped by groups)
# ====================================================================
async def get_my_reputation_service(session: Session, user_auth_uuid: str) -> MyReputationResponse:
    """
    Lấy tất cả feedbacks mà user nhận được (reputation), grouped by groups.
    Use case: Tab "Uy tín của tôi"
    """
    try:
        # Get user profile
        user_profile = session.exec(
            select(Profiles).where(Profiles.auth_user_id == user_auth_uuid)
        ).first()
        if not user_profile:
            raise HTTPException(status_code=404, detail="User profile not found")

        # Get all feedbacks where user is the receiver
        stmt = select(Feedbacks).where(
            Feedbacks.rev_id == user_profile.id
        ).order_by(Feedbacks.created_at.desc())
        
        all_feedbacks = session.exec(stmt).all()

        if not all_feedbacks:
            return MyReputationResponse(
                average_rating=0.0,
                total_feedbacks=0,
                groups=[]
            )

        # Calculate average rating
        ratings = [fb.rating for fb in all_feedbacks if fb.rating is not None]
        avg_rating = round(sum(ratings) / len(ratings), 1) if ratings else 0.0

        # Group feedbacks by group_id
        groups_dict: Dict[int, List[Feedbacks]] = {}
        for fb in all_feedbacks:
            if fb.group_id:
                if fb.group_id not in groups_dict:
                    groups_dict[fb.group_id] = []
                groups_dict[fb.group_id].append(fb)

        # Fetch group details
        group_ids = list(groups_dict.keys())
        groups_stmt = select(TravelGroup).where(TravelGroup.id.in_(group_ids))
        groups = session.exec(groups_stmt).all()
        groups_map = {g.id: g for g in groups}

        # Batch fetch profiles for senders
        all_sender_ids = set()
        for fb in all_feedbacks:
            if fb.send_id: all_sender_ids.add(fb.send_id)
        all_sender_ids.add(user_profile.id)  # Add receiver too
        profiles_map = _get_profiles_map(session, list(all_sender_ids))

        # Build response
        group_summaries = []
        for group_id, feedbacks_list in groups_dict.items():
            group = groups_map.get(group_id)
            if not group:
                continue
            
            group_image = None
            if hasattr(group, "image_url") and group.image_url:
                group_image = group.image_url
            elif hasattr(group, "group_image") and group.group_image:
                group_image = group.group_image

            feedback_details = []
            for fb in feedbacks_list:
                sender_info = profiles_map.get(fb.send_id, {})
                receiver_info = profiles_map.get(fb.rev_id, {})
                
                detail = FeedbackDetail(
                    id=fb.id,
                    send_id=fb.send_id,
                    rev_id=fb.rev_id,
                    group_id=fb.group_id,
                    group_image_url=fb.group_image_url,
                    rating=fb.rating,
                    content=fb.content or [],
                    anonymous=fb.anonymous,
                    created_at=fb.created_at,
                    sender_name=None if fb.anonymous else sender_info.get("fullname", f"user-{fb.send_id}"),
                    sender_email=None if fb.anonymous else sender_info.get("email"),
                    receiver_name=receiver_info.get("fullname", f"user-{fb.rev_id}"),
                    receiver_email=receiver_info.get("email")
                )
                feedback_details.append(detail)

            group_summaries.append(GroupReputationSummary(
                group_id=group_id,
                group_name=getattr(group, "name", f"group-{group_id}"),
                group_image_url=group_image,
                feedbacks=feedback_details
            ))

        return MyReputationResponse(
            average_rating=avg_rating,
            total_feedbacks=len(all_feedbacks),
            groups=group_summaries
        )
    except HTTPException:
        raise
    except Exception as e:
        print(f"LỖI (get_my_reputation_service): {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail="Lỗi khi lấy reputation")


# ====================================================================
# ✅ NEW: PENDING REVIEWS (Groups where user hasn't reviewed all members)
# ====================================================================
async def get_pending_reviews_service(session: Session, user_auth_uuid: str) -> PendingReviewsResponse:
    """
    Lấy danh sách các group đã expired mà user chưa đánh giá hết members.
    Use case: Tab "Đánh giá"
    """
    try:
        # Get user profile
        user_profile = session.exec(
            select(Profiles).where(Profiles.auth_user_id == user_auth_uuid)
        ).first()
        if not user_profile:
            raise HTTPException(status_code=404, detail="User profile not found")

        # Get all expired groups user is/was part of
        all_groups = session.exec(
            select(TravelGroup).where(TravelGroup.status == "expired")
        ).all()

        # Filter groups where user is/was a member
        user_expired_groups = []
        for group in all_groups:
            members = group.members or []
            member_uuids = [m.get('profile_uuid') for m in members if m.get('profile_uuid')]
            is_owner = group.owner_id == user_auth_uuid
            
            if is_owner or user_auth_uuid in member_uuids:
                user_expired_groups.append(group)

        pending_groups = []
        
        for group in user_expired_groups:
            # Get all members except self
            members = group.members or []
            other_members = [
                m for m in members 
                if m.get('profile_uuid') and m.get('profile_uuid') != user_auth_uuid
            ]

            if not other_members:
                continue  # No one to review

            # Get feedbacks user already gave in this group
            existing_feedbacks = session.exec(
                select(Feedbacks).where(
                    Feedbacks.send_id == user_profile.id,
                    Feedbacks.group_id == group.id
                )
            ).all()

            reviewed_profile_ids = {fb.rev_id for fb in existing_feedbacks}

            # Find unreviewed members
            unreviewed = []
            for member in other_members:
                member_uuid = member.get('profile_uuid')
                if not member_uuid:
                    continue
                
                # Get profile by UUID
                member_profile = session.exec(
                    select(Profiles).where(Profiles.auth_user_id == member_uuid)
                ).first()
                
                if member_profile and member_profile.id not in reviewed_profile_ids:
                    unreviewed.append(UnreviewedMember(
                        profile_id=member_profile.id,
                        profile_uuid=member_uuid,
                        email=member_profile.email,
                        fullname=getattr(member_profile, 'fullname', None)
                    ))

            if unreviewed:  # Only include groups with unreviewed members
                group_image = None
                if hasattr(group, "image_url") and group.image_url:
                    group_image = group.image_url
                elif hasattr(group, "group_image") and group.group_image:
                    group_image = group.group_image

                pending_groups.append(PendingReviewGroup(
                    group_id=group.id,
                    group_name=getattr(group, "name", f"group-{group.id}"),
                    group_image_url=group_image,
                    unreviewed_members=unreviewed
                ))

        return PendingReviewsResponse(pending_groups=pending_groups)
    except HTTPException:
        raise
    except Exception as e:
        print(f"LỖI (get_pending_reviews_service): {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail="Lỗi khi lấy pending reviews")


# ====================================================================
# KEPT: get_user_groups_feedbacks_service (từ code cũ)
# ====================================================================
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