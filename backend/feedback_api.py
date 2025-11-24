from fastapi import APIRouter, Depends, Query, HTTPException
from typing import Any, List, Optional
from sqlmodel import Session
from database import get_session
from auth_guard import get_current_user
import feedback_service
from feedback_models import (
    CreateFeedbackInput,
    UpdateFeedbackInput,
    FeedbackPublic,
    BatchCreateFeedbackInput,
    FeedbackDetail
)

router = APIRouter(prefix="/feedbacks", tags=["Feedbacks"])


@router.post("/create", response_model=FeedbackPublic)
async def create_feedback(
    data: CreateFeedbackInput,
    session: Session = Depends(get_session),
    user = Depends(get_current_user)
):
    """
    Tạo feedback. Người gửi được lấy từ token (auth guard).
    user.id (returned by auth_guard) expected as UUID string (auth_user_id).
    predefined_tags = ['friendly', 'punctual', 'helpful', 'fun', 'organized', 'late', 'uncooperative']
    """
    try:
        sender_auth_uuid = str(user.id)
        obj = await feedback_service.create_feedback_service(session, sender_auth_uuid, data)
        return obj
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/batch-create", response_model=List[FeedbackPublic])
async def batch_create_feedback(
    data: BatchCreateFeedbackInput,
    session: Session = Depends(get_session),
    user = Depends(get_current_user)
):
    try:
        sender_auth_uuid = str(user.id)
        objs = await feedback_service.batch_create_feedback_service(session, sender_auth_uuid, data)
        return objs
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/", response_model=Any)
async def list_feedbacks(
    rev_id: Optional[int] = Query(None),
    send_id: Optional[int] = Query(None),
    q: Optional[str] = Query(None),
    sort_by: Optional[str] = Query(None),
    order: Optional[str] = Query("desc"),
    session: Session = Depends(get_session),
    user = Depends(get_current_user)
):
    """
    sort_by là một trong các trường: created_at, rating
    order là 'asc' hoặc 'desc'
    """
    try:
        res = await feedback_service.list_feedbacks_service(
            session, rev_id=rev_id, send_id=send_id, q=q, sort_by=sort_by, order=order
        )
        return res
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# trả về feedbacks theo từng group user tham gia
@router.get("/user-groups", response_model=List[Any])
async def get_user_groups_feedbacks(
    session: Session = Depends(get_session),
    user = Depends(get_current_user)
):
    """
    Lấy tất cả groups mà user tham gia
    và trả về feedbacks của từng group với các trường:
      - group_id, group_name, group_image
      - feedbacks: [{ sender_name, receiver_name, rating, content }, ...]
    """
    try:
        user_uuid = str(user.id)
        res = await feedback_service.get_user_groups_feedbacks_service(session, user_uuid)
        return res
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/group/{group_id}", response_model=List[FeedbackDetail])
async def get_group_feedbacks(
    group_id: int,
    session: Session = Depends(get_session),
    user = Depends(get_current_user)
):
    try:
        rev_uuid = str(user.id)
        res = await feedback_service.get_group_feedbacks_service(session, group_id, rev_uuid)
        return res
    except HTTPException:
        raise
    except Exception as e:
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
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/{fid}", response_model=FeedbackPublic)
async def update_feedback(
    fid: int,
    data: UpdateFeedbackInput,
    session: Session = Depends(get_session),
    user = Depends(get_current_user)
):
    try:
        sender_auth_uuid = str(user.id)
        obj = await feedback_service.update_feedback_service(session, fid, sender_auth_uuid, data)
        return obj
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{fid}")
async def delete_feedback(
    fid: int,
    session: Session = Depends(get_session),
    user = Depends(get_current_user)
):
    try:
        sender_auth_uuid = str(user.id)
        ok = await feedback_service.delete_feedback_service(session, fid, sender_auth_uuid)
        return {"deleted": ok}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))