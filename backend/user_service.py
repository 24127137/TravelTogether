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
# LOGIC GĐ 5: Cập nhật Profile (Đã tích hợp Logic Xóa Itinerary)
# ====================================================================
async def update_profile_service(
    session: Session, 
    auth_user_id: str, 
    update_data: ProfileUpdate
) -> ProfilePublic:
    """
    Cập nhật Profile với cơ chế 'Giao dịch bù trừ' (Manual Rollback).
    Nếu DB lỗi -> Hoàn tác Supabase.
    Logic nghiệp vụ: Nếu đổi Thành phố -> Xóa Lịch trình cũ.
    """
    if not supabase:
        raise Exception("Supabase client (user_service) chưa được khởi tạo.")
        
    print(f"Đang cập nhật (Full Logic) cho Auth UUID: {auth_user_id}")

    # BƯỚC 0: LẤY DỮ LIỆU CŨ (ĐỂ PHÒNG HỜ ROLLBACK)
    statement = select(Profiles).where(Profiles.auth_user_id == auth_user_id)
    db_profile = session.exec(statement).first()
    
    if not db_profile:
        raise Exception("Profile not found (DB)")

    old_email = db_profile.email # Lưu lại email cũ
    supabase_updated = False     # Cờ đánh dấu xem đã sửa Supabase chưa

    # BƯỚC 1: CẬP NHẬT AUTH (SUPABASE)
    auth_updates = {}
    if update_data.email and update_data.email != old_email:
        auth_updates["email"] = update_data.email
    if update_data.password:
        auth_updates["password"] = update_data.password
        
    if auth_updates:
        try:
            print(f"1. Đang cập nhật Supabase Auth: {auth_updates.keys()}")
            supabase.auth.admin.update_user_by_id(
                auth_user_id, 
                auth_updates
            )
            supabase_updated = True # Đánh dấu là đã sửa xong Supabase
            print("-> Supabase OK.")
        except Exception as e:
            print(f"LỖI khi cập nhật Auth (Dừng ngay): {e}")
            raise e

    # BƯỚC 2: CẬP NHẬT PROFILE (DATABASE)
    # Chuẩn bị dữ liệu update
    profile_updates = update_data.model_dump(exclude_unset=True)
    profile_updates.pop("email", None)    # Email đã xử lý ở trên
    profile_updates.pop("password", None) # Password không lưu DB

    try:
        if profile_updates:
            # === [LOGIC MỚI: XÓA ITINERARY NẾU ĐỔI CITY] ===
            new_city = profile_updates.get("preferred_city")

            # Nếu có city mới VÀ city mới khác city cũ -> Xóa lịch trình cũ
            if new_city and new_city != db_profile.preferred_city:
                print(f"User đổi thành phố sang {new_city} -> Xóa itinerary cũ.")
                db_profile.itinerary = None
            # ==============================================

            print(f"2. Đang cập nhật Profile DB: {profile_updates.keys()}")
            
            # Cập nhật dynamic các trường còn lại (bao gồm cả emergency_contact)
            for key, value in profile_updates.items():
                setattr(db_profile, key, value)
            
            session.add(db_profile)
            session.commit() # <--- NẾU LỖI SẼ NHẢY XUỐNG EXCEPT
            session.refresh(db_profile)
            print("-> Database OK.")
        else:
            print("Không có dữ liệu DB nào cần cập nhật.")

    except Exception as db_error:
        # === ĐÂY LÀ GIẢI PHÁP FIX LỖI TRANSACTION (MANUAL ROLLBACK) ===
        print(f"!!! LỖI DATABASE: {db_error}")
        
        if supabase_updated and "email" in auth_updates:
            print(f"!!! ĐANG HOÀN TÁC (ROLLBACK) SUPABASE VỀ EMAIL CŨ: {old_email}")
            try:
                # GỌI SUPABASE LẦN NỮA ĐỂ SỬA LẠI EMAIL CŨ
                supabase.auth.admin.update_user_by_id(
                    auth_user_id, 
                    {"email": old_email}
                )
                print("-> Hoàn tác Supabase thành công. Dữ liệu đã an toàn.")
            except Exception as rollback_error:
                # Trường hợp xấu nhất: Cả DB lỗi VÀ Rollback lỗi (Rất hiếm)
                print(f"!!! THẢM HỌA: Hoàn tác thất bại: {rollback_error}")
        
        # Ném lỗi ra để API trả về 500 cho Frontend biết
        raise Exception(f"Lỗi cập nhật Database (Đã hoàn tác Auth): {db_error}")

    # BƯỚC 3: TRẢ VỀ KẾT QUẢ
    public_profile = ProfilePublic.model_validate(db_profile)
    return public_profile