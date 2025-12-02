from sqlmodel import Session, select, text
from db_tables import TravelGroup, Profiles
from datetime import datetime, date
from typing import List, Optional, Any, Dict, Tuple
from fastapi import HTTPException
from group_models import GroupMemberPublic

# --- CÁC HÀM HỖ TRỢ LOGIC ---

def list_to_daterange(date_list: Optional[List[str]]) -> Optional[Any]:
    if not date_list or len(date_list) != 2: return None
    try:
        start = date.fromisoformat(date_list[0])
        end = date.fromisoformat(date_list[1])
        range_str = f"[{start},{end}]" 
        return text(f"'{range_str}'::daterange")
    except ValueError: return None

def is_group_expired(group: TravelGroup) -> bool:
    if not group.travel_dates: return False
    try:
        end_date = group.travel_dates.upper
        if not end_date: return False
        return end_date < date.today()
    except Exception: return False

def enrich_group_members(session: Session, group: TravelGroup) -> List[GroupMemberPublic]:
    if not group.members: return []
    member_uuids = [m.get("profile_uuid") for m in group.members]
    if not member_uuids: return []
    
    profiles = session.exec(select(Profiles).where(Profiles.auth_user_id.in_(member_uuids))).all()
    profile_map = {p.auth_user_id: p for p in profiles}
    
    enriched = []
    for m in group.members:
        uid = m.get("profile_uuid")
        role = m.get("role")
        profile = profile_map.get(uid)
        if profile:
            enriched.append(GroupMemberPublic(
                profile_uuid=uid, role=role,
                fullname=profile.fullname or "Chưa đặt tên",
                email=profile.email, avatar_url=profile.avatar_url
            ))
    return enriched

def validate_user_profile_completeness(user: Profiles):
    if not user.preferred_city or not user.travel_dates:
        raise HTTPException(400, "Vui lòng cập nhật City và Dates trong hồ sơ trước khi tham gia nhóm.")

def check_date_overlap(range_a: Any, range_b: Any) -> bool:
    """
    Kiểm tra 2 khoảng thời gian có trùng nhau không.
    Logic: (StartA <= EndB) AND (StartB <= EndA)
    """
    if not range_a or not range_b: return False
    # PostgreSQL daterange object có thuộc tính .lower (start) và .upper (end)
    start_a, end_a = range_a.lower, range_a.upper
    start_b, end_b = range_b.lower, range_b.upper
    
    if start_a and end_a and start_b and end_b:
        return start_a <= end_b and start_b <= end_a
    return False

async def get_group_by_id_and_check_membership(session: Session, auth_uuid: str, group_id: int) -> TravelGroup:
    """Helper: Lấy group và check xem user có phải member/host không"""
    profile = session.exec(select(Profiles).where(Profiles.auth_user_id == auth_uuid)).first()
    if not profile: raise HTTPException(404, "Profile not found")

    is_host = any(g.get('group_id') == group_id for g in profile.owned_groups or [])
    is_member = any(g.get('group_id') == group_id for g in profile.joined_groups or [])
    
    if not (is_host or is_member):
        raise HTTPException(403, "Bạn không thuộc nhóm này.")
        
    group = session.get(TravelGroup, group_id)
    if not group: raise HTTPException(404, "Nhóm không tồn tại")
    return group