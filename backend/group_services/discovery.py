from sqlmodel import Session, select, text
from db_tables import TravelGroup, Profiles
from group_models import SuggestionOutput, GroupPlanOutput
from fastapi import HTTPException
from typing import List, Any
import ai_service
from .utils import validate_user_profile_completeness

async def group_suggest_service(session: Session, current_user: Any) -> List[SuggestionOutput]:
    user_uuid = str(current_user.id)
    
    # 1. Lấy thông tin từ Profile (Nguồn duy nhất & Đã được validate sạch sẽ)
    user = session.exec(select(Profiles).where(Profiles.auth_user_id == user_uuid)).first()
    validate_user_profile_completeness(user)

    # 2. Tìm nhóm khớp City và Date
    # Vì user.travel_dates đã được bảo đảm không trùng với các nhóm user đang tham gia (nhờ user_service)
    # Nên ta KHÔNG CẦN vòng lặp check_date_overlap ở đây nữa.
    statement = select(TravelGroup).where(
        TravelGroup.status == "open",
        TravelGroup.preferred_city == user.preferred_city,
        text(f"travel_dates = '{user.travel_dates}'::daterange") 
    )
    candidates = session.exec(statement).all()
    
    if not candidates:
        raise HTTPException(
            status_code=404, 
            detail=f"Không có nhóm nào đi {user.preferred_city} đúng ngày này."
        )

    valid_candidates = []
    ai_input_list = []
    
    for group in candidates:
        # Lọc chính mình (Host)
        if group.owner_id == user_uuid: continue 
        
        # Lọc Pending
        is_pending = False
        if group.pending_requests:
            for req in group.pending_requests:
                if req.get("profile_uuid") == user_uuid: is_pending = True
        if is_pending: continue
        
        # Lọc đã Join
        # (Thực ra query theo ngày ở trên đã lọc rồi vì ngày trong profile không thể trùng với ngày nhóm đã join, 
        # nhưng giữ lại check id này cho chắc chắn 100%)
        is_joined = False
        if user.joined_groups:
             for j in user.joined_groups:
                 if j.get('group_id') == group.id: is_joined = True
        if is_joined: continue
        
        valid_candidates.append(group)
        ai_input_list.append({"id": group.id, "itinerary": group.itinerary})

    if not valid_candidates:
        raise HTTPException(status_code=404, detail="Không tìm thấy nhóm phù hợp.")

    # 3. Gọi AI chấm điểm
    ai_scores_map = await ai_service.rank_groups_by_itinerary_ai(
        user.itinerary,
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