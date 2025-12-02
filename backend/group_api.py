from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session
from database import get_session
from group_models import (
    CreateGroupInput, RequestJoinInput, ActionRequestInput, 
    CancelRequestInput, PendingRequestPublic, GroupPlanOutput,
    GroupDetailPublic, SuggestionOutput 
)
from auth_guard import get_current_user
from typing import List, Any, Dict 

# Import service từ các file con
from group_services import host, join, member, discovery

router = APIRouter(prefix="/groups", tags=["GĐ 18 - Groups Final"])

# ====================================================================
# 1. NHÓM API: KHÁM PHÁ & GIA NHẬP (Guest)
# ====================================================================
@router.get("/suggest", response_model=List[SuggestionOutput])
async def suggest_groups(session: Session = Depends(get_session), user = Depends(get_current_user)):
    return await discovery.group_suggest_service(session, user)

@router.get("/{group_id}/public-plan", response_model=GroupPlanOutput)
async def get_group_plan_public(group_id: int, session: Session = Depends(get_session), user = Depends(get_current_user)):
    return await discovery.get_public_group_plan(session, group_id)

@router.post("/request-join")
async def request_join(data: RequestJoinInput, session: Session = Depends(get_session), user = Depends(get_current_user)):
    return await join.request_join_group(session, data.group_id, user)

@router.post("/request-cancel")
async def cancel_request(data: CancelRequestInput, session: Session = Depends(get_session), user = Depends(get_current_user)):
    return await join.cancel_join_request(session, data.group_id, user)

# ====================================================================
# 2. NHÓM API: THÀNH VIÊN (Member)
# ====================================================================

# Lấy danh sách tất cả các nhóm mình đã tham gia
@router.get("/mine", response_model=List[Dict])
async def get_my_groups_list(
    session: Session = Depends(get_session), 
    user = Depends(get_current_user)
):
    return await member.get_my_groups_list_service(session, str(user.id))

# Xem chi tiết 1 nhóm cụ thể (Bắt buộc truyền ID)
@router.get("/{group_id}/detail", response_model=GroupDetailPublic)
async def get_group_detail(
    group_id: int, 
    session: Session = Depends(get_session), 
    user = Depends(get_current_user)
):
    return await member.get_group_detail_by_id(session, str(user.id), group_id)

# Xem lịch trình của 1 nhóm cụ thể
@router.get("/{group_id}/plan", response_model=GroupPlanOutput) 
async def get_group_plan(
    group_id: int,
    session: Session = Depends(get_session), 
    user = Depends(get_current_user)
):
    return await member.get_group_plan_by_id(session, str(user.id), group_id)

# Rời khỏi 1 nhóm cụ thể
@router.post("/{group_id}/leave")
async def leave_group(
    group_id: int,
    session: Session = Depends(get_session), 
    user = Depends(get_current_user)
):
    return await member.leave_group_service(session, group_id, user)

# ====================================================================
# 3. NHÓM API: TRƯỞNG NHÓM (Host)
# ====================================================================
@router.post("/create")
async def create_group(data: CreateGroupInput, session: Session = Depends(get_session), user = Depends(get_current_user)):
    group = await host.create_group_service(session, data, user)
    return {"group_id": group.id, "name": group.name, "owner_uuid": group.owner_id}

@router.patch("/manage")
async def manage_request(data: ActionRequestInput, session: Session = Depends(get_session), user = Depends(get_current_user)):
    # Host duyệt đơn (Accept/Reject/Kick) - cần group_id trong body
    return await host.handle_group_request(session, data.group_id, data.profile_uuid, data.action, user)

@router.get("/{group_id}/requests", response_model=List[PendingRequestPublic])
async def get_pending_requests(group_id: int, session: Session = Depends(get_session), user = Depends(get_current_user)):
    # Host xem danh sách chờ của 1 nhóm cụ thể
    return await host.get_pending_requests(session, group_id, user)

@router.post("/{group_id}/dissolve")
async def host_dissolve_group(group_id: int, session: Session = Depends(get_session), user = Depends(get_current_user)):
    # Host giải tán 1 nhóm cụ thể
    return await host.dissolve_group_service(session, group_id, user)