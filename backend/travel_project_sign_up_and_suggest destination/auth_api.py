from fastapi import APIRouter, HTTPException, Depends, Response
from typing import List, Dict
# SỬA ĐỔI (GĐ 5): Import thêm 'RefreshInput', 'RefreshResponse', 'UserInfo'
from auth_models import SignInInput, SignInResponse, RefreshInput, RefreshResponse, UserInfo
import auth_service # <-- Import service ĐĂNG NHẬP mới
import traceback

# Tạo một "router" mới CHỈ DÀNH CHO XÁC THỰC
router = APIRouter(
    prefix="/auth", # Đặt tiền tố /auth cho tất cả API trong file này
    tags=["GĐ 5 - Authentication"] # Đặt tên nhóm API
)

# ====================================================================
# API (GĐ 4.7): /auth/signin (KHÔNG THAY ĐỔI)
# ====================================================================
@router.post("/signin/", response_model=SignInResponse)
async def sign_in_endpoint(
    signin_data: SignInInput,
    # (Bỏ `response: Response` nếu bạn không dùng Cookie)
):
    """
    (MỚI GĐ 4.7 - Dành cho App Di động)
    Xác thực email và password của người dùng.
    Trả về JSON chứa tokens.
    """
    try:
        service_response = await auth_service.sign_in_service(signin_data)
        
        print("Đăng nhập thành công, trả về JSON chứa tokens...")
        
        # Trả về "Oke" và TOKENS
        return SignInResponse(
            message="Đăng nhập thành công!",
            access_token=service_response.session.access_token,
            refresh_token=service_response.session.refresh_token,
            user=UserInfo( # <-- Sửa lỗi: Phải ép kiểu về UserInfo
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
        # Lỗi này sẽ không xảy ra nếu "Confirm email" đã TẮT
        if "Email not confirmed" in error_str:
            raise HTTPException(
                status_code=401,
                detail="Email chưa được xác nhận. Vui lòng kiểm tra hòm thư."
            )
        print(f"LỖI MÁY CHỦ NỘI BỘ (SIGNIN): {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Lỗi máy chủ nội bộ: {e}")

# ====================================================================
# API MỚI (GĐ 5): /auth/refresh (Xử lý "Vé hết hạn")
# ====================================================================
@router.post("/refresh", response_model=RefreshResponse, tags=["GĐ 5 - Authentication"])
async def refresh_token_endpoint(
    refresh_data: RefreshInput
):
    """
    (MỚI GĐ 5)
    Xử lý "vé hết hạn".
    Frontend (App) gửi "vé dự phòng" (refresh_token) lên đây.
    Backend trả về "vé vào cửa" (access_token) mới.
    """
    try:
        # Gọi "bộ não" logic đổi vé
        new_session = await auth_service.refresh_token_service(refresh_data)
        
        # Trả về "vé" mới cho App
        return RefreshResponse(
            access_token=new_session.access_token,
            refresh_token=new_session.refresh_token # Supabase cũng trả về 1 refresh token mới
        )
            
    except Exception as e:
        # Nếu "vé dự phòng" cũng hết hạn
        raise HTTPException(
            status_code=401, # 401 Unauthorized
            detail=f"Refresh token không hợp lệ: {e}"
        )