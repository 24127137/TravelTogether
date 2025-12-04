from sqlmodel import Session, select
from db_tables import TravelGroup, Profiles
from group_models import GroupDetailPublic, GroupPlanOutput
from fastapi import HTTPException
from typing import Dict, Any, List
from .utils import enrich_group_members, is_group_expired, get_group_by_id_and_check_membership

async def leave_group_service(session: Session, group_id: int, current_user: Any) -> Dict:
    user_uuid = str(current_user.id)
    user = session.exec(select(Profiles).where(Profiles.auth_user_id == user_uuid)).first()
    
    # Check quyền
    is_member = any(g.get('group_id') == group_id for g in user.joined_groups or [])
    is_owner = any(g.get('group_id') == group_id for g in user.owned_groups or [])
    
    if not (is_member or is_owner): raise HTTPException(400, "Bạn không trong nhóm này")
    if is_owner: raise HTTPException(400, "Host không thể rời nhóm, hãy giải tán.")
        
    group = session.get(TravelGroup, group_id)
    
    try:
        if group:
            if not is_group_expired(group):
                group.members = [m for m in group.members if m.get("profile_uuid") != user_uuid]
                group.status = "open"
                session.add(group)
        
        user.joined_groups = [g for g in (user.joined_groups or []) if g.get('group_id') != group_id]
        session.add(user)
        session.commit()
        return {"message": "Đã rời nhóm"}
    except Exception as e:
        session.rollback()
        raise HTTPException(500, str(e))

async def get_my_groups_list_service(session: Session, auth_uuid: str) -> List[Dict]:
    profile = session.exec(select(Profiles).where(Profiles.auth_user_id == auth_uuid)).first()
    if not profile: raise HTTPException(404, "Profile lỗi")
    # Trả về tất cả nhóm (cả host và join)
    return (profile.joined_groups or []) + (profile.owned_groups or [])

async def get_group_detail_by_id(session: Session, auth_uuid: str, group_id: int) -> GroupDetailPublic:
    group = await get_group_by_id_and_check_membership(session, auth_uuid, group_id)
    enriched = enrich_group_members(session, group)
    return GroupDetailPublic(
        id=group.id, name=group.name, status=group.status,
        member_count=len(group.members), max_members=group.max_members,
        members=enriched, group_image_url=getattr(group, "group_image_url", None)
    )

async def get_group_plan_by_id(session: Session, auth_uuid: str, group_id: int) -> GroupPlanOutput:
    group = await get_group_by_id_and_check_membership(session, auth_uuid, group_id)
    out = GroupPlanOutput.model_validate(group)
    if hasattr(group, "group_image_url"): out.group_image_url = group.group_image_url
    return out