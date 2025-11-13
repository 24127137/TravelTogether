from auth_models import SignInInput, RefreshInput # <-- Import 'RefreshInput'
import traceback
from config import settings
from supabase import create_client, Client
from pydantic import BaseModel
from typing import Any # <-- Import 'Any'

# ====================================================================
# SỬA LỖI (GĐ 4.8): Xóa 'gotrue.types' và dùng 'Any'
# ====================================================================
# (Không cần import 'gotrue.types' nữa)
# ====================================================================


# Khởi tạo Supabase client (dùng chung keys với services.py)
try:
    supabase: Client = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
    print("Đã khởi tạo Supabase Auth client (cho auth_service) thành công.")
except Exception as e:
    print(f"LỖI: Không thể khởi tạo Supabase Auth client (trong auth_service): {e}")
    supabase = None

class SignInServiceResponse(BaseModel):
    """
    Một class nội bộ để trả về session và user một cách an toàn
    """
    # === SỬA LỖI (GĐ 4.8): Thay thế kiểu dữ liệu 'lạ' bằng 'Any' ===
    session: Any 
    user: Any
    
    # === THÊM CẤU HÌNH ĐỂ SỬA LỖI PYDANTIC ===
    class Config:
        arbitrary_types_allowed = True


async def sign_in_service(signin_data: SignInInput) -> SignInServiceResponse:
    """
    (Logic GĐ 4.6 - Đăng nhập)
    Xác thực email/password.
    """
    if not supabase:
        raise Exception("Supabase Auth client chưa được khởi tạo.")
        
    print(f"Đang thực hiện đăng nhập (GĐ 4.6) cho: {signin_data.email}")
    
    try:
        auth_response = supabase.auth.sign_in_with_password({
            "email": signin_data.email,
            "password": signin_data.password,
        })
        print(f"Đăng nhập thành công cho: {auth_response.user.email}")
        return SignInServiceResponse(
            session=auth_response.session,
            user=auth_response.user
        )
    except Exception as e:
        print(f"LỖI khi đăng nhập GĐ 4.6: {e}")
        traceback.print_exc()
        raise e 

# ====================================================================
# THÊM MỚI (GĐ 5): Logic "Đổi vé" (Refresh Token)
# ====================================================================
async def refresh_token_service(refresh_data: RefreshInput) -> Any: # <-- Trả về Any
    """
    (Logic GĐ 5)
    1. Nhận "vé dự phòng" (refresh_token).
    2. Gọi Supabase Auth để lấy "vé vào cửa" mới.
    """
    if not supabase:
        raise Exception("Supabase Auth client chưa được khởi tạo.")
        
    print(f"Đang 'đổi vé' (refresh token)...")
    
    try:
        # === GỌI SUPABASE AUTH ĐỂ ĐỔI VÉ ===
        auth_response = supabase.auth.refresh_session(
            refresh_data.refresh_token
        )
        
        print("Đổi vé thành công.")
        return auth_response.session
        
    except Exception as e:
        print(f"LỖI khi đổi vé (refresh token): {e}")
        traceback.print_exc()
        raise Exception("Refresh token không hợp lệ hoặc đã hết hạn")