# group_service.py
from pydantic import EmailStr
from sqlmodel import Session, select, text
from db_tables import TravelGroup, Profiles 
# === SỬA ĐỔI (GĐ 15.2): Import model "Kế hoạch" mới ===
from group_models import CreateGroupInput, GroupExitInput, GroupPlanOutput
from typing import Any, List, Dict, Optional, Tuple 
from datetime import datetime, date 
from fastapi import HTTPException
import traceback

# ====================================================================
# HÀM CHUYỂN DATERANGE (Không thay đổi)
# ====================================================================
def list_to_daterange(date_list: Optional[List[str]]) -> Optional[Any]:
    # (Code GĐ 13 - không thay đổi)
    if not date_list or len(date_list) != 2:
        return None
    try:
        start = date.fromisoformat(date_list[0])
        end = date.fromisoformat(date_list[1])
        range_str = f"[{start},{end}]" 
        return text(f"'{range_str}'::daterange")
    except ValueError:
        return None

# ====================================================================
# HÀM HỖ TRỢ V2 (GĐ 12): Hủy Request Cũ (Không thay đổi)
# ====================================================================
def _cancel_all_pending_requests(session: Session, user: Profiles):
    # (Code GĐ 12 - không thay đổi)
    if not user.pending_requests:
        return 
    print(f"Đang hủy {len(user.pending_requests)} request cũ của User UUID: {user.auth_user_id}")
    group_ids = [req.get("group_id") for req in user.pending_requests if req.get("group_id")]
    if group_ids:
        groups_to_update = session.exec(select(TravelGroup).where(TravelGroup.id.in_(group_ids))).all()
        for group in groups_to_update:
            group.pending_requests = [
                req for req in group.pending_requests 
                if req.get("profile_uuid") != user.auth_user_id
            ]
            session.add(group)
    user.pending_requests = []
    session.add(user)

# ====================================================================
# HÀM HỖ TRỢ V3 (GĐ 13): Lấy Nhóm của Host (Không thay đổi)
# ====================================================================
async def _get_host_group_info(session: Session, current_user: Any) -> TravelGroup:
    # (Code GĐ 13 - không thay đổi)
    owner_uuid = str(current_user.id)
    owned_groups_list = session.exec(
        select(Profiles.owned_groups)
        .where(Profiles.auth_user_id == owner_uuid)
    ).first()
    if not owned_groups_list or len(owned_groups_list) == 0:
        raise HTTPException(status_code=403, detail="Bạn không phải là Host của nhóm nào")
    try:
        group_id = owned_groups_list[0]['group_id']
    except (KeyError, IndexError):
         raise HTTPException(status_code=500, detail="Lỗi dữ liệu: owned_groups không hợp lệ")
    group = session.get(TravelGroup, group_id)
    if not group:
         raise HTTPException(status_code=404, detail=f"Không tìm thấy nhóm (ID: {group_id}) mà bạn sở hữu")
    return group

# ====================================================================
# HÀM HỖ TRỢ V4 (GĐ 15): Lấy Group ID (Chung) (Không thay đổi)
# ====================================================================
async def get_user_group_info(session: Session, auth_uuid: str) -> tuple[str, int, TravelGroup]:
    """
    (Refactor GĐ 15)
    Hàm "thông minh": Lấy sender_id (UUID), ID Nhóm (INT), và Group Object.
    """
    
    profile = session.exec(
        select(Profiles.joined_groups, Profiles.owned_groups)
        .where(Profiles.auth_user_id == auth_uuid)
    ).first()

    if not profile:
        raise HTTPException(status_code=404, detail="Không tìm thấy profile của bạn")
    
    sender_id = auth_uuid 
    group_id = None 
    
    try:
        if profile.joined_groups and len(profile.joined_groups) > 0:
            group_id = profile.joined_groups[0]['group_id'] 
        elif profile.owned_groups and len(profile.owned_groups) > 0:
            group_id = profile.owned_groups[0]['group_id']
            
        if group_id is None:
            raise HTTPException(status_code=400, detail="Bạn chưa tham gia (hoặc sở hữu) bất kỳ nhóm nào.")
        
        group = session.get(TravelGroup, group_id)
        if not group:
             raise HTTPException(status_code=404, detail=f"Lỗi dữ liệu: Không tìm thấy nhóm ID: {group_id}")

        return sender_id, group_id, group

    except KeyError:
        raise HTTPException(status_code=500, detail="Lỗi cấu trúc dữ liệu: JSON của nhóm không hợp lệ.")
    except Exception as e:
        raise e

# ====================================================================
# LOGIC TẠO NHÓM (GĐ 12 - Không thay đổi)
# ====================================================================
async def create_group_service_v2(
    session: Session,
    group_data: CreateGroupInput,
    current_user: Any 
) -> TravelGroup:
    # (Code GĐ 12 - không thay đổi)
    owner_uuid = str(current_user.id)
    owner = session.exec(select(Profiles).where(Profiles.auth_user_id == owner_uuid)).first()
    if not owner:
        raise HTTPException(status_code=404, detail="Profile không tồn tại")
    if owner.owned_groups:
        raise HTTPException(status_code=400, detail="Bạn đã là Host. BẮT BUỘC Giải tán nhóm trước.")
    if owner.joined_groups:
        raise HTTPException(status_code=400, detail="Bạn đã là Member. BẮT BUỘC Rời nhóm trước.")
    if not owner.preferred_city or not owner.travel_dates:
        raise HTTPException(status_code=400, detail="Vui lòng hoàn thiện travel plan (city, dates) trước khi tạo nhóm")
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
    except Exception as e:
        session.rollback()
        raise HTTPException(status_code=500, detail=f"Lỗi máy chủ: {e}")

# ====================================================================
# LOGIC XIN VÀO NHÓM (GĐ 12 - Không thay đổi)
# ====================================================================
async def request_join_group_v2(
    session: Session,
    group_id: int,
    current_user: Any
) -> Dict:
    # (Code GĐ 12 - không thay đổi)
    user_uuid = str(current_user.id)
    user = session.exec(select(Profiles).where(Profiles.auth_user_id == user_uuid)).first()
    group = session.exec(select(TravelGroup).where(TravelGroup.id == group_id)).first()
    if not user or not group:
        raise HTTPException(status_code=404, detail="Không tìm thấy User hoặc Group")
    if group.status != "open":
        raise HTTPException(status_code=400, detail="Nhóm đã đóng hoặc đầy")
    if user.owned_groups:
        raise HTTPException(status_code=400, detail="Bạn đang là Host. BẮT BUỘC Giải tán nhóm trước.")
    if user.joined_groups:
        raise HTTPException(status_code=400, detail="Bạn đã ở trong nhóm này.")
    if any(m.get("profile_uuid") == user_uuid for m in group.members):
        raise HTTPException(status_code=400, detail="Bạn đã ở trong nhóm này")
    if any(r.get("profile_uuid") == user_uuid for r in group.pending_requests):
        raise HTTPException(status_code=400, detail="Bạn đã gửi yêu cầu rồi")
    try:
        group.pending_requests.append({
            "profile_uuid": user_uuid, 
            "email": user.email, 
            "fullname": user.fullname, 
            "requested_at": datetime.now() 
        })
        if not user.pending_requests:
            user.pending_requests = []
        user.pending_requests.append({
            "group_id": group.id,
            "group_name": group.name,
            "status": "pending"
        })
        session.add(group)
        session.add(user)
        session.commit() 
        return {"message": "Yêu cầu đã được gửi"}
    except Exception as e:
        session.rollback()
        raise HTTPException(status_code=500, detail=f"Lỗi máy chủ: {e}")

# ====================================================================
# LOGIC DUYỆT/KICK (GĐ 13 - Không thay đổi)
# ====================================================================
async def handle_group_request_v2(
    session: Session,
    target_uuid: str, 
    action: str,
    current_user: Any
) -> Dict:
    # (Code GĐ 13 - không thay đổi)
    group = await _get_host_group_info(session, current_user)
    target_user = session.exec(select(Profiles).where(Profiles.auth_user_id == target_uuid)).first()
    if not target_user:
        raise HTTPException(status_code=404, detail="Không tìm thấy User")
    try:
        if action == "accept":
            if len(group.members) >= group.max_members:
                raise HTTPException(status_code=400, detail="Nhóm đã đầy")
            if target_user.owned_groups or target_user.joined_groups:
                raise HTTPException(status_code=400, detail="User này đã ở trong một nhóm khác.")
            request_data = next((r for r in group.pending_requests if r.get("profile_uuid") == target_uuid), None)
            if not request_data:
                raise HTTPException(status_code=404, detail="Không tìm thấy yêu cầu tham gia của user này")
            _cancel_all_pending_requests(session, target_user)
            group.pending_requests = [r for r in group.pending_requests if r.get("profile_uuid") != target_uuid]
            group.members.append({"profile_uuid": target_uuid, "email": target_user.email, "role": "member"})
            target_user.joined_groups = [{"group_id": group.id, "name": group.name}]
        elif action == "reject":
            group.pending_requests = [r for r in group.pending_requests if r.get("profile_uuid") != target_uuid]
            target_user.pending_requests = [r for r in (target_user.pending_requests or []) if r.get("group_id") != group.id]
        elif action == "kick":
            if target_uuid == group.owner_id:
                raise HTTPException(status_code=400, detail="Host không thể tự kick chính mình.")
            group.members = [m for m in group.members if m.get("profile_uuid") != target_uuid]
            target_user.joined_groups = []
        if len(group.members) >= group.max_members:
            group.status = "closed"
        else:
            group.status = "open"
        session.add(group)
        session.add(target_user)
        session.commit()
        return {"message": f"Hành động '{action}' thành công"}
    except HTTPException as he:
        raise he
    except Exception as e:
        session.rollback()
        raise HTTPException(status_code=500, detail=f"Lỗi máy chủ: {e}")

# ====================================================================
# XEM DANH SÁCH CHỜ (GĐ 13 - Không thay đổi)
# ====================================================================
async def get_pending_requests_service(
    session: Session,
    current_user: Any
) -> List[Dict[str, Any]]:
    # (Code GĐ 13 - không thay đổi)
    group = await _get_host_group_info(session, current_user)
    return group.pending_requests or []

# ====================================================================
# GỢI Ý NHÓM (GĐ 12 - Không thay đổi)
# ====================================================================
async def group_suggest_service_v2(
    session: Session,
    current_user: Any
) -> List[Dict[str, Any]]:
    # (Code GĐ 12 - không thay đổi)
    user_uuid = str(current_user.id)
    user_profile = session.exec(select(Profiles).where(Profiles.auth_user_id == user_uuid)).first()
    if not user_profile:
        raise HTTPException(status_code=404, detail="Không tìm thấy profile")
    if not user_profile.preferred_city or not user_profile.interests or not user_profile.travel_dates:
        raise HTTPException(status_code=400, detail="Profile thiếu thông tin: city, interests, travel_dates")
    groups = session.exec(select(TravelGroup).where(TravelGroup.status == "open")).all()
    if not groups:
        return []
    suggestions = []
    for group in groups:
        if group.owner_id == user_profile.auth_user_id:
            continue
        if any(r.get("profile_uuid") == user_uuid for r in group.pending_requests):
            continue
        score = 0
        reason = []
        if group.preferred_city == user_profile.preferred_city:
            score += 30
            reason.append("Cùng thành phố")
        if group.travel_dates and user_profile.travel_dates:
            try:
                overlap_check = session.exec(select(text(f"'{group.travel_dates}'::daterange && '{user_profile.travel_dates}'::daterange"))).scalar()
                if overlap_check:
                    score += 40
                    reason.append("Trùng thời gian")
            except Exception as de:
                print(f"Lỗi Daterange overlap: {de}")
        common_interests = set(user_profile.interests or []).intersection(set(group.interests or []))
        if common_interests:
            points = min(len(common_interests) * 10, 30)
            score += points
            reason.append(f"{len(common_interests)} sở thích chung")
        if score >= 60:
            suggestions.append({"group_id": group.id, "name": group.name, "score": score, "reason": ", ".join(reason) if reason else "Phù hợp"})
    suggestions.sort(key=lambda x: x["score"], reverse=True)
    return suggestions

# ====================================================================
# LOGIC RỜI NHÓM (GĐ 14 - Không thay đổi)
# ====================================================================
async def leave_group_service(
    session: Session, 
    current_user: Any
) -> Dict:
    # (Code GĐ 14 - không thay đổi)
    user_uuid = str(current_user.id)
    user_profile = session.exec(select(Profiles).where(Profiles.auth_user_id == user_uuid)).first()
    if not user_profile:
        raise HTTPException(status_code=404, detail="Không tìm thấy profile")
    if not user_profile.joined_groups or len(user_profile.joined_groups) == 0:
        raise HTTPException(status_code=400, detail="Bạn không phải là thành viên của nhóm nào")
    try:
        group_id = user_profile.joined_groups[0]['group_id']
        group = session.get(TravelGroup, group_id)
        if group:
            group.members = [m for m in group.members if m.get("profile_uuid") != user_uuid]
            if len(group.members) == 1:
                group.status = "open"
            session.add(group)
        user_profile.joined_groups = []
        session.add(user_profile)
        session.commit()
        return {"message": "Bạn đã rời nhóm thành công."}
    except Exception as e:
        session.rollback()
        raise HTTPException(status_code=500, detail=f"Lỗi máy chủ: {e}")

# ====================================================================
# LOGIC HOST RỜI (GĐ 14 - Không thay đổi)
# ====================================================================
async def host_exit_service(
    session: Session, 
    data: GroupExitInput, 
    current_user: Any
) -> Dict:
    # (Code GĐ 14 - không thay đổi)
    group = await _get_host_group_info(session, current_user)
    current_host_profile = session.exec(select(Profiles).where(Profiles.auth_user_id == group.owner_id)).first()
    if not current_host_profile:
         raise HTTPException(status_code=404, detail="Không tìm thấy profile của Host")
    try:
        if data.action == "dissolve":
            member_uuids = [
                m.get("profile_uuid") for m in group.members 
                if m.get("profile_uuid") != group.owner_id
            ]
            if member_uuids:
                members_to_update = session.exec(
                    select(Profiles).where(Profiles.auth_user_id.in_(member_uuids))
                ).all()
                for member in members_to_update:
                    member.joined_groups = []
                    session.add(member)
            current_host_profile.owned_groups = []
            session.add(current_host_profile)
            session.delete(group)
            session.commit()
            return {"message": "Nhóm đã được giải tán vĩnh viễn."}
        elif data.action == "transfer":
            new_host_uuid = data.new_host_uuid
            if not new_host_uuid: 
                raise HTTPException(status_code=400, detail="new_host_uuid là bắt buộc")
            if new_host_uuid == group.owner_id:
                raise HTTPException(status_code=400, detail="Bạn không thể nhường quyền cho chính mình")
            new_host_member_data = next((m for m in group.members if m.get("profile_uuid") == new_host_uuid), None)
            if not new_host_member_data:
                raise HTTPException(status_code=404, detail="Người này không phải là thành viên của nhóm")
            new_host_profile = session.exec(select(Profiles).where(Profiles.auth_user_id == new_host_uuid)).first()
            if not new_host_profile:
                raise HTTPException(status_code=404, detail="Không tìm thấy profile của Host mới")
            group.owner_id = new_host_uuid 
            new_members_list = []
            for m in group.members:
                if m.get("profile_uuid") == current_host_profile.auth_user_id:
                    continue 
                if m.get("profile_uuid") == new_host_uuid:
                    m['role'] = 'owner' 
                new_members_list.append(m)
            group.members = new_members_list
            current_host_profile.owned_groups = []
            new_host_profile.joined_groups = [] 
            new_host_profile.owned_groups = [{"group_id": group.id, "name": group.name}]
            session.add(group)
            session.add(current_host_profile)
            session.add(new_host_profile)
            session.commit()
            return {"message": f"Đã nhường quyền Host cho {new_host_profile.email}"}
    except HTTPException as he:
        raise he
    except Exception as e:
        session.rollback()
        raise HTTPException(status_code=500, detail=f"Lỗi máy chủ: {e}")

# ====================================================================
# SỬA ĐỔI (GĐ 15.2): LOGIC LẤY LỊCH TRÌNH NHÓM
# ====================================================================
async def get_group_plan_service(
    session: Session, 
    auth_uuid: str
) -> GroupPlanOutput: # <-- Trả về model GĐ 15.2
    """
    (Mới GĐ 15) Lấy Kế hoạch (Plan) của nhóm hiện tại.
    """
    # 1. Dùng hàm hỗ trợ V4 để tìm nhóm (đã check quyền)
    sender_id, group_id, group_db_object = await get_user_group_info(session, auth_uuid)
    
    # 2. Chuyển đổi sang Pydantic model 'GroupPlanOutput'
    plan_output = GroupPlanOutput.model_validate(group_db_object)
    
    return plan_output