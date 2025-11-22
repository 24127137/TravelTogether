from fastapi import HTTPException
from sqlmodel import Session, select
import traceback
from config import settings
from supabase import create_client, Client
from typing import Any
from user_models import ProfilePublic, ProfileUpdate
from db_tables import Profiles

# Khởi tạo Supabase client (chỉ dùng cho cập nhật Email/Pass)
try:
    supabase: Client = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
    print("Đã khởi tạo Supabase client (cho user_service) thành công.")
except Exception as e:
    print(f"LỖI: Không thể khởi tạo Supabase client (trong user_service): {e}")
    supabase = None

# ====================================================================
# LOGIC GĐ 5: Lấy Profile (Cho GET /users/me)
# ====================================================================
async def get_profile_by_uuid_service(session: Session, auth_user_id: str) -> ProfilePublic:
    """
    (Logic đã refactor GĐ 8.1)
    Tìm profile trong bảng 'profiles' bằng 'auth_user_id'.
    """
    print(f"Đang tìm profile cho Auth UUID: {auth_user_id}")
    
    statement = select(Profiles).where(Profiles.auth_user_id == auth_user_id)
    db_profile = session.exec(statement).first()
    
    if not db_profile:
        print("LỖI: Không tìm thấy profile khớp với UUID.")
        raise Exception("Profile not found for this user")
        
    public_profile = ProfilePublic.model_validate(db_profile)
    
    return public_profile

# ====================================================================
# LOGIC GĐ 5: Cập nhật Profile (Cho PATCH /me)
# ====================================================================
async def update_profile_service(
    session: Session, 
    auth_user_id: str, 
    update_data: ProfileUpdate
) -> ProfilePublic:
    """
    (Logic đã refactor GĐ 8.1)
    Cập nhật Auth (Email, Password) trên Supabase.
    Cập nhật Profile (Fullname, Interests...) trên Database.
    """
    if not supabase:
        raise Exception("Supabase client (user_service) chưa được khởi tạo.")
        
    print(f"Đang cập nhật (GĐ 8.1) cho Auth UUID: {auth_user_id}")

    # 1. CẬP NHẬT AUTH (SUPABASE)
    auth_updates = {}
    if update_data.email:
        auth_updates["email"] = update_data.email
    if update_data.password:
        auth_updates["password"] = update_data.password
        
    if auth_updates:
        try:
            print(f"Đang cập nhật Supabase Auth (Email/Pass): {auth_updates.keys()}")
            supabase.auth.admin.update_user_by_id(
                auth_user_id, 
                auth_updates
            )
            print("Cập nhật Auth thành công.")
        except Exception as e:
            print(f"LỖI khi cập nhật Auth: {e}")
            raise e

    # 2. CẬP NHẬT PROFILE (DATABASE)
    statement = select(Profiles).where(Profiles.auth_user_id == auth_user_id)
    db_profile = session.exec(statement).first()
    
    if not db_profile:
        print("LỖI: Không tìm thấy profile DB để cập nhật.")
        raise Exception("Profile not found (DB)")
        
    profile_updates = update_data.model_dump(exclude_unset=True)
    
    profile_updates.pop("email", None)
    profile_updates.pop("password", None)

    if profile_updates:
        try:
            print(f"Đang cập nhật Profile DB (Fullname, Interests...): {profile_updates.keys()}")
            
            for key, value in profile_updates.items():
                setattr(db_profile, key, value)
                
            session.add(db_profile)
            session.commit()
            session.refresh(db_profile)
            print("Cập nhật Profile DB thành công.")
            
        except Exception as e:
            print(f"LỖI khi cập nhật Profile DB: {e}")
            raise e
    else:
        print("Không có dữ liệu Profile DB nào cần cập nhật.")

    # 3. TRẢ VỀ DỮ LIỆU CÔNG KHAI
    public_profile = ProfilePublic.model_validate(db_profile)
    return public_profile