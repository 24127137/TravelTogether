from fastapi import HTTPException
from sqlmodel import Session, select
from typing import List
from db_tables import Profiles, Destination
from recommend_models import RecommendationOutput
import ai_service # Import "bộ não" AI

# ====================================================================
# LOGIC GĐ 7: Lấy Gợi ý (Tìm bằng UUID)
# ====================================================================
async def get_ranked_recommendations_service_by_uuid(session: Session, auth_user_id: str) -> List[RecommendationOutput]:
    """
    (Logic đã refactor GĐ 8.1)
    Tìm profile bằng AUTH_USER_ID để lấy gợi ý.
    """
    print(f"Bắt đầu quy trình gợi ý (GĐ 8.1) cho Auth UUID: {auth_user_id}")

    statement_profile = select(Profiles).where(Profiles.auth_user_id == auth_user_id)
    profile = session.exec(statement_profile).first()
    
    if not profile:
        raise Exception("Profile not found")
        
    if not profile.interests or not profile.preferred_city:
        print(f"Lỗi 404: Profile (ID: {profile.id}) thiếu 'interests' hoặc 'preferred_city'.")
        raise Exception(f"Profile incomplete: Vui lòng cập nhật sở thích (interests) và thành phố (preferred_city) của bạn.")

    statement_dest = select(Destination).where(Destination.city == profile.preferred_city)
    destinations = session.exec(statement_dest).all()
    
    if not destinations:
        print(f"Lỗi 404: Không tìm thấy địa điểm nào cho thành phố: {profile.preferred_city}")
        raise Exception(f"Destinations not found for city: {profile.preferred_city}")

    ranked_list = await ai_service.rank_destinations_by_ai(
        user_interests=profile.interests,
        destinations=destinations
    )
    return ranked_list