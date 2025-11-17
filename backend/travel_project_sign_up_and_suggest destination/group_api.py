# group_api.py
from fastapi import APIRouter, Depends
from pydantic import EmailStr
from sqlmodel import Session
from database import get_session
from group_service import (
    create_group_from_profile,
    request_join_group,
    handle_group_request,
    group_suggest_by_email_service 
)
from models import CreateGroupInput, RequestJoinInput, ActionRequestInput
from auth_guard import get_current_user

# ====================================================================
# ROUTER: /groups
# ====================================================================
router = APIRouter(prefix="/groups", tags=["Groups"])


# ====================================================================
# TẠO NHÓM
# ====================================================================
@router.post("/create")
async def create_group(
    data: CreateGroupInput,
    session: Session = Depends(get_session),
    user = Depends(get_current_user)
):
    group = await create_group_from_profile(session, data, user)
    return {"group_id": group.id, "name": group.name}


# ====================================================================
# GỬI YÊU CẦU GIA NHẬP
# ====================================================================
@router.post("/request-join")
async def request_join(
    data: RequestJoinInput,
    session: Session = Depends(get_session),
    user = Depends(get_current_user)
):
    return await request_join_group(session, data.group_id, user)


# ====================================================================
# XỬ LÝ YÊU CẦU (chấp nhận/từ chối/kick)
# ====================================================================
@router.patch("/{group_id}/manage")
async def manage_request(
    group_id: int,
    data: ActionRequestInput,
    session: Session = Depends(get_session),
    user = Depends(get_current_user)
):
    return await handle_group_request(session, group_id, data.profile_id, data.action, user)


# ====================================================================
# GỢI Ý NHÓM THEO EMAIL
# ====================================================================
@router.get("/suggest/{email}")
async def suggest_groups(
    email: EmailStr,
    session: Session = Depends(get_session),
    user = Depends(get_current_user)
):
    """
    Gợi ý nhóm phù hợp cho user dựa trên email
    → Trả về danh sách nhóm + điểm + lý do
    """
    suggestions = await group_suggest_by_email_service(session, email)
    return suggestions