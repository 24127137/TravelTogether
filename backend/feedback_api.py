from fastapi import APIRouter, Depends, Query, HTTPException
from typing import Any, List, Optional
from sqlmodel import Session
from database import get_session
from auth_guard import get_current_user
import feedback_service
from feedback_models import CreateFeedbackInput, UpdateFeedbackInput, FeedbackPublic

router = APIRouter(prefix="/feedbacks", tags=["Feedbacks"])

@router.post("/create", response_model=FeedbackPublic)
async def create_feedback(
    data: CreateFeedbackInput,
    session: Session = Depends(get_session),
    user = Depends(get_current_user)
):
    """
    Tạo feedback. Người gửi được lấy từ token (auth guard).
    """
    try:
        sender_uuid = str(user.id)
        obj = await feedback_service.create_feedback_service(session, sender_uuid, data)
        return obj
    except HTTPException:
        raise
    except Exception as e:
        print(f"LỖI /feedbacks/create: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/", response_model=Any)  # trả về dict meta + data
async def list_feedbacks(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=200),
    rev_id: Optional[int] = Query(None),
    send_id: Optional[int] = Query(None),
    q: Optional[str] = Query(None),
    session: Session = Depends(get_session),
    user = Depends(get_current_user)
):
    try:
        res = await feedback_service.list_feedbacks_service(session, page=page, limit=limit, rev_id=rev_id, send_id=send_id, q=q)
        # Nếu muốn ẩn send_id khi anonymous True, client nên làm; hoặc server có thể transform ở đây.
        # Mình trả nguyên dữ liệu, client sẽ hiển thị "Anonymous" nếu anonymous True.
        return res
    except HTTPException:
        raise
    except Exception as e:
        print(f"LỖI /feedbacks/: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{fid}", response_model=FeedbackPublic)
async def get_feedback(
    fid: int,
    session: Session = Depends(get_session),
    user = Depends(get_current_user)
):
    try:
        obj = await feedback_service.get_feedback_service(session, fid)
        return obj
    except HTTPException:
        raise
    except Exception as e:
        print(f"LỖI /feedbacks/{fid}: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.put("/{fid}", response_model=FeedbackPublic)
async def update_feedback(
    fid: int,
    data: UpdateFeedbackInput,
    session: Session = Depends(get_session),
    user = Depends(get_current_user)
):
    try:
        sender_uuid = str(user.id)
        obj = await feedback_service.update_feedback_service(session, fid, sender_uuid, data)
        return obj
    except HTTPException:
        raise
    except Exception as e:
        print(f"LỖI PUT /feedbacks/{fid}: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/{fid}")
async def delete_feedback(
    fid: int,
    session: Session = Depends(get_session),
    user = Depends(get_current_user)
):
    try:
        sender_uuid = str(user.id)
        ok = await feedback_service.delete_feedback_service(session, fid, sender_uuid)
        return {"deleted": ok}
    except HTTPException:
        raise
    except Exception as e:
        print(f"LỖI DELETE /feedbacks/{fid}: {e}")
        raise HTTPException(status_code=500, detail=str(e))
