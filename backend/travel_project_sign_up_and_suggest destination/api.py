from fastapi import APIRouter, HTTPException, Depends
from typing import List, Dict
from models import ProfileCreate, RecommendationOutput, Profiles, EmailStr
import services
from database import get_session
from sqlmodel import Session
import traceback

# Tạo một "router" mới
router = APIRouter()

# ====================================================================
# API GĐ 4.6: Quay lui /create-profile về logic GĐ 4.4
# ====================================================================
@router.post("/create-profile/", response_model=Profiles, tags=["GĐ 5 - Profiles (Sign Up)"])
async def create_profile_endpoint(
    profile_data: ProfileCreate, # <-- Tự động dùng ProfileCreate MỚI
    session: Session = Depends(get_session) # <-- CẦN SESSION TRỞ LẠI
):
    """
    (Đã cập nhật GĐ 4.6 - Rollback)
    Tạo một profile người dùng mới (Đăng ký Trực tiếp).
    Tạo Auth user VÀ Profile user ngay lập tức.
    """
    try:
        # Gọi service MỚI (đã có logic 2-trong-1)
        new_profile = await services.create_profile_service(session, profile_data)
        
        # Trả về TOÀN BỘ profile đã tạo
        return new_profile
        
    except Exception as e:
        error_str = str(e)
        if "duplicate key" in error_str or "already registered" in error_str or "UNIQUE constraint" in error_str:
             raise HTTPException(
                status_code=400, 
                detail=f"Lỗi: Email '{profile_data.email}' đã tồn tại."
            )
        if "Password should be at least" in error_str:
            raise HTTPException(
                status_code=400,
                detail="Lỗi: Mật khẩu quá yếu. (Supabase yêu cầu ít nhất 6 ký tự)."
            )
        print(f"LỖI MÁY CHỦ NỘI BỘ: {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Lỗi máy chủ nội bộ: {e}")

# ====================================================================
# API GĐ 4.5: /recommendations/{email} (KHÔNG THAY ĐỔI)
# ====================================================================
@router.get("/recommendations/{email}", response_model=List[RecommendationOutput], tags=["GĐ 5 - Recommendations"])
async def get_recommendations_endpoint(
    email: EmailStr, 
    session: Session = Depends(get_session)
):
    """
    API chính để lấy danh sách gợi ý đã được AI xếp hạng.
    (Tìm kiếm bằng email)
    """
    try:
        ranked_list = await services.get_ranked_recommendations_service(session, email)
        
        if not ranked_list:
            raise HTTPException(
                status_code=404, 
                detail="AI đã chạy nhưng không thể tạo gợi ý."
            )
            
        return ranked_list
            
    except Exception as e:
        print(f"LỖI MÁY CHỦ NỘI BỘ: {e}")
        traceback.print_exc()
        if "not found" in str(e) or "incomplete" in str(e):
            raise HTTPException(
                status_code=404, 
                detail=str(e)
            )
        raise HTTPException(status_code=500, detail=f"Lỗi máy chủ nội bộ: {e}")

@router.get("/", tags=["Root"])
def read_root():
    """
    Endpoint gốc để kiểm tra server
    """
    return {"message": "Chào mừng bạn đến với API Du lịch (GĐ 4.6 - Đăng ký Trực tiếp)"}