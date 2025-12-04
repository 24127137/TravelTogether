from sqlmodel import Session, select
from db_tables import TravelGroup, Profiles
from group_models import CreateGroupInput
from fastapi import HTTPException
from typing import Dict, List, Any
from datetime import datetime
from .utils import (
    validate_user_profile_completeness, check_date_overlap, is_group_expired
)
import traceback

# --- Helper: Lấy nhóm nếu user là chủ ---
async def _get_group_if_owner(session: Session, group_id: int, owner_uuid: str) -> TravelGroup:
    group = session.get(TravelGroup, group_id)
    if not group: raise HTTPException(404, "Nhóm không tồn tại")
    if group.owner_id != owner_uuid: raise HTTPException(403, "Bạn không phải chủ nhóm này")
    return group

# --- Helper: Xóa pending requests bị trùng lịch ---
def _cancel_overlapping_pending_requests(session: Session, target_user: Profiles, joined_group_dates: Any):
    if not target_user.pending_requests: return 
    
    pending_to_cancel = []
    # Tìm các nhóm đang pending mà bị trùng lịch
    for req in target_user.pending_requests:
        gid = req.get("group_id")
        if gid:
            grp = session.get(TravelGroup, gid)
            if grp and check_date_overlap(grp.travel_dates, joined_group_dates):
                pending_to_cancel.append(gid)

    if not pending_to_cancel: return

    # 1. Xóa user khỏi danh sách chờ của các nhóm đó
    groups = session.exec(select(TravelGroup).where(TravelGroup.id.in_(pending_to_cancel))).all()
    for g in groups:
        current_reqs = list(g.pending_requests or [])
        new_reqs = [r for r in current_reqs if r.get("profile_uuid") != target_user.auth_user_id]
        g.pending_requests = new_reqs
        session.add(g)
    
    # 2. Xóa request khỏi profile của user
    target_user.pending_requests = [r for r in target_user.pending_requests if r.get("group_id") not in pending_to_cancel]
    session.add(target_user)

# ====================================================================
# SERVICES
# ====================================================================

async def create_group_service(session: Session, group_data: CreateGroupInput, current_user: Any) -> TravelGroup:
    owner_uuid = str(current_user.id)
    owner = session.exec(select(Profiles).where(Profiles.auth_user_id == owner_uuid)).first()
    if not owner: raise HTTPException(404, "Lỗi profile")
    validate_user_profile_completeness(owner)
    
    # Check overlap với các nhóm đang tham gia
    for g_info in (owner.owned_groups or []) + (owner.joined_groups or []):
        gid = g_info.get('group_id')
        if gid:
            grp = session.get(TravelGroup, gid)
            if grp and check_date_overlap(grp.travel_dates, owner.travel_dates):
                raise HTTPException(400, "Lịch trình bị trùng với nhóm khác bạn đang tham gia.")

    try:
        group = TravelGroup(
            name=group_data.name, owner_id=owner_uuid, max_members=group_data.max_members,
            preferred_city=owner.preferred_city, travel_dates=owner.travel_dates,
            interests=owner.interests or [], itinerary=owner.itinerary,
            group_image_url=group_data.group_image_url,
            members=[{"profile_uuid": owner_uuid, "email": owner.email, "role": "owner"}], 
            pending_requests=[], created_at=datetime.now()
        )
        session.add(group)
        session.commit()
        session.refresh(group)
        
        # Update owner profile
        owned = list(owner.owned_groups or [])
        owned.append({"group_id": group.id, "name": group.name})
        owner.owned_groups = owned
        
        # Dọn dẹp các pending request cũ bị trùng lịch với nhóm mới tạo
        _cancel_overlapping_pending_requests(session, owner, group.travel_dates)
        
        session.add(owner)
        session.commit()
        return group
    except Exception as e:
        session.rollback()
        raise HTTPException(500, str(e))

async def handle_group_request(session: Session, group_id: int, target_uuid: str, action: str, current_user: Any) -> Dict:
    group = await _get_group_if_owner(session, group_id, str(current_user.id))
    target_user = session.exec(select(Profiles).where(Profiles.auth_user_id == target_uuid)).first()
    if not target_user: raise HTTPException(404, "User không tồn tại")

    try:
        if action == "accept":
            if len(group.members) >= group.max_members: raise HTTPException(400, "Nhóm đã đầy")
            
            # Check overlap user target (kiểm tra lần cuối)
            for g_info in (target_user.owned_groups or []) + (target_user.joined_groups or []):
                gid = g_info.get('group_id')
                if gid:
                    grp = session.get(TravelGroup, gid)
                    if grp and check_date_overlap(grp.travel_dates, group.travel_dates):
                        raise HTTPException(400, "User này bị trùng lịch với nhóm khác.")

            # Add member
            mems = list(group.members)
            mems.append({"profile_uuid": target_uuid, "role": "member"})
            group.members = mems
            
            # Remove from request list
            group.pending_requests = [r for r in (group.pending_requests or []) if r.get("profile_uuid") != target_uuid]
            
            # Update user profile
            joined = list(target_user.joined_groups or [])
            joined.append({"group_id": group.id, "name": group.name})
            target_user.joined_groups = joined
            
            # Clean up other conflicting requests
            _cancel_overlapping_pending_requests(session, target_user, group.travel_dates)
            
        elif action == "reject":
            group.pending_requests = [r for r in (group.pending_requests or []) if r.get("profile_uuid") != target_uuid]
            target_user.pending_requests = [r for r in (target_user.pending_requests or []) if r.get("group_id") != group.id]
        
        elif action == "kick":
            if target_uuid == group.owner_id: raise HTTPException(400, "Không thể kick host")
            group.members = [m for m in group.members if m.get("profile_uuid") != target_uuid]
            target_user.joined_groups = [g for g in (target_user.joined_groups or []) if g.get('group_id') != group.id]
            
        # Update status
        group.status = "closed" if len(group.members) >= group.max_members else "open"

        session.add(group)
        session.add(target_user)
        session.commit()
        return {"message": "Success"}
    except Exception as e:
        session.rollback()
        raise HTTPException(500, str(e))

async def dissolve_group_service(session: Session, group_id: int, current_user: Any) -> Dict:
    owner_uuid = str(current_user.id)
    group = await _get_group_if_owner(session, group_id, owner_uuid)
    host_profile = session.exec(select(Profiles).where(Profiles.auth_user_id == owner_uuid)).first()
    
    try:
        # Clean members
        m_uuids = [m.get("profile_uuid") for m in group.members if m.get("profile_uuid") != owner_uuid]
        if m_uuids:
            mems = session.exec(select(Profiles).where(Profiles.auth_user_id.in_(m_uuids))).all()
            for m in mems:
                m.joined_groups = [g for g in (m.joined_groups or []) if g.get('group_id') != group.id]
                session.add(m)
        
        # Clean pending
        p_uuids = [r.get("profile_uuid") for r in (group.pending_requests or [])]
        if p_uuids:
            p_users = session.exec(select(Profiles).where(Profiles.auth_user_id.in_(p_uuids))).all()
            for pu in p_users:
                pu.pending_requests = [r for r in (pu.pending_requests or []) if r.get("group_id") != group.id]
                session.add(pu)
        
        # Clean host
        host_profile.owned_groups = [g for g in (host_profile.owned_groups or []) if g.get('group_id') != group.id]
        session.add(host_profile)
        
        if is_group_expired(group):
            group.status = "expired"
            session.add(group)
            msg = "Nhóm đã lưu vào lịch sử."
        else:
            session.delete(group)
            msg = "Nhóm đã giải tán."
        
        session.commit()
        return {"message": msg}
    except Exception as e:
        session.rollback()
        raise HTTPException(500, str(e))

async def get_pending_requests(session: Session, group_id: int, current_user: Any) -> List[Dict]:
    group = await _get_group_if_owner(session, group_id, str(current_user.id))
    raw_requests = group.pending_requests or []
    if not raw_requests: return []

    uuids = [r.get("profile_uuid") for r in raw_requests]
    profiles = session.exec(select(Profiles).where(Profiles.auth_user_id.in_(uuids))).all()
    avatars = {p.auth_user_id: p.avatar_url for p in profiles}
    
    res = []
    for r in raw_requests:
        c = r.copy()
        c["avatar_url"] = avatars.get(r.get("profile_uuid"))
        res.append(c)
    return res