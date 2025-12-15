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
    FeedbackDetail,
    MyReputationResponse,
    PendingReviewsResponse
)

router = APIRouter(prefix="/feedbacks", tags=["Feedbacks"])


# ====================================================================
# CREATE FEEDBACK
# ====================================================================
@router.post("/create", response_model=FeedbackPublic)
async def create_feedback(
    data: CreateFeedbackInput,
    session: Session = Depends(get_session),
    user = Depends(get_current_user)
):
    """
    Tạo feedback cho member trong group đã expired.
    
    Business Rules:
    - Group phải có status = "expired"
    - Sender và receiver phải cùng trong group
    - Không cho phép đánh giá trùng (1 sender + 1 receiver trong 1 group)
    - Tags phải thuộc predefined_tags: ['friendly', 'punctual', 'helpful', 'fun', 'organized', 'late', 'uncooperative']
    """
    try:
        sender_auth_uuid = str(user.id)
        obj = await feedback_service.create_feedback_service(session, sender_auth_uuid, data)
        return obj
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ====================================================================
# LIST FEEDBACKS (with filters)
# ====================================================================
@router.get("/", response_model=Any)
async def list_feedbacks(
    rev_id: Optional[int] = Query(None, description="Filter by receiver profile ID"),
    receiver_uuid: Optional[str] = Query(None, description="Filter by receiver UUID (Thay thế cho rev_id)"),
    send_id: Optional[int] = Query(None, description="Filter by sender profile ID"),
    group_id: Optional[int] = Query(None, description="Filter by group ID"),
    q: Optional[str] = Query(None, description="Search in content tags"),
    sort_by: Optional[str] = Query(None, description="Sort by: created_at, rating"),
    order: Optional[str] = Query("desc", description="Order: asc or desc"),
    session: Session = Depends(get_session),
    user = Depends(get_current_user)
):
    """
    Lấy danh sách feedbacks với filters:
    - rev_id: Lọc theo người nhận
    - send_id: Lọc theo người gửi  
    - group_id: Lọc theo nhóm
    - q: Tìm kiếm trong content tags
    - sort_by: Sắp xếp theo created_at hoặc rating
    - order: asc hoặc desc
    
    Returns:
    {
        "meta": {
            "total": int,
            "average_rating": float (if filtering by rev_id)
        },
        "data": [...]
    }
    """
    try:
        res = await feedback_service.list_feedbacks_service(
            session, 
            rev_id=rev_id,
            receiver_uuid=receiver_uuid,
            send_id=send_id, 
            group_id=group_id,
            q=q, 
            sort_by=sort_by, 
            order=order
        )
        return res
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ====================================================================
# MY REPUTATION (Tab "Uy tín của tôi")
# ====================================================================
@router.get("/my-reputation", response_model=MyReputationResponse)
async def get_my_reputation(
    session: Session = Depends(get_session),
    user = Depends(get_current_user)
):
    """
    Lấy tất cả feedbacks mà user nhận được (reputation), grouped by groups.
    
    Returns:
    {
        "average_rating": float,
        "total_feedbacks": int,
        "groups": [
            {
                "group_id": int,
                "group_name": str,
                "group_image_url": str,
                "feedbacks": [...]
            }
        ]
    }
    
    Use case: Tab "Uy tín của tôi" trong Profile
    """
    try:
        user_uuid = str(user.id)
        res = await feedback_service.get_my_reputation_service(session, user_uuid)
        return res
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ====================================================================
# PENDING REVIEWS (Tab "Đánh giá")
# ====================================================================
@router.get("/pending-reviews", response_model=PendingReviewsResponse)
async def get_pending_reviews(
    session: Session = Depends(get_session),
    user = Depends(get_current_user)
):
    """
    Lấy danh sách các group đã expired mà user chưa đánh giá hết members.
    
    Returns:
    {
        "pending_groups": [
            {
                "group_id": int,
                "group_name": str,
                "group_image_url": str,
                "unreviewed_members": [
                    {
                        "profile_id": int,
                        "profile_uuid": str,
                        "email": str,
                        "fullname": str
                    }
                ]
            }
        ]
    }
    
    Use case: Tab "Đánh giá" trong Profile - hiển thị nhóm expired chưa review hết
    """
    try:
        user_uuid = str(user.id)
        res = await feedback_service.get_pending_reviews_service(session, user_uuid)
        return res
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ====================================================================
# GROUP FEEDBACKS (Tất cả feedbacks trong 1 group)
# ====================================================================
@router.get("/group/{group_id}", response_model=List[FeedbackDetail])
async def get_group_feedbacks(
    group_id: int,
    session: Session = Depends(get_session),
    user = Depends(get_current_user)
):
    """
    Lấy tất cả feedbacks trong 1 group (sender → receiver).
    User phải là member hoặc owner của group.
    
    Returns: List[FeedbackDetail] với đầy đủ thông tin sender và receiver
    
    Use case: Trang Group Detail - hiển thị tất cả feedbacks của nhóm
    """
    try:
        user_uuid = str(user.id)
        res = await feedback_service.get_group_feedbacks_service(session, group_id, user_uuid)
        return res
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ====================================================================
# GET SINGLE FEEDBACK
# ====================================================================
@router.get("/{fid}", response_model=FeedbackPublic)
async def get_feedback(
    fid: int,
    session: Session = Depends(get_session),
    user = Depends(get_current_user)
):
    """
    Lấy chi tiết 1 feedback theo ID.
    """
    try:
        obj = await feedback_service.get_feedback_service(session, fid)
        return obj
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ====================================================================
# UPDATE FEEDBACK
# ====================================================================
@router.put("/{fid}", response_model=FeedbackPublic)
async def update_feedback(
    fid: int,
    data: UpdateFeedbackInput,
    session: Session = Depends(get_session),
    user = Depends(get_current_user)
):
    """
    Cập nhật feedback. Chỉ sender mới có quyền update.
    
    Có thể update: rating, content, anonymous
    """
    try:
        sender_auth_uuid = str(user.id)
        obj = await feedback_service.update_feedback_service(session, fid, sender_auth_uuid, data)
        return obj
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ====================================================================
# DELETE FEEDBACK
# ====================================================================
@router.delete("/{fid}")
async def delete_feedback(
    fid: int,
    session: Session = Depends(get_session),
    user = Depends(get_current_user)
):
    """
    Xóa feedback. Chỉ sender mới có quyền xóa.
    """
    try:
        sender_auth_uuid = str(user.id)
        ok = await feedback_service.delete_feedback_service(session, fid, sender_auth_uuid)
        return {"deleted": ok}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))