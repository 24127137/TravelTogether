from sqlmodel import Session, select
from db_tables import TravelGroup, Profiles
from group_models import GroupDetailPublic, GroupPlanOutput
from fastapi import HTTPException
from typing import Dict, Any
from .utils import enrich_group_members, get_user_group_info, is_group_expired

async def leave_group_service(session: Session, current_user: Any) -> Dict:
    user_uuid = str(current_user.id)
    user = session.exec(select(Profiles).where(Profiles.auth_user_id == user_uuid)).first()
    if not user.joined_groups: raise HTTPException(status_code=400, detail="Bạn không trong nhóm nào")
    
    group_id = user.joined_groups[0]['group_id']
    group = session.get(TravelGroup, group_id)
    
    try:
        msg = ""
        if group:
            if is_group_expired(group):
                msg = "Đã rời nhóm (Lịch sử nhóm vẫn được lưu)."
            else:
                current_members = list(group.members or [])
                new_members = [m for m in current_members if m.get("profile_uuid") != user_uuid]
                group.members = new_members
                if group.status == 'closed': group.status = "open"
                session.add(group)
                msg = "Bạn đã rời nhóm thành công."
        
        user.joined_groups = []
        session.add(user)
        session.commit()
        return {"message": msg}
        
    except Exception as e:
        session.rollback()
        raise HTTPException(status_code=500, detail=f"Lỗi: {e}")

async def get_my_group_detail(session: Session, auth_uuid: str) -> GroupDetailPublic:
    profile = session.exec(select(Profiles).where(Profiles.auth_user_id == auth_uuid)).first()
    group_id = None
    if profile.joined_groups: group_id = profile.joined_groups[0]['group_id']
    elif profile.owned_groups: group_id = profile.owned_groups[0]['group_id']
    if not group_id: raise HTTPException(status_code=404, detail="Bạn chưa có nhóm")
    
    group = session.get(TravelGroup, group_id)
    enriched = enrich_group_members(session, group)
    return GroupDetailPublic(
        id=group.id, name=group.name, status=group.status,
        member_count=len(group.members), max_members=group.max_members,
        members=enriched,
        group_image_url=getattr(group, "group_image_url", None)
    )

async def get_group_plan(session: Session, auth_uuid: str) -> GroupPlanOutput:
    sender_id, group_id, group_db_object = await get_user_group_info(session, auth_uuid)
    plan_output = GroupPlanOutput.model_validate(group_db_object)
    if hasattr(group_db_object, "group_image_url"):
         plan_output.group_image_url = group_db_object.group_image_url
    return plan_output