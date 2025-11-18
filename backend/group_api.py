# group_api.py
from fastapi import APIRouter, Depends, Query, HTTPException
from pydantic import EmailStr
from sqlmodel import Session, select
from database import get_session
# Import service (bộ não)
import group_service
# === SỬA ĐỔI (GĐ 15.2): Import model "Kế hoạch" mới ===
from group_models import (
    CreateGroupInput, RequestJoinInput, ActionRequestInput,
    PendingRequestPublic, GroupExitInput, GroupPlanOutput # <-- Sửa ở đây
)
from auth_guard import get_current_user
from typing import List, Any, Dict 

# ====================================================================
# ROUTER: /groups (GĐ 15.2 - Plan Cập nhật)
# ====================================================================
router = APIRouter(prefix="/groups", tags=["GĐ 15 - Groups & Plan"])

# ====================================================================
# API TẠO NHÓM (Không thay đổi)
# ====================================================================
@router.post("/create")
async def create_group(
    data: CreateGroupInput,
    session: Session = Depends(get_session),
    user = Depends(get_current_user)
):
    group = await group_service.create_group_service_v2(session, data, user)
    return {"group_id": group.id, "name": group.name, "owner_uuid": group.owner_id}

# ====================================================================
# API XIN VÀO NHÓM (Không thay đổi)
# ====================================================================
@router.post("/request-join")
async def request_join(
    data: RequestJoinInput,
    session: Session = Depends(get_session),
    user = Depends(get_current_user)
):
    return await group_service.request_join_group_v2(session, data.group_id, user)

# ====================================================================
# API GỢI Ý NHÓM (Không thay đổi)
# ====================================================================
@router.get("/suggest", response_model=List[Dict[str, Any]])
async def suggest_groups(
    session: Session = Depends(get_session),
    user = Depends(get_current_user)
):
    return await group_service.group_suggest_service_v2(session, user)

# ====================================================================
# API LẤY LỊCH TRÌNH NHÓM (SỬA ĐỔI GĐ 15.2)
# ====================================================================
@router.get("/plan", response_model=GroupPlanOutput) # <-- SỬA Ở ĐÂY
async def get_my_group_plan(
    session: Session = Depends(get_session),
    user = Depends(get_current_user)
):
    """
    (Nâng cấp GĐ 15.2) Lấy Kế hoạch (Plan) của nhóm.
    (Gồm city, dates, itinerary)
    """
    auth_uuid = str(user.id)
    plan = await group_service.get_group_plan_service(session, auth_uuid)
    return plan

# ====================================================================
# API HOST: QUẢN LÝ (Không thay đổi)
# ====================================================================
@router.patch("/manage", response_model=Dict[str, str])
async def manage_request_auto(
    data: ActionRequestInput, 
    session: Session = Depends(get_session),
    user = Depends(get_current_user)
):
    """ (GĐ 13) Host duyệt/kick. Tự động tìm Group ID. """
    return await group_service.handle_group_request_v2(
        session, data.profile_uuid, data.action, user
    )

@router.get("/manage/requests", response_model=List[PendingRequestPublic])
async def get_pending_requests_auto(
    session: Session = Depends(get_session),
    user = Depends(get_current_user)
):
    """ (GĐ 13) Host xem danh sách chờ. Tự động tìm Group ID. """
    requests_list = await group_service.get_pending_requests_service(session, user)
    return [PendingRequestPublic.model_validate(req) for req in requests_list]

# ====================================================================
# API RỜI NHÓM / GIẢI TÁN (Không thay đổi)
# ====================================================================
@router.post("/leave", response_model=Dict[str, str])
async def leave_group(
    session: Session = Depends(get_session),
    user = Depends(get_current_user)
):
    """ (GĐ 14) Dành cho Member thường RỜI NHÓM. """
    return await group_service.leave_group_service(session, user)

@router.post("/exit", response_model=Dict[str, str])
async def host_exit_group(
    data: GroupExitInput, 
    session: Session = Depends(get_session),
    user = Depends(get_current_user)
):
    """ (GĐ 14) Dành cho Host: GIẢI TÁN hoặc NHƯỜNG QUYỀN. """
    return await group_service.host_exit_service(session, data, user)