from sqlmodel import Session, select, text
from db_tables import TravelGroup, Profiles
from datetime import datetime, date
from typing import List, Optional, Any, Dict, Tuple
from fastapi import HTTPException
from group_models import GroupMemberPublic

# --- CÁC HÀM HỖ TRỢ LOGIC ---

def list_to_daterange(date_list: Optional[List[str]]) -> Optional[Any]:
    if not date_list or len(date_list) != 2: return None
    try:
        start = date.fromisoformat(date_list[0])
        end = date.fromisoformat(date_list[1])
        range_str = f"[{start},{end}]" 
        return text(f"'{range_str}'::daterange")
    except ValueError: return None

def is_group_expired(group: TravelGroup) -> bool:
    if not group.travel_dates: return False
    try:
        # Xử lý an toàn nếu travel_dates là string
        if isinstance(group.travel_dates, str):
            _, end_date = _extract_dates(group.travel_dates)
        else:
            end_date = group.travel_dates.upper
            
        if not end_date: return False
        return end_date < date.today()
    except Exception: return False

def enrich_group_members(session: Session, group: TravelGroup) -> List[GroupMemberPublic]:
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

def validate_user_profile_completeness(user: Profiles):
    if not user.preferred_city or not user.travel_dates:
        raise HTTPException(400, "Vui lòng cập nhật City và Dates trong hồ sơ trước khi tham gia nhóm.")

# === [HELPER QUAN TRỌNG] Xử lý trích xuất ngày từ String hoặc Object ===
def _extract_dates(date_range_obj: Any) -> Tuple[Optional[date], Optional[date]]:
    """
    Hàm thông minh: Tự động nhận diện đầu vào là String (từ Frontend) 
    hay Daterange Object (từ DB) để lấy ra ngày bắt đầu và kết thúc.
    """
    if not date_range_obj:
        return None, None

    # Trường hợp 1: Là String (Frontend gửi lên: '[2025-12-10,2025-12-18)')
    if isinstance(date_range_obj, str):
        try:
            # Loại bỏ các ký tự bao quanh: [, ], (, )
            clean_str = date_range_obj.strip("[]()")
            parts = clean_str.split(",")
            if len(parts) == 2:
                start = datetime.strptime(parts[0].strip(), "%Y-%m-%d").date() if parts[0].strip() else None
                end = datetime.strptime(parts[1].strip(), "%Y-%m-%d").date() if parts[1].strip() else None
                return start, end
        except Exception as e:
            print(f"Lỗi parse date string: {e}")
            return None, None

    # Trường hợp 2: Là Object từ Database (psycopg2 DateRange)
    try:
        return date_range_obj.lower, date_range_obj.upper
    except AttributeError:
        return None, None

def check_date_overlap(range_a: Any, range_b: Any) -> bool:
    """
    Kiểm tra 2 khoảng thời gian có trùng nhau không.
    Đã fix lỗi String vs Date object.
    Logic: (StartA <= EndB) AND (StartB <= EndA)
    """
    # Dùng hàm helper để chuẩn hóa dữ liệu về date object
    start_a, end_a = _extract_dates(range_a)
    start_b, end_b = _extract_dates(range_b)
    
    if start_a and end_a and start_b and end_b:
        return start_a <= end_b and start_b <= end_a
    return False

async def get_group_by_id_and_check_membership(session: Session, auth_uuid: str, group_id: int) -> TravelGroup:
    """Helper: Lấy group và check xem user có phải member/host không"""
    profile = session.exec(select(Profiles).where(Profiles.auth_user_id == auth_uuid)).first()
    if not profile: raise HTTPException(404, "Profile not found")

    is_host = any(g.get('group_id') == group_id for g in profile.owned_groups or [])
    is_member = any(g.get('group_id') == group_id for g in profile.joined_groups or [])
    
    if not (is_host or is_member):
        raise HTTPException(403, "Bạn không thuộc nhóm này.")
        
    group = session.get(TravelGroup, group_id)
    if not group: raise HTTPException(404, "Nhóm không tồn tại")
    return group