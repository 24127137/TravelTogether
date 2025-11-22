from sqlmodel import Session, select
from typing import Any, List, Optional
import traceback
from feedback_models import Feedbacks, CreateFeedbackInput, UpdateFeedbackInput
from db_tables import Profiles
from fastapi import HTTPException

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

        new = Feedbacks(
            send_id = db_sender.id,
            rev_id = payload.rev_id,
            rating = payload.rating,
            content = payload.content,
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

# Lấy list feedbacks (pagination + filter)
async def list_feedbacks_service(session: Session, page: int = 1, limit: int = 20, rev_id: Optional[int] = None, send_id: Optional[int] = None, q: Optional[str] = None) -> dict:
    try:
        if page < 1: page = 1
        if limit < 1: limit = 20
        if limit > 200: limit = 200

        stmt = select(Feedbacks)
        if rev_id:
            stmt = stmt.where(Feedbacks.rev_id == rev_id)
        if send_id:
            stmt = stmt.where(Feedbacks.send_id == send_id)
        if q:
            stmt = stmt.where(Feedbacks.content.ilike(f"%{q}%"))

        total = session.exec(select([Feedbacks.id]).from_statement(stmt.subquery()).count()).all() if False else None
        # Note: SQLModel/SQLAlchemy count is sometimes verbose; we'll compute total simply:
        all_q = session.exec(stmt)
        all_list = all_q.all()
        total_count = len(all_list)
        offset = (page - 1) * limit
        paged = all_list[offset: offset + limit]

        return {"meta": {"total": total_count, "page": page, "limit": limit}, "data": paged}
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
        if payload.content is not None: obj.content = payload.content
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
