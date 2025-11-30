from fastapi import APIRouter, HTTPException, Depends
from typing import Any
from user_models import ProfilePublic, ProfileUpdate
import user_service
from database import get_session
from sqlmodel import Session
import traceback
from auth_guard import get_current_user # Import "Người Bảo vệ"

# ====================================================================
# API cho Profiles (Đã được bảo vệ)
# ====================================================================

router = APIRouter(
    prefix="/users", # Đặt tiền tố /users
    tags=["GĐ 8 - User (Profile)"]
)

@router.get("/me", response_model=ProfilePublic)
async def get_my_profile_endpoint(
    session: Session = Depends(get_session),
    user_object: Any = Depends(get_current_user) 
):
    """
    (API đã refactor GĐ 8.1)
    Lấy thông tin profile của user hiện tại (dựa trên Token).
    """
    try:
        auth_uuid = str(user_object.id) 
        profile = await user_service.get_profile_by_uuid_service(session, auth_uuid)
        return profile
            
    except Exception as e:
        print(f"LỖI KHI LẤY PROFILE /users/me: {e}")
        traceback.print_exc()
        if "not found" in str(e):
            raise HTTPException(status_code=404, detail=str(e))
        raise HTTPException(status_code=500, detail=f"Lỗi máy chủ nội bộ: {e}")


@router.patch("/me", response_model=ProfilePublic)
async def update_my_profile_endpoint(
    update_data: ProfileUpdate, 
    session: Session = Depends(get_session),
    user_object: Any = Depends(get_current_user)
):
    """
    (API đã refactor GĐ 8.1)
    Cập nhật "tất tần tật" cho user hiện tại (dựa trên Token).
    """
    try:
        auth_uuid = str(user_object.id)
        
        updated_profile = await user_service.update_profile_service(
            session=session, 
            auth_user_id=auth_uuid, 
            update_data=update_data
        )
        return updated_profile
            
    except Exception as e:
        print(f"LỖI KHI CẬP NHẬT PROFILE /users/me: {e}")
        traceback.print_exc()
        if "not found" in str(e):
            raise HTTPException(status_code=404, detail=str(e))
        raise HTTPException(status_code=500, detail=f"Lỗi máy chủ nội bộ: {e}")