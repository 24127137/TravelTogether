from sqlmodel import Session, select, text
from db_tables import TravelGroup, Profiles, UserTripPlans
from group_models import SuggestionOutput, GroupPlanOutput
from fastapi import HTTPException
from typing import List, Any
import ai_service
from .utils import validate_user_profile_completeness

async def group_suggest_service(session: Session, current_user: Any) -> List[SuggestionOutput]:
    user_uuid = str(current_user.id)
    
    # 1. Lấy Plan mới nhất (vừa update) trong bảng UserTripPlans
    # Sắp xếp theo updated_at giảm dần để lấy cái mới nhất
    latest_plan = session.exec(
        select(UserTripPlans)
        .where(UserTripPlans.user_id == user_uuid)
        .order_by(UserTripPlans.updated_at.desc())
    ).first()
    
    # Nếu chưa có plan nào trong bảng mới, fallback về Profile cũ hoặc báo lỗi
    if not latest_plan:
        # Thử lấy từ Profile (cho tương thích ngược)
        user_profile = session.exec(select(Profiles).where(Profiles.auth_user_id == user_uuid)).first()
        if user_profile and user_profile.preferred_city and user_profile.travel_dates:
             # Tạo giả object plan từ profile
             class TempPlan:
                 preferred_city = user_profile.preferred_city
                 travel_dates = user_profile.travel_dates
                 itinerary = user_profile.itinerary
             latest_plan = TempPlan()
        else:
            raise HTTPException(404, "Bạn chưa có kế hoạch du lịch nào. Hãy cập nhật hồ sơ trước.")

    # 2. Tìm nhóm khớp với Plan mới nhất
    # Lưu ý: Convert DATERANGE thành chuỗi để so sánh trong SQL nếu cần, hoặc dùng parameter binding
    # Ở đây ta dùng text literal cho an toàn với daterange
    statement = select(TravelGroup).where(
        TravelGroup.status == "open",
        TravelGroup.preferred_city == latest_plan.preferred_city, 
        text(f"travel_dates = '{latest_plan.travel_dates}'::daterange") 
    )
    candidates = session.exec(statement).all()
    
    if not candidates:
        raise HTTPException(404, f"Không có nhóm nào đi {latest_plan.preferred_city} đúng ngày này.")

    valid_candidates = []
    ai_input_list = []
    
    for group in candidates:
        # Bỏ qua nhóm mình làm chủ
        if group.owner_id == user_uuid: continue 
        
        # Bỏ qua nhóm mình đang pending
        is_pending = False
        if group.pending_requests:
            for req in group.pending_requests:
                if req.get("profile_uuid") == user_uuid: is_pending = True
        if is_pending: continue
        
        # Bỏ qua nhóm mình ĐÃ tham gia (check joined_groups của profile)
        # (Đoạn này tối ưu: có thể query profile 1 lần ở trên)
        
        valid_candidates.append(group)
        ai_input_list.append({"id": group.id, "itinerary": group.itinerary})

    if not valid_candidates: 
        raise HTTPException(404, "Không tìm thấy nhóm phù hợp (hoặc bạn đã tham gia hết rồi).")

    # GỌI AI: So sánh Itinerary của PLAN MỚI NHẤT với các nhóm
    ai_scores_map = await ai_service.rank_groups_by_itinerary_ai(
        latest_plan.itinerary, 
        ai_input_list
    )
    
    results = []
    for group in valid_candidates:
        score = ai_scores_map.get(group.id, 0.0)
        current_count = len(group.members or []) 
        
        results.append(SuggestionOutput(
            group_id=group.id, 
            name=group.name, 
            score=score,
            group_image_url=getattr(group, "group_image_url", None),
            member_count=current_count, 
            max_members=group.max_members
        ))

    results.sort(key=lambda x: x.score, reverse=True)
    return results

async def get_public_group_plan(session: Session, group_id: int) -> GroupPlanOutput:
    group = session.get(TravelGroup, group_id)
    if not group: raise HTTPException(404, "Nhóm không tồn tại")
    return GroupPlanOutput(
        group_id=group.id, 
        group_name=group.name, 
        preferred_city=group.preferred_city,
        travel_dates=group.travel_dates, 
        itinerary=group.itinerary,
        group_image_url=getattr(group, "group_image_url", None),
        interests=group.interests or [] 
    )