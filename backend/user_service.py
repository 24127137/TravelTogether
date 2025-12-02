from sqlmodel import Session, select
from db_tables import Profiles, UserTripPlans, TravelGroup
from user_models import ProfilePublic, ProfileUpdate
from datetime import datetime
from config import settings
from supabase import create_client, Client
from typing import Any
import traceback

# Import hàm check trùng lịch từ folder group_services
from group_services.utils import check_date_overlap

# Khởi tạo Supabase client
try:
    supabase: Client = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
except Exception:
    supabase = None

async def update_profile_service(
    session: Session, 
    auth_user_id: str, 
    update_data: ProfileUpdate
) -> ProfilePublic:
    """
    Cập nhật Profile. 
    Logic mới: Lưu lịch trình vào bảng UserTripPlans và kiểm tra trùng lặp.
    """
    if not supabase:
        raise Exception("Supabase client chưa được khởi tạo.")

    print(f"Đang cập nhật Profile & Trip Plan cho: {auth_user_id}")

    # 1. Lấy Profile gốc
    db_profile = session.exec(select(Profiles).where(Profiles.auth_user_id == auth_user_id)).first()
    if not db_profile: raise Exception("Profile not found (DB)")

    old_email = db_profile.email
    supabase_updated = False

    # 2. CẬP NHẬT AUTH (Email/Password) - Logic cũ giữ nguyên
    auth_updates = {}
    if update_data.email and update_data.email != old_email:
        auth_updates["email"] = update_data.email
    if update_data.password:
        auth_updates["password"] = update_data.password
        
    if auth_updates:
        try:
            supabase.auth.admin.update_user_by_id(auth_user_id, auth_updates)
            supabase_updated = True
        except Exception as e:
            raise e

    # 3. CẬP NHẬT THÔNG TIN CƠ BẢN VÀO PROFILE
    # Lấy data update, loại bỏ email/pass (đã xử lý) và các trường trip (xử lý riêng)
    profile_updates = update_data.model_dump(exclude_unset=True)
    trip_fields = ["preferred_city", "travel_dates", "itinerary"]
    
    basic_updates = {k: v for k, v in profile_updates.items() 
                     if k not in ["email", "password"] and k not in trip_fields}

    try:
        # Cập nhật thông tin cơ bản (Tên, tuổi, sở thích...)
        for key, value in basic_updates.items():
            setattr(db_profile, key, value)
        
        session.add(db_profile)

        # 4. [LOGIC MỚI] XỬ LÝ TRAVEL PLANS (Lưu nhiều lịch trình)
        new_city = update_data.preferred_city
        new_dates = update_data.travel_dates
        new_itinerary = update_data.itinerary

        # Chỉ xử lý khi có City và Dates (tức là User đang lên kế hoạch đi chơi)
        if new_city and new_dates:
            print(f"-> User muốn thêm lịch trình đi {new_city}")

            # A. Kiểm tra trùng lịch với CÁC PLAN KHÁC trong quá khứ
            existing_plans = session.exec(
                select(UserTripPlans).where(UserTripPlans.user_id == auth_user_id)
            ).all()
            
            for plan in existing_plans:
                if check_date_overlap(plan.travel_dates, new_dates):
                    raise Exception(f"Lịch trình mới bị trùng ngày với kế hoạch đi {plan.preferred_city} cũ của bạn.")

            # B. Kiểm tra trùng lịch với CÁC NHÓM ĐÃ THAM GIA
            all_groups_info = (db_profile.joined_groups or []) + (db_profile.owned_groups or [])
            for g_info in all_groups_info:
                gid = g_info.get('group_id')
                if gid:
                    grp = session.get(TravelGroup, gid)
                    # Nếu nhóm còn hiệu lực (chưa expired/closed) thì check trùng
                    if grp and grp.status == 'open' and check_date_overlap(grp.travel_dates, new_dates):
                         raise Exception(f"Lịch trình mới bị trùng ngày với nhóm '{grp.name}' bạn đang tham gia.")

            # C. Nếu không trùng -> Lưu Plan Mới vào bảng UserTripPlans
            new_plan = UserTripPlans(
                user_id=auth_user_id,
                preferred_city=new_city,
                travel_dates=new_dates,
                itinerary=new_itinerary,
                updated_at=datetime.now()
            )
            session.add(new_plan)
            
            # D. Cập nhật "Cache" vào Profile chính (để hiển thị cái mới nhất ở màn hình Home)
            db_profile.preferred_city = new_city
            db_profile.travel_dates = new_dates
            db_profile.itinerary = new_itinerary

        # Commit toàn bộ thay đổi (Profile + Plan)
        session.commit()
        session.refresh(db_profile)
        print("-> Cập nhật thành công.")
        
    except Exception as db_error:
        print(f"Lỗi DB: {db_error}")
        # Rollback Supabase nếu lỗi
        if supabase_updated and "email" in auth_updates:
            try:
                supabase.auth.admin.update_user_by_id(auth_user_id, {"email": old_email})
            except:
                pass
        raise Exception(f"Lỗi cập nhật: {db_error}")

    return ProfilePublic.model_validate(db_profile)

async def get_profile_by_uuid_service(session: Session, auth_user_id: str) -> ProfilePublic:
    profile = session.exec(select(Profiles).where(Profiles.auth_user_id == auth_user_id)).first()
    if not profile: raise Exception("User not found")
    return ProfilePublic.model_validate(profile)