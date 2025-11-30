from sqlmodel import Session, select
from db_tables import TravelGroup, Profiles
from group_models import CreateGroupInput, PendingRequestPublic
from fastapi import HTTPException
from typing import Dict, List, Any
from datetime import datetime
from .utils import (
    validate_user_profile_completeness, cancel_all_pending_requests,
    get_host_group_info, is_group_expired
)

async def create_group_service(session: Session, group_data: CreateGroupInput, current_user: Any) -> TravelGroup:
    owner_uuid = str(current_user.id)
    owner = session.exec(select(Profiles).where(Profiles.auth_user_id == owner_uuid)).first()
    
    if not owner: raise HTTPException(status_code=404, detail="Profile không tồn tại")
    
    validate_user_profile_completeness(owner)
    if owner.owned_groups: raise HTTPException(status_code=400, detail="Bạn đã là Host.")
    if owner.joined_groups: raise HTTPException(status_code=400, detail="Bạn đã là Member.")

    try:
        cancel_all_pending_requests(session, owner)
        
        group = TravelGroup(
            name=group_data.name,
            owner_id=owner_uuid, 
            max_members=group_data.max_members,
            preferred_city=owner.preferred_city,
            travel_dates=owner.travel_dates,
            interests=owner.interests or [], 
            itinerary=owner.itinerary,
            group_image_url=group_data.group_image_url,
            members=[{"profile_uuid": owner_uuid, "email": owner.email, "role": "owner"}], 
            pending_requests=[],
            created_at=datetime.now()
        )
        session.add(group)
        session.commit()
        session.refresh(group)
        
        owner.owned_groups = [{"group_id": group.id, "name": group.name}]
        session.add(owner)
        session.commit()
        return group
    except HTTPException as he: raise he
    except Exception as e:
        session.rollback()
        raise HTTPException(status_code=500, detail=f"Lỗi: {e}")

async def handle_group_request(session: Session, target_uuid: str, action: str, current_user: Any) -> Dict:
    group = await get_host_group_info(session, current_user)
    target_user = session.exec(select(Profiles).where(Profiles.auth_user_id == target_uuid)).first()
    if not target_user: raise HTTPException(status_code=404, detail="Không tìm thấy User mục tiêu")

    try:
        current_reqs = list(group.pending_requests or [])
        current_members = list(group.members or [])

        if action == "accept":
            if len(current_members) >= group.max_members:
                raise HTTPException(status_code=400, detail="Nhóm đã đầy")
            if target_user.owned_groups or target_user.joined_groups:
                raise HTTPException(status_code=400, detail="User này đã vào nhóm khác.")

            new_reqs = [r for r in current_reqs if r.get("profile_uuid") != target_uuid]
            group.pending_requests = new_reqs
            
            current_members.append({"profile_uuid": target_uuid, "role": "member"})
            group.members = current_members
            
            cancel_all_pending_requests(session, target_user)
            target_user.joined_groups = [{"group_id": group.id, "name": group.name}]
            
        elif action == "reject":
            new_reqs = [r for r in current_reqs if r.get("profile_uuid") != target_uuid]
            group.pending_requests = new_reqs
            
            u_reqs = list(target_user.pending_requests or [])
            target_user.pending_requests = [r for r in u_reqs if r.get("group_id") != group.id]
        
        elif action == "kick":
            if target_uuid == group.owner_id: raise HTTPException(status_code=400, detail="Không thể tự kick.")
            new_members = [m for m in current_members if m.get("profile_uuid") != target_uuid]
            group.members = new_members
            target_user.joined_groups = []

        if len(group.members) >= group.max_members: group.status = "closed"
        else: group.status = "open"

        session.add(group)
        session.add(target_user)
        session.commit()
        return {"message": f"Hành động '{action}' thành công"}
    except Exception as e:
        session.rollback()
        raise HTTPException(status_code=500, detail=f"Lỗi: {e}")

async def dissolve_group_service(session: Session, current_user: Any) -> Dict:
    group = await get_host_group_info(session, current_user)
    host_profile = session.exec(select(Profiles).where(Profiles.auth_user_id == group.owner_id)).first()
    
    try:
        # Dọn dẹp Members
        member_uuids = [m.get("profile_uuid") for m in (group.members or []) if m.get("profile_uuid") != group.owner_id]
        if member_uuids:
            members_db = session.exec(select(Profiles).where(Profiles.auth_user_id.in_(member_uuids))).all()
            for m in members_db:
                m.joined_groups = []
                session.add(m)
        
        # Dọn dẹp Pending Requests
        pending_uuids = [r.get("profile_uuid") for r in (group.pending_requests or [])]
        if pending_uuids:
            pending_users_db = session.exec(select(Profiles).where(Profiles.auth_user_id.in_(pending_uuids))).all()
            for pu in pending_users_db:
                pu_reqs = list(pu.pending_requests or [])
                pu.pending_requests = [r for r in pu_reqs if r.get("group_id") != group.id]
                session.add(pu)
        
        host_profile.owned_groups = []
        session.add(host_profile)
        
        if is_group_expired(group):
            group.status = "expired"
            session.add(group)
            msg = "Nhóm đã kết thúc và được lưu vào lịch sử."
        else:
            session.delete(group)
            msg = "Nhóm đã được giải tán và xóa vĩnh viễn."
        
        session.commit()
        return {"message": msg}
        
    except Exception as e:
        session.rollback()
        raise HTTPException(status_code=500, detail=f"Lỗi: {e}")

async def get_pending_requests(session: Session, current_user: Any) -> List[Dict]:
    group = await get_host_group_info(session, current_user)
<<<<<<< HEAD
    return group.pending_requests or []
=======
    raw_requests = group.pending_requests or []
    if not raw_requests:
        return []
    pending_uuids = [req.get("profile_uuid") for req in raw_requests]
    profiles = session.exec(
        select(Profiles).where(Profiles.auth_user_id.in_(pending_uuids))
    ).all()
    avatar_map = {p.auth_user_id: p.avatar_url for p in profiles}
    enriched_requests = []
    for req in raw_requests:
        req_copy = req.copy()
        req_copy["avatar_url"] = avatar_map.get(req.get("profile_uuid"))
        enriched_requests.append(req_copy)
    return enriched_requests