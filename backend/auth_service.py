from auth_models import SignInInput, RefreshInput, ProfileCreate
import traceback
from config import settings
from supabase import create_client, Client
from pydantic import BaseModel
from typing import Any 
from sqlmodel import Session
from db_tables import Profiles # Import Bảng


# Khởi tạo Supabase client
try:
    supabase: Client = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
    print("Đã khởi tạo Supabase Auth client (cho auth_service) thành công.")
except Exception as e:
    print(f"LỖI: Không thể khởi tạo Supabase Auth client (trong auth_service): {e}")
    supabase = None

class SignInServiceResponse(BaseModel):
    session: Any 
    user: Any
    class Config:
        arbitrary_types_allowed = True

# ====================================================================
# LOGIC (GĐ 8): Đăng Ký
# ====================================================================
async def create_profile_service(session: Session, profile_data: ProfileCreate) -> Profiles:
    """
    (Đã di chuyển GĐ 8)
    1. Tạo user trên Supabase Auth.
    2. Tạo profile trên Database.
    """
    if not supabase:
        raise Exception("Supabase client chưa được khởi tạo.")
        
    print(f"Đang thực hiện Đăng ký (GĐ 8) cho: {profile_data.email}")
    
    # 1. TẠO USER TRÊN SUPABASE AUTH
    try:
        auth_response = supabase.auth.sign_up({
            "email": profile_data.email,
            "password": profile_data.password,
        })

        if not auth_response.user or not auth_response.user.id:
            raise Exception("Không thể tạo user Auth. Dữ liệu trả về không hợp lệ.")
            
        auth_user_id = str(auth_response.user.id)
        print(f"Tạo Auth user thành công. UUID: {auth_user_id}")
        
    except Exception as e:
        print(f"LỖI khi tạo Auth user: {e}")
        raise e

    # 2. TẠO PROFILE TRÊN DATABASE
    try:
        db_profile = Profiles(
            auth_user_id=auth_user_id, 
            email=profile_data.email,
            fullname=profile_data.fullname,
            gender=profile_data.gender,
            interests=profile_data.interests,
            preferred_city=profile_data.preferred_city
        )
        
        session.add(db_profile)
        session.commit()
        session.refresh(db_profile)
        
        print(f"Tạo Profile DB thành công cho: {db_profile.email}")
        return db_profile
        
    except Exception as e:
        print(f"LỖI khi tạo Profile DB: {e}")
        traceback.print_exc()
        
        # === XỬ LÝ ROLLBACK (QUAN TRỌNG) ===
        try:
            print(f"ĐANG ROLLBACK: Xóa Auth user (UUID: {auth_user_id})...")
            supabase.auth.admin.delete_user(auth_user_id)
            print("Rollback thành công.")
        except Exception as admin_e:
            print(f"LỖI NGHIÊM TRỌNG KHI ROLLBACK: {admin_e}")
            
        raise e

# ====================================================================
# LOGIC (GĐ 4.6): Đăng nhập
# ====================================================================
async def sign_in_service(signin_data: SignInInput) -> SignInServiceResponse:
    """
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
# LOGIC (GĐ 5): Đổi vé (Refresh Token)
# ====================================================================
async def refresh_token_service(refresh_data: RefreshInput) -> Any: 
    """
    (Logic GĐ 5)
    Gọi Supabase Auth để lấy "vé vào cửa" mới.
    """
    if not supabase:
        raise Exception("Supabase Auth client chưa được khởi tạo.")
        
    print(f"Đang 'đổi vé' (refresh token)...")
    
    try:
        auth_response = supabase.auth.refresh_session(
            refresh_data.refresh_token
        )
        
        print("Đổi vé thành công.")
        return auth_response.session
        
    except Exception as e:
        print(f"LỖI khi đổi vé (refresh token): {e}")
        traceback.print_exc()
        raise Exception("Refresh token không hợp lệ hoặc đã hết hạn")