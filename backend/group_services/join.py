from sqlmodel import Session, select
from db_tables import TravelGroup, Profiles
from fastapi import HTTPException
from typing import Dict, Any # <-- Đã import Any
from datetime import datetime
from .utils import validate_user_profile_completeness, check_date_overlap

async def request_join_group(session: Session, group_id: int, current_user: Any) -> Dict:
    user_uuid = str(current_user.id)
    user = session.exec(select(Profiles).where(Profiles.auth_user_id == user_uuid)).first()
    group = session.exec(select(TravelGroup).where(TravelGroup.id == group_id)).first()
    
    if not user or not group: raise HTTPException(404, "Không tìm thấy.")
    validate_user_profile_completeness(user)

    if group.status != "open": raise HTTPException(400, "Nhóm đã đóng.")
    
    # Check overlap với các nhóm đang tham gia
    for joined_group_info in (user.joined_groups or []) + (user.owned_groups or []):
        gid = joined_group_info.get('group_id')
        if gid:
            curr_grp = session.get(TravelGroup, gid)
            if curr_grp and check_date_overlap(curr_grp.travel_dates, group.travel_dates):
                raise HTTPException(400, "Lịch trình bị trùng với nhóm khác bạn đang tham gia.")

    current_reqs = group.pending_requests or []
    if any(r.get("profile_uuid") == user_uuid for r in current_reqs):
        raise HTTPException(400, "Đã gửi yêu cầu rồi.")

    try:
        new_req = {
            "profile_uuid": user_uuid, "email": user.email, 
            "fullname": user.fullname, "requested_at": str(datetime.now())
        }
        group.pending_requests = list(current_reqs) + [new_req]

        user_reqs = list(user.pending_requests or [])
        user.pending_requests = user_reqs + [{"group_id": group.id, "group_name": group.name, "status": "pending"}]

        session.add(group)
        session.add(user)
        session.commit() 
        return {"message": "Đã gửi yêu cầu tham gia"}
    except Exception as e:
        session.rollback()
        raise HTTPException(500, str(e))

async def cancel_join_request(session: Session, group_id: int, current_user: Any) -> Dict:
    user_uuid = str(current_user.id)
    user = session.exec(select(Profiles).where(Profiles.auth_user_id == user_uuid)).first()
    group = session.exec(select(TravelGroup).where(TravelGroup.id == group_id)).first()

    if not user or not group: raise HTTPException(404, "Dữ liệu lỗi")

    try:
        g_reqs = list(group.pending_requests or [])
        new_g_reqs = [r for r in g_reqs if r.get("profile_uuid") != user_uuid]
        if len(new_g_reqs) == len(g_reqs): raise HTTPException(400, "Không tìm thấy yêu cầu để hủy")
        group.pending_requests = new_g_reqs

        u_reqs = list(user.pending_requests or [])
        user.pending_requests = [r for r in u_reqs if r.get("group_id") != group.id]

        session.add(group)
        session.add(user)
        session.commit()
        return {"message": "Đã hủy yêu cầu."}
    except Exception as e:
        session.rollback()
        raise HTTPException(500, str(e))