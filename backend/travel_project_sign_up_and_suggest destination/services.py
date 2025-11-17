# services.py
from fastapi import HTTPException
from sqlmodel import Session, select
from sqlalchemy import text
from sqlalchemy.dialects.postgresql import ARRAY, JSONB
from typing import List, Dict, Any, Optional
from datetime import date, timedelta
import traceback
from models import (
    Profiles, Destination, ProfileCreate, ProfileUpdate, RecommendationOutput, EmailStr
)
import ai_service
from config import settings
from supabase import create_client, Client

# ====================================================================
# SUPABASE CLIENT
# ====================================================================
supabase: Optional[Client] = None
try:
    supabase = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
    print("Supabase client khởi tạo thành công.")
except Exception as e:
    print(f"Không thể khởi tạo Supabase: {e}")
    supabase = None


# ====================================================================
# HÀM CHUYỂN DATERANGE
# ====================================================================
def list_to_daterange(date_list: Optional[List[str]]) -> Optional[Any]:
    if not date_list or len(date_list) != 2:
        return None
    try:
        start = date.fromisoformat(date_list[0])
        end = date.fromisoformat(date_list[1])
        end_inclusive = end + timedelta(days=1)
        range_str = f"[{start},{end_inclusive})"
        return text(f"'{range_str}'::daterange")
    except ValueError:
        return None


# ====================================================================
# ĐĂNG KÝ
# ====================================================================
async def create_profile_service(session: Session, profile_data: ProfileCreate) -> Profiles:
    if not supabase:
        raise Exception("Supabase chưa khởi tạo.")
    print(f"Đang tạo profile cho: {profile_data.email}")
    auth_user_id = None
    try:
        auth_response = supabase.auth.sign_up({
            "email": profile_data.email,
            "password": profile_data.password,
        })
        auth_user_id = auth_response.user.id
        print(f"Auth user tạo thành công: {auth_user_id}")

        profile_dict = profile_data.model_dump(exclude={"password"})
        profile_dict["auth_user_id"] = str(auth_user_id)
        db_profile = Profiles.model_validate(profile_dict)

        session.add(db_profile)
        session.commit()
        session.refresh(db_profile)
        print(f"Profile tạo thành công, ID: {db_profile.id}")
        return db_profile
    except Exception as e:
        print(f"LỖI tạo profile: {e}")
        traceback.print_exc()
        session.rollback()
        if auth_user_id:
            try:
                supabase.auth.admin.delete_user(auth_user_id)
                print("Rollback Auth thành công.")
            except: pass
        raise e


# ====================================================================
# GỢI Ý ĐIỂM ĐẾN
# ====================================================================
async def get_ranked_recommendations_service(session: Session, email: EmailStr) -> List[RecommendationOutput]:
    try:
        profile = session.exec(select(Profiles).where(Profiles.email == email)).first()
        if not profile or not profile.interests or not profile.preferred_city:
            raise Exception("Profile không hợp lệ")

        destinations = session.exec(select(Destination).where(Destination.city == profile.preferred_city)).all()
        if not destinations:
            raise Exception(f"Không có điểm đến ở {profile.preferred_city}")

        ranked = await ai_service.rank_destinations_by_ai(
            user_interests=profile.interests,
            destinations=destinations
        )
        return ranked
    except Exception as e:
        print(f"LỖI gợi ý: {e}")
        raise e


# ====================================================================
# LẤY PROFILE
# ====================================================================
async def get_profile_by_uuid_service(session: Session, auth_user_id: str) -> Profiles:
    profile = session.exec(select(Profiles).where(Profiles.auth_user_id == auth_user_id)).first()
    if not profile:
        raise HTTPException(status_code=404, detail="Profile không tồn tại")
    return profile


# ====================================================================
# CẬP NHẬT PROFILE (HOÀN CHỈNH)
# ====================================================================
async def update_profile_service(
    session: Session,
    auth_user_id: str,
    update_data: ProfileUpdate
) -> Profiles:
    if not supabase:
        raise Exception("Supabase chưa khởi tạo.")

    print(f"Đang cập nhật profile cho: {auth_user_id}")
    update_dict = update_data.model_dump(exclude_unset=True)
    if not update_dict:
        raise HTTPException(status_code=400, detail="Không có dữ liệu cập nhật.")

    auth_updates = {}
    if "email" in update_dict: auth_updates["email"] = update_dict.pop("email")
    if "password" in update_dict: auth_updates["password"] = update_dict.pop("password")

    try:
        if auth_updates:
            supabase.auth.admin.update_user_by_id(auth_user_id, auth_updates)
            print("Cập nhật Auth thành công.")

        profile = session.exec(select(Profiles).where(Profiles.auth_user_id == auth_user_id)).first()
        if not profile:
            raise HTTPException(status_code=404, detail="Profile không tồn tại")

        for key, value in update_dict.items():
            if value is None: continue

            if key == "travel_dates":
                profile.travel_dates = list_to_daterange(value)

            elif key == "itinerary":
                profile.itinerary = value

            elif key == "interests":
                profile.interests = value

            elif key in ["fullname", "preferred_city", "gender"]:
                setattr(profile, key, value)

        session.add(profile)
        session.commit()
        session.refresh(profile)
        print("Cập nhật Profile thành công.")
        return profile

    except HTTPException:
        raise
    except Exception as e:
        print(f"LỖI cập nhật: {e}")
        traceback.print_exc()
        session.rollback()
        raise HTTPException(status_code=500, detail=f"Lỗi máy chủ: {str(e)}")