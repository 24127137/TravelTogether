from fastapi import HTTPException
from sqlmodel import Session, select
import traceback
from config import settings
from supabase import create_client, Client
from typing import Any
from user_models import ProfilePublic, ProfileUpdate
from db_tables import Profiles, TravelGroup

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
# async def get_profile_by_uuid_service(session: Session, auth_user_id: str) -> ProfilePublic:
#     """
#     Tìm profile trong bảng 'profiles' bằng 'auth_user_id'.
#     """
#     print(f"Đang tìm profile cho Auth UUID: {auth_user_id}")
#
#     statement = select(Profiles).where(Profiles.auth_user_id == auth_user_id)
#     db_profile = session.exec(statement).first()
#
#     if not db_profile:
#         print("LỖI: Không tìm thấy profile khớp với UUID.")
#         raise Exception("Profile not found for this user")
#
#     public_profile = ProfilePublic.model_validate(db_profile)
#
#     return public_profile

async def get_profile_by_uuid_service(session: Session, auth_user_id: str) -> ProfilePublic:
    """
    Lấy profile. Nếu User đang trong nhóm -> Trả về Itinerary của Nhóm.
    """
    print(f"Đang tìm profile cho Auth UUID: {auth_user_id}")

    # 1. Lấy thông tin gốc của User
    statement = select(Profiles).where(Profiles.auth_user_id == auth_user_id)
    db_profile = session.exec(statement).first()

    if not db_profile:
        raise Exception("Profile not found")

    # 2. KIỂM TRA: User có đang trong nhóm nào không?
    group_id = None

    # Check nếu là Member (Joined)
    if db_profile.joined_groups and isinstance(db_profile.joined_groups, list) and len(db_profile.joined_groups) > 0:
        first_group = db_profile.joined_groups[0]
        if isinstance(first_group, dict):
            group_id = first_group.get('group_id')

    # Check nếu là Host (Owned) - (Phòng trường hợp Host chưa set itinerary cá nhân nhưng Group đã có)
    elif db_profile.owned_groups and isinstance(db_profile.owned_groups, list) and len(db_profile.owned_groups) > 0:
        first_group = db_profile.owned_groups[0]
        if isinstance(first_group, dict):
            group_id = first_group.get('group_id')

    # 3. NẾU CÓ NHÓM -> LẤY PLAN CỦA NHÓM ĐÈ LÊN
    final_itinerary = db_profile.itinerary # Mặc định lấy của cá nhân

    if group_id:
        print(f"🚀 User thuộc Group ID {group_id}. Đang lấy Group Itinerary...")
        travel_group = session.get(TravelGroup, group_id)

        if travel_group and travel_group.itinerary:
            # LẤY ITINERARY CỦA NHÓM GÁN VÀO BIẾN TẠM
            final_itinerary = travel_group.itinerary
            print("✅ Đã áp dụng Itinerary của nhóm.")
        else:
            print("⚠️ Nhóm không có itinerary hoặc không tìm thấy nhóm.")

    # 4. TẠO MODEL TRẢ VỀ (KHÔNG SỬA DATABASE)
    # Validate từ db_profile nhưng ghi đè itinerary
    public_profile = ProfilePublic.model_validate(db_profile)
    public_profile.itinerary = final_itinerary

    return public_profile

# ====================================================================
# LOGIC GĐ 5: Cập nhật Profile (ĐÃ FIX LỖI TRANSACTION)
# ====================================================================
async def update_profile_service(
    session: Session, 
    auth_user_id: str, 
    update_data: ProfileUpdate
) -> ProfilePublic:
    """
    Cập nhật Profile với cơ chế 'Giao dịch bù trừ' (Manual Rollback).
    Nếu DB lỗi -> Hoàn tác Supabase.
    """
    if not supabase:
        raise Exception("Supabase client (user_service) chưa được khởi tạo.")
        
    print(f"Đang cập nhật (GĐ 8.1) cho Auth UUID: {auth_user_id}")

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
            print(f"2. Đang cập nhật Profile DB: {profile_updates.keys()}")
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