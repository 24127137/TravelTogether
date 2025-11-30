from sqlmodel import Session, select, text
from db_tables import TravelGroup, Profiles
from datetime import date
from typing import List, Optional, Any
from fastapi import HTTPException
from group_models import GroupMemberPublic

# --- CÁC HÀM HỖ TRỢ LOGIC ---

def list_to_daterange(date_list: Optional[List[str]]) -> Optional[Any]:
    """Chuyển đổi list ngày ['Y-M-D', 'Y-M-D'] sang PostgreSQL DATERANGE"""
    if not date_list or len(date_list) != 2: return None
    try:
        start = date.fromisoformat(date_list[0])
        end = date.fromisoformat(date_list[1])
        range_str = f"[{start},{end}]" 
        return text(f"'{range_str}'::daterange")
    except ValueError: return None

def is_group_expired(group: TravelGroup) -> bool:
    """Kiểm tra xem nhóm đã quá hạn (đi xong) chưa"""
    if not group.travel_dates: return False
    try:
        end_date = group.travel_dates.upper
        if not end_date: return False
        today = date.today()
        return end_date < today
    except Exception: return False

def cancel_all_pending_requests(session: Session, user: Profiles):
    """Hủy tất cả yêu cầu xin vào nhóm khác của User này"""
    if not user.pending_requests: return 
    
    group_ids = [req.get("group_id") for req in user.pending_requests if req.get("group_id")]
    if group_ids:
        groups_to_update = session.exec(select(TravelGroup).where(TravelGroup.id.in_(group_ids))).all()
        for group in groups_to_update:
            current_reqs = list(group.pending_requests or [])
            new_reqs = [r for r in current_reqs if r.get("profile_uuid") != user.auth_user_id]
            group.pending_requests = new_reqs
            session.add(group)
    
    user.pending_requests = []
    session.add(user)

def enrich_group_members(session: Session, group: TravelGroup) -> List[GroupMemberPublic]:
    """Lấy thông tin chi tiết (Avatar, Tên...) cho danh sách thành viên"""
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
    """Đảm bảo user có đủ thông tin trước khi tham gia/tạo nhóm"""
    if not user.preferred_city or not user.travel_dates:
        raise HTTPException(
            status_code=400, 
            detail="Bạn chưa cập nhật đầy đủ hồ sơ (City, Dates) để tham gia nhóm."
        )

async def get_host_group_info(session: Session, current_user: Any) -> TravelGroup:
    """Tìm nhóm mà user hiện tại đang làm Host"""
    owner_uuid = str(current_user.id)
    group = session.exec(select(TravelGroup).where(TravelGroup.owner_id == owner_uuid)).first()
    if not group: raise HTTPException(status_code=403, detail="Bạn không phải là Host của nhóm nào")
    return group

async def get_user_group_info(session: Session, auth_uuid: str) -> tuple[str, int, TravelGroup]:
    """Tìm nhóm của user (Dù là Host hay Member) - Dùng chung"""
    profile = session.exec(
        select(Profiles.joined_groups, Profiles.owned_groups)
        .where(Profiles.auth_user_id == auth_uuid)
    ).first()
    
    if not profile: raise HTTPException(status_code=404, detail="Không tìm thấy profile")
    
    sender_id = auth_uuid 
    group_id = None 
    try:
        if profile.joined_groups and len(profile.joined_groups) > 0: 
            group_id = profile.joined_groups[0]['group_id'] 
        elif profile.owned_groups and len(profile.owned_groups) > 0: 
            group_id = profile.owned_groups[0]['group_id']
        
        if group_id is None: raise HTTPException(status_code=400, detail="Chưa tham gia nhóm nào.")
        
        group = session.get(TravelGroup, group_id)
        if not group: raise HTTPException(status_code=404, detail=f"Lỗi dữ liệu nhóm ID: {group_id}")
        
        return sender_id, group_id, group
    except KeyError: raise HTTPException(status_code=500, detail="Lỗi cấu trúc dữ liệu.")
    except Exception as e: raise e