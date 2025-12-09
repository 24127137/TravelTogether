from sqlmodel import Session, select
from db_tables import Profiles, TokenSecurity
from auth_models import SignInInput, ProfileCreate, SignInServiceResponse, RefreshInput
from datetime import datetime
import traceback
from config import settings
from supabase import create_client, Client
from typing import Any
import hashlib

# Khởi tạo Supabase client
try:
    supabase: Client = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
    print("Đã khởi tạo Supabase Auth client (cho auth_service) thành công.")
except Exception as e:
    print(f"LỖI: Không thể khởi tạo Supabase Auth client (trong auth_service): {e}")
    supabase = None

def hash_token(token: str) -> str:
    """Hàm băm token dùng chung"""
    return hashlib.sha256(token.encode()).hexdigest()

# ====================================================================
# LOGIC: Đăng Ký (Sign Up)
# ====================================================================
async def create_profile_service(session: Session, profile_data: ProfileCreate) -> Profiles:
    if not supabase:
        raise Exception("Supabase client chưa được khởi tạo.")
        
    print(f"Đang thực hiện Đăng ký cho: {profile_data.email}")
    
    # 1. TẠO USER TRÊN SUPABASE AUTH
    try:
        auth_response = supabase.auth.sign_up({
            "email": profile_data.email,
            "password": profile_data.password,
        })
        
        if not auth_response.user or not auth_response.user.id:
            raise Exception("Không thể tạo user Auth. Dữ liệu trả về không hợp lệ.")
            
        auth_user_id = str(auth_response.user.id)
        
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
            preferred_city=profile_data.preferred_city,
            # Lưu liên hệ khẩn cấp
            emergency_contact=profile_data.emergency_contact
        )
        
        session.add(db_profile)
        session.commit()
        session.refresh(db_profile)
        
        return db_profile
        
    except Exception as e:
        print(f"LỖI khi tạo Profile DB: {e}")
        traceback.print_exc()
        
        # ROLLBACK
        try:
            supabase.auth.admin.delete_user(auth_user_id)
        except Exception as admin_e:
            print(f"LỖI NGHIÊM TRỌNG KHI ROLLBACK: {admin_e}")
            
        raise e

# ====================================================================
# LOGIC: Đăng Nhập (Sign In) - Supabase Only
# ====================================================================
async def sign_in_service(signin_data: SignInInput) -> SignInServiceResponse:
    if not supabase:
        raise Exception("Supabase Auth client chưa được khởi tạo.")
    try:
        auth_response = supabase.auth.sign_in_with_password({
            "email": signin_data.email,
            "password": signin_data.password,
        })
        return SignInServiceResponse(session=auth_response.session, user=auth_response.user)
    except Exception as e:
        print(f"LỖI khi đăng nhập: {e}")
        raise e 

# ====================================================================
# LOGIC: Refresh Token - Supabase Only
# ====================================================================
async def refresh_token_service(refresh_data: RefreshInput) -> Any: 
    if not supabase:
        raise Exception("Supabase Auth client chưa được khởi tạo.")
    try:
        auth_response = supabase.auth.refresh_session(refresh_data.refresh_token)
        return auth_response.session
    except Exception as e:
        # print(f"LỖI khi đổi vé: {e}")
        raise Exception("Refresh token không hợp lệ")

# ====================================================================
# LOGIC MỚI: Lưu Active Session (Upsert)
# ====================================================================
async def save_active_session(
    session: Session, 
    user_id: str, 
    access_token: str, 
    ip: str, 
    user_agent: str
):
    """
    Lưu hoặc Cập nhật token đang hoạt động vào bảng TokenSecurity.
    Đảm bảo mỗi user chỉ có 1 session active.
    """
    token_hash = hash_token(access_token)
    
    try:
        # Tìm session cũ
        existing = session.exec(
            select(TokenSecurity).where(TokenSecurity.user_id == user_id)
        ).first()
        
        if existing:
            # Update (Ghi đè session cũ)
            existing.token_signature = token_hash
            existing.ip_address = ip
            existing.user_agent = user_agent
            existing.created_at = datetime.now()
            session.add(existing)
        else:
            # Insert mới
            new_sec = TokenSecurity(
                user_id=user_id,
                token_signature=token_hash,
                ip_address=ip,
                user_agent=user_agent
            )
            session.add(new_sec)
            
        session.commit()
        # print(f"-> Đã lưu Active Session cho User {user_id}")
        
    except Exception as e:
        print(f"Lỗi Save Session: {e}")

# ====================================================================
# LOGIC MỚI: Đăng Xuất (Xóa Session)
# ====================================================================
async def sign_out_service(session: Session, user_uuid: str) -> bool:
    """
    Chỉ cần xóa active session là xong.
    Token đó sẽ không còn trong DB -> AuthGuard chặn.
    """
    try:
        active_session = session.exec(
            select(TokenSecurity).where(TokenSecurity.user_id == user_uuid)
        ).first()
        
        if active_session:
            session.delete(active_session)
            session.commit()
            return True
        return False
        
    except Exception as e:
        print(f"Lỗi Service SignOut: {e}")
        raise e