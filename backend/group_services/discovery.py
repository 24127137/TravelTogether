from sqlmodel import Session, select, text
from db_tables import TravelGroup, Profiles
from group_models import SuggestionOutput, GroupPlanOutput
from fastapi import HTTPException
from typing import List, Any
import ai_service
from .utils import validate_user_profile_completeness

async def group_suggest_service(session: Session, current_user: Any) -> List[SuggestionOutput]:
    user_uuid = str(current_user.id)
    user = session.exec(select(Profiles).where(Profiles.auth_user_id == user_uuid)).first()
    
    validate_user_profile_completeness(user)

    # LỌC CỨNG
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
        if group.owner_id == user_uuid: continue 
        if any(r.get("profile_uuid") == user_uuid for r in (group.pending_requests or [])): continue
        
        valid_candidates.append(group)
        ai_input_list.append({
            "id": group.id,
            "itinerary": group.itinerary
        })

    if not valid_candidates:
        raise HTTPException(status_code=404, detail="Không tìm thấy nhóm phù hợp (đã lọc trùng).")

    # GỌI AI
    ai_scores_map = await ai_service.rank_groups_by_itinerary_ai(
        user_itinerary=user.itinerary,
        candidate_groups=ai_input_list
    )
    
    results = []
    for group in valid_candidates:
        score = ai_scores_map.get(group.id, 0.0)
        
        # [TÍNH TOÁN SỐ LƯỢNG MEMBER]
        # group.members là list JSON, dùng len() để đếm
        current_count = len(group.members or []) 
        
        results.append(SuggestionOutput(
            group_id=group.id, 
            name=group.name, 
            score=score,
            group_image_url=getattr(group, "group_image_url", None),
            
            # [GÁN GIÁ TRỊ VÀO ĐÂY]
            member_count=current_count,
            max_members=group.max_members
        ))

    results.sort(key=lambda x: x.score, reverse=True)
    return results

async def get_public_group_plan(session: Session, group_id: int) -> GroupPlanOutput:
    group = session.get(TravelGroup, group_id)
    if not group: raise HTTPException(status_code=404, detail="Nhóm không tồn tại")
    return GroupPlanOutput(
        group_id=group.id, group_name=group.name, preferred_city=group.preferred_city,
        travel_dates=group.travel_dates, itinerary=group.itinerary,
        group_image_url=getattr(group, "group_image_url", None),
        interests=group.interests or [] 
    )