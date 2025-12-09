from sqlmodel import Session, select
from db_tables import Profiles, TravelGroup
from user_models import ProfilePublic, ProfileUpdate
from datetime import datetime
from config import settings
from supabase import create_client, Client
from typing import Any
import traceback

# Import hàm check trùng lịch
from group_services.utils import check_date_overlap

try:
    supabase: Client = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
except:
    supabase = None

async def update_profile_service(
    session: Session, 
    auth_user_id: str, 
    update_data: ProfileUpdate
) -> ProfilePublic:
    """
    Cập nhật Profile.
    CHẶN CHẶT: Nếu travel_dates mới trùng với bất kỳ nhóm nào đang tham gia -> BÁO LỖI.
    """
    if not supabase: raise Exception("Supabase client lỗi.")

    print(f"Đang cập nhật Profile cho: {auth_user_id}")

    # 1. Lấy Profile gốc
    db_profile = session.exec(select(Profiles).where(Profiles.auth_user_id == auth_user_id)).first()
    if not db_profile: raise Exception("User not found")

    # 2. Xử lý Auth (Email/Pass)
    old_email = db_profile.email
    auth_updates = {}
    if update_data.email and update_data.email != old_email: auth_updates["email"] = update_data.email
    if update_data.password: auth_updates["password"] = update_data.password
        
    if auth_updates:
        try:
            supabase.auth.admin.update_user_by_id(auth_user_id, auth_updates)
        except Exception as e:
            raise e

    # 3. Chuẩn bị dữ liệu update
    profile_updates = update_data.model_dump(exclude_unset=True)
    profile_updates.pop("email", None)
    profile_updates.pop("password", None)

    # === [LOGIC QUAN TRỌNG: KIỂM TRA TRÙNG LỊCH NGAY TẠI GỐC] ===
    new_dates = profile_updates.get("travel_dates")
    
    # Nếu người dùng đổi ngày (new_dates khác None)
    if new_dates:
        # Lấy danh sách ID tất cả nhóm đang tham gia
        joined_info = (db_profile.joined_groups or []) + (db_profile.owned_groups or [])
        group_ids = [g['group_id'] for g in joined_info if g.get('group_id')]
        
        if group_ids:
            # Lấy thông tin nhóm từ DB để check ngày
            groups = session.exec(select(TravelGroup).where(TravelGroup.id.in_(group_ids))).all()
            
            for grp in groups:
                # Chỉ check với nhóm đang hoạt động
                if grp.status in ['open', 'closed']:
                    if check_date_overlap(grp.travel_dates, new_dates):
                        raise Exception(
                            f"Cập nhật thất bại: Lịch trình mới bị trùng với nhóm '{grp.name}' "
                            f"(Ngày: {grp.travel_dates}) mà bạn đang tham gia."
                        )
    # ============================================================

    try:
        # Xử lý logic phụ: Đổi city -> Xóa itinerary cũ
        new_city = profile_updates.get("preferred_city")
        if new_city and new_city != db_profile.preferred_city:
            db_profile.itinerary = None

        # Cập nhật vào DB
        for key, value in profile_updates.items():
            setattr(db_profile, key, value)
        
        session.add(db_profile)
        session.commit()
        session.refresh(db_profile)
        
        return ProfilePublic.model_validate(db_profile)
        
    except Exception as db_error:
        print(f"Lỗi DB: {db_error}")
        # Rollback Auth nếu cần
        if auth_updates and "email" in auth_updates:
            try:
                supabase.auth.admin.update_user_by_id(auth_user_id, {"email": old_email})
            except: pass
        raise Exception(f"Lỗi cập nhật: {db_error}")

async def get_profile_by_uuid_service(session: Session, auth_user_id: str) -> ProfilePublic:
    profile = session.exec(select(Profiles).where(Profiles.auth_user_id == auth_user_id)).first()
    if not profile: raise Exception("User not found")
    return ProfilePublic.model_validate(profile)