from sqlmodel import Session, select, func
from typing import Any, List, Optional
import traceback
from feedback_models import Feedbacks, CreateFeedbackInput, UpdateFeedbackInput, BatchCreateFeedbackInput, UserGroupFeedbackSummary, FeedbackDetail
from db_tables import Profiles, TravelGroup
from fastapi import HTTPException
from sqlalchemy import or_

predefined_tags = ['friendly', 'punctual', 'helpful', 'fun', 'organized', 'late', 'uncooperative']

# Tạo feedback
async def create_feedback_service(session: Session, sender_auth_uuid: str, payload: CreateFeedbackInput) -> Feedbacks:
    """
    sender_auth_uuid: str (auth_user_id) - giá trị id từ token (the project's auth_guard returns user.id as uuid string)
    payload: CreateFeedbackInput
    """
    try:
        # Lấy profile của sender theo auth_user_id
        stmt = select(Profiles).where(Profiles.auth_user_id == sender_auth_uuid)
        db_sender = session.exec(stmt).first()
        if not db_sender:
            raise HTTPException(status_code=404, detail="Sender profile not found")

        # Kiểm tra rev exists
        stmt2 = select(Profiles).where(Profiles.id == payload.rev_id)
        db_rev = session.exec(stmt2).first()
        if not db_rev:
            raise HTTPException(status_code=404, detail="Recipient profile not found")

        # Validate tags
        if payload.content:
            invalid_tags = set(payload.content) - set(predefined_tags)
            if invalid_tags:
                raise HTTPException(status_code=400, detail=f"Invalid tags: {invalid_tags}")

        # Validate sender/rev là members nếu có group_id
        if payload.group_id:
            stmt_group = select(TravelGroup).where(TravelGroup.id == payload.group_id)
            group = session.exec(stmt_group).first()
            if not group:
                raise HTTPException(status_code=404, detail="Group not found")
            member_uuids = [m.get('profile_uuid') for m in (group.members or []) if m.get('profile_uuid')]
            if sender_auth_uuid not in member_uuids or db_rev.auth_user_id not in member_uuids:
                raise HTTPException(status_code=403, detail="Không phải member của group")

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

# Batch create
async def batch_create_feedback_service(session: Session, sender_auth_uuid: str, payload: BatchCreateFeedbackInput) -> List[Feedbacks]:
    try:
        # Lấy sender + group members để validate
        stmt_sender = select(Profiles).where(Profiles.auth_user_id == sender_auth_uuid)
        db_sender = session.exec(stmt_sender).first()
        if not db_sender:
            raise HTTPException(status_code=404, detail="Sender not found")
        
        stmt_group = select(TravelGroup).where(TravelGroup.id == payload.group_id)
        group = session.exec(stmt_group).first()
        if not group:
            raise HTTPException(status_code=404, detail="Group not found")
        member_uuids = [m.get('profile_uuid') for m in (group.members or []) if m.get('profile_uuid')]
        if sender_auth_uuid not in member_uuids:
            raise HTTPException(status_code=403, detail="Sender không phải member")
        
        created = []
        for fb in payload.feedbacks:
            fb.group_id = payload.group_id
            stmt_rev = select(Profiles).where(Profiles.id == fb.rev_id)
            db_rev = session.exec(stmt_rev).first()
            if not db_rev or db_rev.auth_user_id not in member_uuids:
                raise HTTPException(status_code=403, detail=f"Rev {fb.rev_id} không phải member")
            new = await create_feedback_service(session, sender_auth_uuid, fb)
            created.append(new)
        return created
    except HTTPException:
        raise
    except Exception as e:
        print(f"LỖI (batch_create_feedback_service): {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail="Lỗi khi tạo batch feedback")

# Lấy list feedbacks (không pagination, trả về tất cả)
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
            stmt = stmt.where(Feedbacks.content.ilike(f"%{q}%"))

        # Áp dụng sort
        if sort_by == "created_at":
            if order.lower() == "asc":
                stmt = stmt.order_by(Feedbacks.created_at.asc())
            else:
                stmt = stmt.order_by(Feedbacks.created_at.desc())
        elif sort_by == "rating":
            if order.lower() == "asc":
                stmt = stmt.order_by(Feedbacks.rating.asc())
            else:
                stmt = stmt.order_by(Feedbacks.rating.desc())

        all_q = session.exec(stmt)
        all_list = all_q.all()
        total_count = len(all_list)

        meta = {"total": total_count}
        
        # Tính average rating nếu có rev_id
        if rev_id:
            avg_stmt = select(func.avg(Feedbacks.rating)).where(Feedbacks.rev_id == rev_id, Feedbacks.rating.isnot(None))
            average = session.exec(avg_stmt).one() or 0.0
            meta["average_rating"] = round(float(average), 1)

        return {"meta": meta, "data": all_list}
    except Exception as e:
        print(f"LỖI (list_feedbacks_service): {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail="Internal server error when listing feedbacks")

# Lấy 1 feedback theo id
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

# Cập nhật (chỉ người gửi mới được sửa)
async def update_feedback_service(session: Session, fid: int, sender_auth_uuid: str, payload: UpdateFeedbackInput) -> Feedbacks:
    try:
        # lấy sender profile id
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

# Xóa (chỉ người gửi mới được xóa)
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

# Lấy list disbanded groups của user với average rating
async def get_user_disbanded_groups_service(session: Session, user_auth_uuid: str) -> List[UserGroupFeedbackSummary]:
    try:
        # Lấy profile id của user
        stmt_user = select(Profiles).where(Profiles.auth_user_id == user_auth_uuid)
        db_user = session.exec(stmt_user).first()
        if not db_user:
            raise HTTPException(status_code=404, detail="User profile not found")

        # Lấy groups disbanded mà user owned hoặc joined
        stmt_groups = select(TravelGroup).where(
            TravelGroup.status == "disbanded",
            or_(
                TravelGroup.owner_id == user_auth_uuid,
                TravelGroup.members.op("@>")([{"profile_uuid": user_auth_uuid}])  # JSONB query
            )
        )
        groups = session.exec(stmt_groups).all()

        summaries = []
        for group in groups:
            avg_stmt = select(func.avg(Feedbacks.rating)).where(
                Feedbacks.rev_id == db_user.id,
                Feedbacks.group_id == group.id,
                Feedbacks.rating.isnot(None)
            )
            average = session.exec(avg_stmt).one() or 0.0

            summaries.append(UserGroupFeedbackSummary(
                group_id=group.id,
                group_name=group.name,
                group_image_url=group.image_url if hasattr(group, 'image_url') else None,  # Giả sử có field này; nếu không, thêm vào db_tables.py
                average_rating=round(float(average), 1)
            ))
        return summaries
    except Exception as e:
        print(f"LỖI (get_user_disbanded_groups_service): {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail="Lỗi khi lấy groups feedback")

# Lấy feedbacks cho group cụ thể (rev = user)
async def get_group_feedbacks_service(session: Session, group_id: int, rev_auth_uuid: str) -> List[FeedbackDetail]:
    try:
        # Lấy rev profile
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

        details = []
        for fb in feedbacks:
            sender_name = None
            if not fb.anonymous:
                stmt_sender = select(Profiles).where(Profiles.id == fb.send_id)
                db_sender = session.exec(stmt_sender).first()
                sender_name = db_sender.fullname if db_sender else "Unknown"

            details.append(FeedbackDetail(
                **fb.dict(),
                sender_name=sender_name
            ))
        return details
    except Exception as e:
        print(f"LỖI (get_group_feedbacks_service): {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail="Lỗi khi lấy feedbacks group")