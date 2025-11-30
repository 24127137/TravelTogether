from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session
from database import get_session
from auth_guard import get_current_user
from group_models import (
    CreateGroupInput, RequestJoinInput, ActionRequestInput, 
    CancelRequestInput, PendingRequestPublic, GroupPlanOutput,
    GroupDetailPublic, SuggestionOutput 
)
from typing import List

# Import từ các file service đã chia nhỏ
from group_services import host, join, member, discovery

router = APIRouter(prefix="/groups", tags=["GĐ 18 - Groups Final"])

# --- NHÓM HOST ---
@router.post("/create")
async def create_group(data: CreateGroupInput, session: Session = Depends(get_session), user = Depends(get_current_user)):
    return await host.create_group_service(session, data, user)

@router.patch("/manage")
async def manage_request(data: ActionRequestInput, session: Session = Depends(get_session), user = Depends(get_current_user)):
    return await host.handle_group_request(session, data.profile_uuid, data.action, user)

@router.get("/manage/requests", response_model=List[PendingRequestPublic])
async def get_pending_requests(session: Session = Depends(get_session), user = Depends(get_current_user)):
    return await host.get_pending_requests(session, user)

@router.post("/dissolve")
async def host_dissolve_group(session: Session = Depends(get_session), user = Depends(get_current_user)):
    return await host.dissolve_group_service(session, user)

# --- NHÓM JOIN (GUEST) ---
@router.post("/request-join")
async def request_join(data: RequestJoinInput, session: Session = Depends(get_session), user = Depends(get_current_user)):
    return await join.request_join_group(session, data.group_id, user)

@router.post("/request-cancel")
async def cancel_request(data: CancelRequestInput, session: Session = Depends(get_session), user = Depends(get_current_user)):
    return await join.cancel_join_request(session, data.group_id, user)

# --- NHÓM MEMBER ---
@router.get("/my-group", response_model=GroupDetailPublic)
async def get_my_group_detail(session: Session = Depends(get_session), user = Depends(get_current_user)):
    auth_uuid = str(user.id)
    return await member.get_my_group_detail(session, auth_uuid)

@router.get("/plan", response_model=GroupPlanOutput) 
async def get_my_group_plan(session: Session = Depends(get_session), user = Depends(get_current_user)):
    auth_uuid = str(user.id)
    return await member.get_group_plan(session, auth_uuid)

@router.post("/leave")
async def leave_group(session: Session = Depends(get_session), user = Depends(get_current_user)):
    return await member.leave_group_service(session, user)

# --- NHÓM DISCOVERY ---
@router.get("/suggest", response_model=List[SuggestionOutput])
async def suggest_groups(session: Session = Depends(get_session), user = Depends(get_current_user)):
    return await discovery.group_suggest_service(session, user)

@router.get("/{group_id}/public-plan", response_model=GroupPlanOutput)
async def get_group_plan_public(group_id: int, session: Session = Depends(get_session), user = Depends(get_current_user)):
    return await discovery.get_public_group_plan(session, group_id)