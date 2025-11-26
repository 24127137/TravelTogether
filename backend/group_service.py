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
import ai_service 

# ====================================================================
# 1. CÁC HÀM HỖ TRỢ (HELPERS) - QUAN TRỌNG
# ====================================================================

def list_to_daterange(date_list: Optional[List[str]]) -> Optional[Any]:
    """Chuyển đổi list ngày ['Y-M-D', 'Y-M-D'] sang PostgreSQL DATERANGE"""
    if not date_list or len(date_list) != 2: return None
    try:
        start = date.fromisoformat(date_list[0])
        end = date.fromisoformat(date_list[1])
        # Dùng 'inclusive' [] để PostgreSQL hiểu ngày kết thúc cũng được tính
        range_str = f"[{start},{end}]" 
        return text(f"'{range_str}'::daterange")
    except ValueError: return None

def _is_group_expired(group: TravelGroup) -> bool:
    """Kiểm tra xem nhóm đã quá hạn (đi xong) chưa"""
    if not group.travel_dates: return False
    try:
        # psycopg2 daterange.upper là ngày kết thúc
        end_date = group.travel_dates.upper
        if not end_date: return False
        today = date.today()
        # Nếu ngày kết thúc < hôm nay => Đã qua (Expired)
        return end_date < today
    except Exception: return False

def _cancel_all_pending_requests(session: Session, user: Profiles):
    """Hủy tất cả yêu cầu xin vào nhóm khác của User này"""
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
    
    # Xóa sạch danh sách chờ của user
    user.pending_requests = []
    session.add(user)

def _enrich_group_members(session: Session, group: TravelGroup) -> List[GroupMemberPublic]:
    """Lấy thông tin chi tiết (Avatar, Tên, Email) cho danh sách thành viên"""
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
    """Tìm nhóm mà user hiện tại đang làm Host"""
    owner_uuid = str(current_user.id)
    group = session.exec(select(TravelGroup).where(TravelGroup.owner_id == owner_uuid)).first()
    if not group: raise HTTPException(status_code=403, detail="Bạn không phải là Host của nhóm nào")
    return group

async def get_user_group_info(session: Session, auth_uuid: str) -> tuple[str, int, TravelGroup]:
    """Tìm nhóm của user (Dù là Host hay Member) - Dùng cho Chat & Plan"""
    profile = session.exec(
        select(Profiles.joined_groups, Profiles.owned_groups)
        .where(Profiles.auth_user_id == auth_uuid)
    ).first()
    
    if not profile: raise HTTPException(status_code=404, detail="Không tìm thấy profile")
    
    sender_id = auth_uuid 
    group_id = None 
    try:
        if profile.joined_groups and len(profile.joined_groups) > 0: 
            group_id = profile.joined_groups[0]['group_id'] 
        elif profile.owned_groups and len(profile.owned_groups) > 0: 
            group_id = profile.owned_groups[0]['group_id']
        
        if group_id is None: raise HTTPException(status_code=400, detail="Chưa tham gia nhóm nào.")
        
        group = session.get(TravelGroup, group_id)
        if not group: raise HTTPException(status_code=404, detail=f"Lỗi dữ liệu nhóm ID: {group_id}")
        
        return sender_id, group_id, group
    except KeyError: raise HTTPException(status_code=500, detail="Lỗi cấu trúc dữ liệu.")
    except Exception as e: raise e

def _validate_user_profile_completeness(user: Profiles):
    """Đảm bảo user có đủ thông tin trước khi tham gia/tạo nhóm"""
    if not user.preferred_city or not user.travel_dates:
        raise HTTPException(
            status_code=400, 
            detail="Bạn chưa cập nhật đầy đủ hồ sơ (City, Dates) để tham gia nhóm."
        )

# ====================================================================
# 2. LOGIC TẠO NHÓM (CREATE)
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
        
        # Auto-fill từ Host sang Group
        group = TravelGroup(
            name=group_data.name,
            owner_id=owner_uuid, 
            max_members=group_data.max_members,
            preferred_city=owner.preferred_city, # Auto-fill
            travel_dates=owner.travel_dates,     # Auto-fill
            interests=owner.interests or [], 
            itinerary=owner.itinerary,           # Auto-fill Itinerary
            # === CẬP NHẬT: Lưu URL ảnh bìa (nếu có trong input, nếu không thì null) ===
            # group_image_url=group_data.group_image_url, (Nếu model input có)
            # =================================
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
# 3. LOGIC XIN VÀO (REQUEST JOIN) & HỦY YÊU CẦU (CANCEL)
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

# ====================================================================
# 4. LOGIC QUẢN LÝ (MANAGE - ACCEPT/REJECT/KICK)
# ====================================================================
async def handle_group_request_v2(session: Session, target_uuid: str, action: str, current_user: Any) -> Dict:
    group = await _get_host_group_info(session, current_user)
    target_user = session.exec(select(Profiles).where(Profiles.auth_user_id == target_uuid)).first()
    if not target_user: raise HTTPException(status_code=404, detail="Không tìm thấy User mục tiêu")

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
# 5. LOGIC GIẢI TÁN & RỜI NHÓM (DISSOLVE / LEAVE)
# ====================================================================
async def host_dissolve_group_service(session: Session, current_user: Any) -> Dict:
    group = await _get_host_group_info(session, current_user)
    host_profile = session.exec(select(Profiles).where(Profiles.auth_user_id == group.owner_id)).first()
    
    try:
        # Dọn dẹp Members
        member_uuids = [m.get("profile_uuid") for m in (group.members or []) if m.get("profile_uuid") != group.owner_id]
        if member_uuids:
            members_db = session.exec(select(Profiles).where(Profiles.auth_user_id.in_(member_uuids))).all()
            for m in members_db:
                m.joined_groups = []
                session.add(m)
        
        # Dọn dẹp Pending Requests
        pending_uuids = [r.get("profile_uuid") for r in (group.pending_requests or [])]
        if pending_uuids:
            pending_users_db = session.exec(select(Profiles).where(Profiles.auth_user_id.in_(pending_uuids))).all()
            for pu in pending_users_db:
                pu_reqs = list(pu.pending_requests or [])
                pu.pending_requests = [r for r in pu_reqs if r.get("group_id") != group.id]
                session.add(pu)
        
        # Dọn dẹp Host
        host_profile.owned_groups = []
        session.add(host_profile)
        
        # === CHECK EXPIRED ===
        is_expired = _is_group_expired(group)
        
        if is_expired:
            group.status = "expired"
            session.add(group) # Giữ lại
            msg = "Nhóm đã kết thúc và được lưu vào lịch sử."
        else:
            session.delete(group) # Xóa vĩnh viễn
            msg = "Nhóm đã được giải tán và xóa vĩnh viễn."
        
        session.commit()
        return {"message": msg}
        
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
            is_expired = _is_group_expired(group)
            
            if is_expired:
                pass # Đã đi xong -> Giữ tên
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

# ====================================================================
# 6. LOGIC GỢI Ý THÔNG MINH (AI SUGGEST)
# ====================================================================

def _extract_locations_from_itinerary(itinerary_json: Optional[Dict[str, str]]) -> set[str]:
    if not itinerary_json: return set()
    clean_locations = set()
    # Duyệt qua VALUES của dict (tên địa điểm)
    for value in itinerary_json.values():
        raw_text = str(value).lower()
        # Tách dấu phẩy
        if "," in raw_text:
            parts = [p.strip() for p in raw_text.split(",")]
        else:
            parts = [raw_text.strip()]
            
        for part in parts:
            loc_clean = re.sub(r'[^\w\s]', '', part).strip()
            if loc_clean and len(loc_clean) > 1: 
                clean_locations.add(loc_clean)
    return clean_locations

async def group_suggest_service_v2(session: Session, current_user: Any) -> List[SuggestionOutput]:
    user_uuid = str(current_user.id)
    user = session.exec(select(Profiles).where(Profiles.auth_user_id == user_uuid)).first()
    
    _validate_user_profile_completeness(user)

    # LỌC CỨNG: Cùng City + Cùng Date
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

    valid_candidates = []
    ai_input_list = []
    
    for group in candidates:
        if group.owner_id == user_uuid: continue 
        if any(r.get("profile_uuid") == user_uuid for r in (group.pending_requests or [])): continue
        
        valid_candidates.append(group)
        ai_input_list.append({
            "id": group.id,
            "itinerary": group.itinerary
        })

    if not valid_candidates:
        raise HTTPException(status_code=404, detail="Không tìm thấy nhóm phù hợp (đã lọc trùng).")

    # GỌI AI CHẤM ĐIỂM
    ai_scores_map = await ai_service.rank_groups_by_itinerary_ai(
        user_itinerary=user.itinerary,
        candidate_groups=ai_input_list
    )
    
    results = []
    for group in valid_candidates:
        score = ai_scores_map.get(group.id, 0.0)
        
        results.append(SuggestionOutput(
            group_id=group.id, 
            name=group.name, 
            score=score,
            # Trả về URL ảnh (nếu có trong DB)
            group_image_url=getattr(group, "group_image_url", None) 
        ))

    results.sort(key=lambda x: x.score, reverse=True)
    return results

# ====================================================================
# 7. CÁC HÀM GET (VIEW)
# ====================================================================

async def get_public_group_plan(session: Session, group_id: int) -> GroupPlanOutput:
    group = session.get(TravelGroup, group_id)
    if not group: raise HTTPException(status_code=404, detail="Nhóm không tồn tại")
    return GroupPlanOutput(
        group_id=group.id, group_name=group.name, preferred_city=group.preferred_city,
        travel_dates=group.travel_dates, itinerary=group.itinerary,
        group_image_url=getattr(group, "group_image_url", None)
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
        members=enriched,
        group_image_url=getattr(group, "group_image_url", None)
    )

async def get_pending_requests_service(session: Session, current_user: Any) -> List[Dict]:
    group = await _get_host_group_info(session, current_user)
    return group.pending_requests or []

async def get_group_plan_service(session: Session, auth_uuid: str) -> GroupPlanOutput:
    sender_id, group_id, group_db_object = await get_user_group_info(session, auth_uuid)
    plan_output = GroupPlanOutput.model_validate(group_db_object)
    # Bổ sung URL ảnh thủ công nếu model_validate chưa map
    if hasattr(group_db_object, "group_image_url"):
         plan_output.group_image_url = group_db_object.group_image_url
    return plan_output