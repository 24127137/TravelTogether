from pydantic import EmailStr
from sqlmodel import Session, select, text
from db_tables import TravelGroup, Profiles 
from group_models import (
    CreateGroupInput, GroupPlanOutput,
    GroupDetailPublic, GroupMemberPublic, SuggestionOutput
)
from typing import Any, List, Dict, Optional, Tuple 
from datetime import datetime, date 
from fastapi import HTTPException
import traceback
import json
import re 
# === IMPORT AI SERVICE MỚI ===
import ai_service 
# =============================

# ====================================================================
# 1. CÁC HÀM HỖ TRỢ (HELPERS)
# ====================================================================

def list_to_daterange(date_list: Optional[List[str]]) -> Optional[Any]:
    if not date_list or len(date_list) != 2: return None
    try:
        start = date.fromisoformat(date_list[0])
        end = date.fromisoformat(date_list[1])
        range_str = f"[{start},{end}]" 
        return text(f"'{range_str}'::daterange")
    except ValueError: return None

def _cancel_all_pending_requests(session: Session, user: Profiles):
    if not user.pending_requests: return 
    
    group_ids = [req.get("group_id") for req in user.pending_requests if req.get("group_id")]
    if group_ids:
        groups_to_update = session.exec(select(TravelGroup).where(TravelGroup.id.in_(group_ids))).all()
        for group in groups_to_update:
            current_reqs = list(group.pending_requests or [])
            # Xóa user khỏi pending list của nhóm
            new_reqs = [r for r in current_reqs if r.get("profile_uuid") != user.auth_user_id]
            group.pending_requests = new_reqs
            session.add(group)
    
    user.pending_requests = []
    session.add(user)

def _enrich_group_members(session: Session, group: TravelGroup) -> List[GroupMemberPublic]:
    if not group.members: return []
    member_uuids = [m.get("profile_uuid") for m in group.members]
    if not member_uuids: return []
    
    profiles = session.exec(select(Profiles).where(Profiles.auth_user_id.in_(member_uuids))).all()
    profile_map = {p.auth_user_id: p for p in profiles}
    
    enriched = []
    for m in group.members:
        uid = m.get("profile_uuid")
        role = m.get("role")
        profile = profile_map.get(uid)
        if profile:
            enriched.append(GroupMemberPublic(
                profile_uuid=uid, role=role,
                fullname=profile.fullname or "Chưa đặt tên",
                email=profile.email, avatar_url=profile.avatar_url
            ))
    return enriched

async def _get_host_group_info(session: Session, current_user: Any) -> TravelGroup:
    owner_uuid = str(current_user.id)
    group = session.exec(select(TravelGroup).where(TravelGroup.owner_id == owner_uuid)).first()
    if not group: raise HTTPException(status_code=403, detail="Bạn không phải là Host của nhóm nào")
    return group

async def get_user_group_info(session: Session, auth_uuid: str) -> tuple[str, int, TravelGroup]:
    profile = session.exec(
        select(Profiles.joined_groups, Profiles.owned_groups)
        .where(Profiles.auth_user_id == auth_uuid)
    ).first()
    
    if not profile: raise HTTPException(status_code=404, detail="Không tìm thấy profile")
    
    sender_id = auth_uuid 
    group_id = None 
    try:
        if profile.joined_groups: group_id = profile.joined_groups[0]['group_id'] 
        elif profile.owned_groups: group_id = profile.owned_groups[0]['group_id']
        
        if group_id is None: raise HTTPException(status_code=400, detail="Chưa tham gia nhóm nào.")
        
        group = session.get(TravelGroup, group_id)
        if not group: raise HTTPException(status_code=404, detail=f"Lỗi dữ liệu nhóm ID: {group_id}")
        
        return sender_id, group_id, group
    except KeyError: raise HTTPException(status_code=500, detail="Lỗi cấu trúc dữ liệu.")
    except Exception as e: raise e

def _validate_user_profile_completeness(user: Profiles):
    if not user.preferred_city or not user.travel_dates:
        raise HTTPException(
            status_code=400, 
            detail="Bạn chưa cập nhật đầy đủ hồ sơ (City, Dates) để tham gia nhóm."
        )

# ====================================================================
# 2. LOGIC TẠO NHÓM
# ====================================================================
async def create_group_service_v2(session: Session, group_data: CreateGroupInput, current_user: Any) -> TravelGroup:
    owner_uuid = str(current_user.id)
    owner = session.exec(select(Profiles).where(Profiles.auth_user_id == owner_uuid)).first()
    
    if not owner: raise HTTPException(status_code=404, detail="Profile không tồn tại")
    
    _validate_user_profile_completeness(owner)
    if owner.owned_groups: raise HTTPException(status_code=400, detail="Bạn đã là Host.")
    if owner.joined_groups: raise HTTPException(status_code=400, detail="Bạn đã là Member.")

    try:
        _cancel_all_pending_requests(session, owner)
        
        group = TravelGroup(
            name=group_data.name,
            owner_id=owner_uuid, 
            max_members=group_data.max_members,
            preferred_city=owner.preferred_city, 
            travel_dates=owner.travel_dates,     
            interests=owner.interests or [], 
            itinerary=owner.itinerary,           
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

# ====================================================================
# 3. LOGIC XIN VÀO
# ====================================================================
async def request_join_group_v2(session: Session, group_id: int, current_user: Any) -> Dict:
    user_uuid = str(current_user.id)
    user = session.exec(select(Profiles).where(Profiles.auth_user_id == user_uuid)).first()
    group = session.exec(select(TravelGroup).where(TravelGroup.id == group_id)).first()
    
    if not user or not group: raise HTTPException(status_code=404, detail="Không tìm thấy.")
    
    _validate_user_profile_completeness(user)

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

async def cancel_join_request_service(session: Session, group_id: int, current_user: Any) -> Dict:
    user_uuid = str(current_user.id)
    user = session.exec(select(Profiles).where(Profiles.auth_user_id == user_uuid)).first()
    group = session.exec(select(TravelGroup).where(TravelGroup.id == group_id)).first()

    if not user or not group: raise HTTPException(status_code=404, detail="Dữ liệu không tồn tại")

    try:
        g_reqs = list(group.pending_requests or [])
        new_g_reqs = [r for r in g_reqs if r.get("profile_uuid") != user_uuid]
        if len(new_g_reqs) == len(g_reqs): raise HTTPException(status_code=400, detail="Không có yêu cầu nào")
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

# ====================================================================
# 4. LOGIC DUYỆT
# ====================================================================
async def handle_group_request_v2(session: Session, target_uuid: str, action: str, current_user: Any) -> Dict:
    group = await _get_host_group_info(session, current_user)
    target_user = session.exec(select(Profiles).where(Profiles.auth_user_id == target_uuid)).first()
    if not target_user: raise HTTPException(status_code=404, detail="Không tìm thấy User")

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
            
            _cancel_all_pending_requests(session, target_user)
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

# ====================================================================
# 5. LOGIC HOST GIẢI TÁN
# ====================================================================
async def host_dissolve_group_service(session: Session, current_user: Any) -> Dict:
    group = await _get_host_group_info(session, current_user)
    host_profile = session.exec(select(Profiles).where(Profiles.auth_user_id == group.owner_id)).first()
    try:
        member_uuids = [m.get("profile_uuid") for m in (group.members or []) if m.get("profile_uuid") != group.owner_id]
        if member_uuids:
            members_db = session.exec(select(Profiles).where(Profiles.auth_user_id.in_(member_uuids))).all()
            for m in members_db:
                m.joined_groups = []
                session.add(m)
        pending_uuids = [r.get("profile_uuid") for r in (group.pending_requests or [])]
        if pending_uuids:
            pending_users_db = session.exec(select(Profiles).where(Profiles.auth_user_id.in_(pending_uuids))).all()
            for pu in pending_users_db:
                pu_reqs = list(pu.pending_requests or [])
                pu.pending_requests = [r for r in pu_reqs if r.get("group_id") != group.id]
                session.add(pu)
        host_profile.owned_groups = []
        session.add(host_profile)
        session.delete(group)
        session.commit()
        return {"message": "Đã giải tán nhóm thành công."}
    except Exception as e:
        session.rollback()
        raise HTTPException(status_code=500, detail=f"Lỗi: {e}")

async def leave_group_service(session: Session, current_user: Any) -> Dict:
    user_uuid = str(current_user.id)
    user = session.exec(select(Profiles).where(Profiles.auth_user_id == user_uuid)).first()
    if not user.joined_groups: raise HTTPException(status_code=400, detail="Bạn không trong nhóm nào")
    group_id = user.joined_groups[0]['group_id']
    group = session.get(TravelGroup, group_id)
    try:
        if group:
            current_members = list(group.members or [])
            new_members = [m for m in current_members if m.get("profile_uuid") != user_uuid]
            group.members = new_members
            group.status = "open"
            session.add(group)
        user.joined_groups = []
        session.add(user)
        session.commit()
        return {"message": "Đã rời nhóm."}
    except Exception as e:
        session.rollback()
        raise HTTPException(status_code=500, detail=f"Lỗi: {e}")

# ====================================================================
# 6. LOGIC GỢI Ý THÔNG MINH (GĐ 22 - DÙNG AI MỚI)
# ====================================================================

async def group_suggest_service_v2(session: Session, current_user: Any) -> List[SuggestionOutput]:
    """
    Gợi ý nhóm: 
    1. Lọc cứng (DB) theo City & Date.
    2. Chấm điểm mềm (AI) theo Itinerary.
    """
    user_uuid = str(current_user.id)
    user = session.exec(select(Profiles).where(Profiles.auth_user_id == user_uuid)).first()
    
    # 1. Kiểm tra điều kiện tiên quyết
    _validate_user_profile_completeness(user)

    # 2. LỌC CỨNG (Database Filter)
    # Bắt buộc: Cùng Thành Phố + Cùng Ngày (Overlap hoặc Exact tùy bạn chọn, ở đây dùng Exact '=')
    statement = select(TravelGroup).where(
        TravelGroup.status == "open",
        TravelGroup.preferred_city == user.preferred_city,
        text(f"travel_dates = '{user.travel_dates}'::daterange") 
    )
    candidates = session.exec(statement).all()
    
    if not candidates:
        raise HTTPException(
            status_code=404, 
            detail=f"Không có nhóm nào đi {user.preferred_city} đúng ngày này."
        )

    # 3. Chuẩn bị dữ liệu cho AI
    valid_candidates = []
    ai_input_list = []
    
    for group in candidates:
        # Loại trừ nhóm của chính mình hoặc đã xin
        if group.owner_id == user_uuid: continue 
        if any(r.get("profile_uuid") == user_uuid for r in (group.pending_requests or [])): continue
        
        valid_candidates.append(group)
        # Chỉ gửi ID và Itinerary cho AI để tiết kiệm
        ai_input_list.append({
            "id": group.id,
            "itinerary": group.itinerary
        })

    if not valid_candidates:
        raise HTTPException(status_code=404, detail="Không tìm thấy nhóm phù hợp (đã lọc trùng).")

    # 4. GỌI AI CHẤM ĐIỂM (Sử dụng hàm mới trong ai_service)
    # Nếu user không có itinerary, AI sẽ trả về điểm thấp hoặc 0, không sao cả.
    ai_scores_map = await ai_service.rank_groups_by_itinerary_ai(
        user_itinerary=user.itinerary,
        candidate_groups=ai_input_list
    )
    
    # 5. Tổng hợp kết quả
    results = []
    for group in valid_candidates:
        # Lấy điểm từ AI. Nếu AI lỗi hoặc không chấm, mặc định 0.
        score = ai_scores_map.get(group.id, 0.0)
        
        results.append(SuggestionOutput(
            group_id=group.id, 
            name=group.name, 
            score=score
        ))

    # 6. Sắp xếp (Điểm cao lên đầu)
    results.sort(key=lambda x: x.score, reverse=True)
    
    return results

# ====================================================================
# 7. CÁC HÀM GET KHÁC
# ====================================================================

async def get_public_group_plan(session: Session, group_id: int) -> GroupPlanOutput:
    group = session.get(TravelGroup, group_id)
    if not group: raise HTTPException(status_code=404, detail="Nhóm không tồn tại")
    
    # Fix lỗi data cũ: Nếu itinerary bị lỗi format, trả về rỗng
    try:
        return GroupPlanOutput.model_validate(group)
    except Exception:
        # Fallback an toàn
        return GroupPlanOutput(
            group_id=group.id,
            group_name=group.name,
            preferred_city=group.preferred_city,
            travel_dates=group.travel_dates,
            itinerary={} # Trả về rỗng nếu lỗi
        )

async def get_my_group_detail_service(session: Session, auth_uuid: str) -> GroupDetailPublic:
    profile = session.exec(select(Profiles).where(Profiles.auth_user_id == auth_uuid)).first()
    group_id = None
    if profile.joined_groups: group_id = profile.joined_groups[0]['group_id']
    elif profile.owned_groups: group_id = profile.owned_groups[0]['group_id']
    if not group_id: raise HTTPException(status_code=404, detail="Bạn chưa có nhóm")
    
    group = session.get(TravelGroup, group_id)
    enriched = _enrich_group_members(session, group)
    return GroupDetailPublic(
        id=group.id, name=group.name, status=group.status,
        member_count=len(group.members), max_members=group.max_members,
        members=enriched
    )

async def get_pending_requests_service(session: Session, current_user: Any) -> List[Dict]:
    group = await _get_host_group_info(session, current_user)
    return group.pending_requests or []

async def get_group_plan_service(session: Session, auth_uuid: str) -> GroupPlanOutput:
    """
    Lấy kế hoạch nhóm (Đã thêm Try-Except để fix lỗi 500 do data cũ)
    """
    sender_id, group_id, group_db_object = await get_user_group_info(session, auth_uuid)
    
    try:
        # Cố gắng validate dữ liệu theo khuôn mới
        plan_output = GroupPlanOutput.model_validate(group_db_object)
        return plan_output
    except Exception as e:
        print(f"LỖI DATA CŨ (Get Plan): {e}")
        # Nếu data cũ trong DB không khớp (ví dụ itinerary là List thay vì Dict)
        # Trả về một object "sạch" để không bị sập server
        return GroupPlanOutput(
            group_id=group_db_object.id,
            group_name=group_db_object.name,
            preferred_city=group_db_object.preferred_city,
            travel_dates=group_db_object.travel_dates,
            itinerary={} # Reset itinerary về rỗng để hiển thị được
        )