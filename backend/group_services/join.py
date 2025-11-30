from sqlmodel import Session, select
from db_tables import TravelGroup, Profiles
from fastapi import HTTPException
from typing import Dict, Any  # <--- Đã thêm Any vào đây
from datetime import datetime
from .utils import validate_user_profile_completeness

async def request_join_group(session: Session, group_id: int, current_user: Any) -> Dict:
    user_uuid = str(current_user.id)
    user = session.exec(select(Profiles).where(Profiles.auth_user_id == user_uuid)).first()
    group = session.exec(select(TravelGroup).where(TravelGroup.id == group_id)).first()
    
    if not user or not group: raise HTTPException(status_code=404, detail="Không tìm thấy.")
    
    validate_user_profile_completeness(user)

    if group.status != "open": raise HTTPException(status_code=400, detail="Nhóm đã đóng.")
    if user.owned_groups or user.joined_groups: 
        raise HTTPException(status_code=400, detail="Bạn đang trong một nhóm khác.")
    
    current_group_reqs = group.pending_requests or []
    if any(r.get("profile_uuid") == user_uuid for r in current_group_reqs):
        raise HTTPException(status_code=400, detail="Đã gửi yêu cầu rồi")

    try:
        new_req = {
            "profile_uuid": user_uuid, 
            "email": user.email, 
            "fullname": user.fullname, 
            "requested_at": str(datetime.now())
        }
        group.pending_requests = list(current_group_reqs) + [new_req]

        user_reqs = list(user.pending_requests or [])
        user.pending_requests = user_reqs + [{"group_id": group.id, "group_name": group.name, "status": "pending"}]

        session.add(group)
        session.add(user)
        session.commit() 
        return {"message": "Yêu cầu đã được gửi"}
    except Exception as e:
        session.rollback()
        raise HTTPException(status_code=500, detail=f"Lỗi: {e}")

async def cancel_join_request(session: Session, group_id: int, current_user: Any) -> Dict:
    user_uuid = str(current_user.id)
    user = session.exec(select(Profiles).where(Profiles.auth_user_id == user_uuid)).first()
    group = session.exec(select(TravelGroup).where(TravelGroup.id == group_id)).first()

    if not user or not group: raise HTTPException(status_code=404, detail="Dữ liệu không tồn tại")

    try:
        g_reqs = list(group.pending_requests or [])
        new_g_reqs = [r for r in g_reqs if r.get("profile_uuid") != user_uuid]
        if len(new_g_reqs) == len(g_reqs): raise HTTPException(status_code=400, detail="Không có yêu cầu nào để hủy")
        group.pending_requests = new_g_reqs

        u_reqs = list(user.pending_requests or [])
        new_u_reqs = [r for r in u_reqs if r.get("group_id") != group.id]
        user.pending_requests = new_u_reqs

        session.add(group)
        session.add(user)
        session.commit()
        return {"message": "Đã hủy yêu cầu."}
    except HTTPException as he: raise he
    except Exception as e:
        session.rollback()
        raise HTTPException(status_code=500, detail=f"Lỗi: {e}")