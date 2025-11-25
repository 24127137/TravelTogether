from fastapi import APIRouter, Depends, Query, HTTPException
from sqlmodel import Session
from database import get_session
import group_service
# === SỬA LỖI: Xóa GroupExitInput khỏi import ===
from group_models import (
    CreateGroupInput, RequestJoinInput, ActionRequestInput, 
    CancelRequestInput, PendingRequestPublic, GroupPlanOutput,
    GroupDetailPublic, SuggestionOutput 
)
# ===============================================
from auth_guard import get_current_user
from typing import List, Any, Dict 

router = APIRouter(prefix="/groups", tags=["GĐ 18 - Groups Final"])

@router.post("/create")
async def create_group(data: CreateGroupInput, session: Session = Depends(get_session), user = Depends(get_current_user)):
    group = await group_service.create_group_service_v2(session, data, user)
    return {"group_id": group.id, "name": group.name, "owner_uuid": group.owner_id}

@router.post("/request-join")
async def request_join(data: RequestJoinInput, session: Session = Depends(get_session), user = Depends(get_current_user)):
    return await group_service.request_join_group_v2(session, data.group_id, user)

@router.post("/request-cancel")
async def cancel_request(data: CancelRequestInput, session: Session = Depends(get_session), user = Depends(get_current_user)):
    return await group_service.cancel_join_request_service(session, data.group_id, user)

@router.get("/suggest", response_model=List[SuggestionOutput])
async def suggest_groups(session: Session = Depends(get_session), user = Depends(get_current_user)):
    return await group_service.group_suggest_service_v2(session, user)

@router.patch("/manage")
async def manage_request(data: ActionRequestInput, session: Session = Depends(get_session), user = Depends(get_current_user)):
    return await group_service.handle_group_request_v2(session, data.profile_uuid, data.action, user)

@router.get("/manage/requests", response_model=List[PendingRequestPublic])
async def get_pending_requests(session: Session = Depends(get_session), user = Depends(get_current_user)):
    return await group_service.get_pending_requests_service(session, user)

@router.get("/my-group", response_model=GroupDetailPublic)
async def get_my_group_detail(session: Session = Depends(get_session), user = Depends(get_current_user)):
    auth_uuid = str(user.id)
    return await group_service.get_my_group_detail_service(session, auth_uuid)

@router.get("/{group_id}/public-plan", response_model=GroupPlanOutput)
async def get_group_plan_public(group_id: int, session: Session = Depends(get_session), user = Depends(get_current_user)):
    return await group_service.get_public_group_plan(session, group_id)

@router.get("/plan", response_model=GroupPlanOutput) 
async def get_my_group_plan(session: Session = Depends(get_session), user = Depends(get_current_user)):
    auth_uuid = str(user.id)
    plan = await group_service.get_group_plan_service(session, auth_uuid)
    return plan

@router.post("/leave")
async def leave_group(session: Session = Depends(get_session), user = Depends(get_current_user)):
    return await group_service.leave_group_service(session, user)

# === API GIẢI TÁN (KHÔNG INPUT) ===
@router.post("/dissolve")
async def host_dissolve_group(session: Session = Depends(get_session), user = Depends(get_current_user)):
    """Host giải tán nhóm"""
    return await group_service.host_dissolve_group_service(session, user)