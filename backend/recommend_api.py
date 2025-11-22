from fastapi import APIRouter, HTTPException, Depends
from typing import List, Any
from recommend_models import RecommendationOutput
import recommend_service
from database import get_session
from sqlmodel import Session
import traceback
from auth_guard import get_current_user # Import "Người Bảo vệ"

# ====================================================================
# API cho Gợi ý (Đã được bảo vệ)
# ====================================================================

router = APIRouter(
    prefix="/recommendations", # Đặt tiền tố /recommendations
    tags=["GĐ 8 - Recommendations (Bảo vệ)"]
)

@router.get("/me", response_model=List[RecommendationOutput])
async def get_my_recommendations_endpoint(
    session: Session = Depends(get_session),
    user_object: Any = Depends(get_current_user) 
):
    """
    (API đã refactor GĐ 8.1)
    API chính để lấy danh sách gợi ý đã được AI xếp hạng.
    (Tự động tìm profile dựa trên Access Token).
    """
    try:
        auth_uuid = str(user_object.id)
        
        ranked_list = await recommend_service.get_ranked_recommendations_service_by_uuid(
            session, auth_uuid
        )
        
        if not ranked_list:
            raise HTTPException(
                status_code=404, 
                detail="AI đã chạy nhưng không thể tạo gợi ý."
            )
            
        return ranked_list
            
    except Exception as e:
        print(f"LỖI MÁY CHỦ NỘI BỘ (RECOMMEND): {e}")
        traceback.print_exc()
        if "not found" in str(e) or "incomplete" in str(e):
            raise HTTPException(status_code=404, detail=str(e))
        raise HTTPException(status_code=500, detail=f"Lỗi máy chủ nội bộ: {e}")