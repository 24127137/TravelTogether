from fastapi import APIRouter, Depends, Query, HTTPException
from typing import Any, List, Optional
from sqlmodel import Session
from database import get_session
from auth_guard import get_current_user
import feedback_service
from feedback_models import CreateFeedbackInput, UpdateFeedbackInput, FeedbackPublic, BatchCreateFeedbackInput, UserGroupFeedbackSummary, FeedbackDetail

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

@router.post("/batch-create", response_model=List[FeedbackPublic])
async def batch_create_feedback(
    data: BatchCreateFeedbackInput,
    session: Session = Depends(get_session),
    user = Depends(get_current_user)
):
    """
    Tạo multiple feedbacks (cho multiple recipients sau group disband).
    """
    try:
        sender_uuid = str(user.id)
        objs = await feedback_service.batch_create_feedback_service(session, sender_uuid, data)
        return objs
    except HTTPException:
        raise
    except Exception as e:
        print(f"LỖI /feedbacks/batch-create: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/", response_model=Any)  # trả về dict meta + data
async def list_feedbacks(
    rev_id: Optional[int] = Query(None),
    send_id: Optional[int] = Query(None),
    q: Optional[str] = Query(None),
    sort_by: Optional[str] = Query(None, description="Sắp xếp theo 'created_at' (mới nhất) hoặc 'rating' (sao)"),
    order: Optional[str] = Query("desc", description="Thứ tự: 'asc' (tăng dần) hoặc 'desc' (giảm dần)"),
    session: Session = Depends(get_session),
    user = Depends(get_current_user)
):
    try:
        res = await feedback_service.list_feedbacks_service(
            session, rev_id=rev_id, send_id=send_id, q=q, sort_by=sort_by, order=order
        )
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

@router.get("/user-groups", response_model=List[UserGroupFeedbackSummary])
async def get_user_disbanded_groups(
    session: Session = Depends(get_session),
    user = Depends(get_current_user)
):
    """
    Lấy list groups đã disbanded của user (joined/owned), với average rating.
    """
    try:
        sender_uuid = str(user.id)
        res = await feedback_service.get_user_disbanded_groups_service(session, sender_uuid)
        return res
    except HTTPException:
        raise
    except Exception as e:
        print(f"LỖI /feedbacks/user-groups: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/group/{group_id}", response_model=List[FeedbackDetail])
async def get_group_feedbacks(
    group_id: int,
    session: Session = Depends(get_session),
    user = Depends(get_current_user)
):
    """
    Lấy feedbacks cho group cụ thể (rev_id = user.id), xử lý anonymous.
    """
    try:
        rev_uuid = str(user.id)
        res = await feedback_service.get_group_feedbacks_service(session, group_id, rev_uuid)
        return res
    except HTTPException:
        raise
    except Exception as e:
        print(f"LỖI /feedbacks/group/{group_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))