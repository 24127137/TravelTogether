from fastapi import APIRouter, HTTPException, Depends, Response
from typing import List, Dict
from auth_models import (
    SignInInput, SignInResponse, 
    RefreshInput, RefreshResponse, 
    UserInfo, ProfileCreate
)
from db_tables import Profiles # Import Bảng
import auth_service 
import traceback
from database import get_session
from sqlmodel import Session

# Tạo một "router" mới CHỈ DÀNH CHO XÁC THỰC
router = APIRouter(
    prefix="/auth", 
    tags=["GĐ 8 - Authentication"] 
)

# ====================================================================
# API (GĐ 8): /auth/signup
# ====================================================================
@router.post("/signup", response_model=Profiles, tags=["GĐ 8 - Authentication"])
async def create_profile_endpoint(
    profile_data: ProfileCreate, 
    session: Session = Depends(get_session)
):
    """
    (Đã di chuyển GĐ 8)
    Tạo một profile người dùng mới (Đăng ký Trực tiếp).
    """
    try:
        new_profile = await auth_service.create_profile_service(session, profile_data)
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
        print(f"LỖI MÁY CHỦ NỘI BỘ (SIGNUP): {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Lỗi máy chủ nội bộ: {e}")

# ====================================================================
# API (GĐ 4.7): /auth/signin
# ====================================================================
@router.post("/signin", response_model=SignInResponse)
async def sign_in_endpoint(
    signin_data: SignInInput,
):
    """
    Xác thực email và password của người dùng.
    Trả về JSON chứa tokens.
    """
    try:
        service_response = await auth_service.sign_in_service(signin_data)
        
        print("Đăng nhập thành công, trả về JSON chứa tokens...")
        
        return SignInResponse(
            message="Đăng nhập thành công!",
            access_token=service_response.session.access_token,
            refresh_token=service_response.session.refresh_token,
            user=UserInfo(
                id=str(service_response.user.id),
                email=service_response.user.email
            )
        )
            
    except Exception as e:
        error_str = str(e)
        if "Invalid login credentials" in error_str:
            raise HTTPException(
                status_code=401, 
                detail="Thông tin email hoặc mật khẩu bị sai."
            )
        if "Email not confirmed" in error_str:
            raise HTTPException(
                status_code=401,
                detail="Email chưa được xác nhận. Vui lòng kiểm tra hòm thư."
            )
        print(f"LỖI MÁY CHỦ NỘI BỘ (SIGNIN): {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Lỗi máy chủ nội bộ: {e}")

# ====================================================================
# API (GĐ 5): /auth/refresh
# ====================================================================
@router.post("/refresh", response_model=RefreshResponse, tags=["GĐ 8 - Authentication"])
async def refresh_token_endpoint(
    refresh_data: RefreshInput
):
    """
    Xử lý "vé hết hạn".
    """
    try:
        new_session = await auth_service.refresh_token_service(refresh_data)
        
        return RefreshResponse(
            access_token=new_session.access_token,
            refresh_token=new_session.refresh_token
        )
            
    except Exception as e:
        raise HTTPException(
            status_code=401, # 401 Unauthorized
            detail=f"Refresh token không hợp lệ: {e}"
        )