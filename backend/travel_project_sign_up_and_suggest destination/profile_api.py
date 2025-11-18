from fastapi import APIRouter, HTTPException, Depends
from typing import List, Dict, Any
from models import ProfilePublic, ProfileUpdate, Profiles, EmailStr
import services
from database import get_session
from sqlmodel import Session
import traceback
from auth_guard import get_current_user # <-- Import "Người Bảo vệ"

# ====================================================================
# FILE MỚI (GĐ 5): API cho Profiles (Đã được bảo vệ)
# (Theo yêu cầu "tách 2 api mới ra 2 file riêng")
# ====================================================================

# Tạo một "router" mới CHỈ DÀNH CHO PROFILES
router = APIRouter(
    prefix="/users", # Đặt tiền tố /users cho các API này
    tags=["GĐ 5 - Profiles (Bảo vệ)"]
)

@router.get("/me", response_model=ProfilePublic)
async def get_my_profile_endpoint(
    session: Session = Depends(get_session),
    # "NGƯỜI BẢO VỆ" ĐỨNG GÁC:
    user_object: Any = Depends(get_current_user) 
):
    """
    (MỚI GĐ 5) API được bảo vệ.
    Lấy thông tin profile của user hiện tại (dựa trên "Vé" (Token)
    mà app gửi trong Header).
    (Đúng như bạn yêu cầu, KHÔNG trả về UUID).
    """
    try:
        # Lấy "Số CCCD" (UUID) mà "Bảo vệ" đã lấy từ "Vé"
        auth_uuid = str(user_object.id) 
        
        # Gọi "bộ não" logic (services.py) để tìm "tủ đồ" (profile)
        profile = await services.get_profile_by_uuid_service(session, auth_uuid)
        
        # Trả về DỮ LIỆU CÔNG KHAI (model `ProfilePublic` - không có UUID)
        return profile
            
    except Exception as e:
        print(f"LỖI KHI LẤY PROFILE /users/me: {e}")
        traceback.print_exc()
        if "not found" in str(e):
            raise HTTPException(
                status_code=404, 
                detail=str(e)
            )
        raise HTTPException(status_code=500, detail=f"Lỗi máy chủ nội bộ: {e}")


@router.patch("/me", response_model=ProfilePublic)
async def update_my_profile_endpoint(
    update_data: ProfileUpdate, # <-- Dùng "Tờ đơn Cập nhật"
    session: Session = Depends(get_session),
    # "NGƯỜI BẢO VỆ" ĐỨNG GÁC:
    user_object: Any = Depends(get_current_user)
):
    """
    (MỚI GĐ 5) API được bảo vệ.
    Cập nhật "tất tần tật" (email, password, fullname, interests...)
    cho user hiện tại (dựa trên "Vé" (Token)).
    (Đúng như bạn yêu cầu, KHÔNG trả về UUID).
    """
    try:
        auth_uuid = str(user_object.id)
        
        # Gọi "bộ não" logic (services.py) để cập nhật
        updated_profile = await services.update_profile_service(
            session=session, 
            auth_user_id=auth_uuid, 
            update_data=update_data
        )
        # Trả về profile đã được cập nhật (dạng Public)
        return updated_profile
            
    except Exception as e:
        print(f"LỖI KHI CẬP NHẬT PROFILE /profiles/me: {e}")
        traceback.print_exc()
        if "not found" in str(e):
            raise HTTPException(status_code=404, detail=str(e))
        raise HTTPException(status_code=500, detail=f"Lỗi máy chủ nội bộ: {e}")