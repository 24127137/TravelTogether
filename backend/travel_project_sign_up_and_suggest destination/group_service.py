# group_service.py
from pydantic import EmailStr
from sqlmodel import Session, select
from models import TravelGroup, Profiles, CreateGroupInput
from typing import Any, List, Dict
from datetime import date

async def create_group_from_profile(
    session: Session,
    group_data: CreateGroupInput,
    current_user
) -> TravelGroup:
    owner_email = current_user.email
    owner = session.exec(select(Profiles).where(Profiles.email == owner_email)).first()
    if not owner:
        raise ValueError("Profile not found")

    # Kiểm tra owner đã có travel plan chưa
    if not owner.preferred_city or not owner.travel_dates or not owner.itinerary:
        raise ValueError("Vui lòng hoàn thiện travel plan trước khi tạo nhóm")

    # Tạo group từ profile
    group = TravelGroup(
        name=group_data.name,
        owner_id=owner.id,
        max_members=group_data.max_members,
        preferred_city=owner.preferred_city,
        travel_dates=owner.travel_dates,
        interests=owner.interests or [],
        members=[{"profile_id": owner.id, "email": owner.email, "role": "owner"}],
        pending_requests=[],
        created_at=date.today(),
        status="open"
    )
    session.add(group)
    session.commit()
    session.refresh(group)

    # Cập nhật profile: owned_groups = true, xóa pending_requests
    owner.owned_groups = [{"group_id": group.id, "name": group.name}]
    owner.pending_requests = []  # Xóa hết
    session.add(owner)
    session.commit()

    return group

async def request_join_group(
    session: Session,
    group_id: int,
    current_user
) -> Dict:
    user_email = current_user.email
    user = session.exec(select(Profiles).where(Profiles.email == user_email)).first()
    group = session.exec(select(TravelGroup).where(TravelGroup.id == group_id)).first()

    if not user or not group:
        raise ValueError("Not found")
    if group.status == "full":
        raise ValueError("Group is full")

    # Kiểm tra user đã join/own chưa
    if any(m["profile_id"] == user.id for m in group.members):
        raise ValueError("Already in group")
    if any(r["profile_id"] == user.id for r in group.pending_requests):
        raise ValueError("Already requested")

    # Giới hạn 3 pending requests
    pending_count = len([r for r in user.pending_requests or [] if r["status"] == "pending"])
    if pending_count >= 3:
        raise ValueError("Chỉ được gửi tối đa 3 yêu cầu")

    # Thêm vào group.pending_requests
    group.pending_requests.append({
        "profile_id": user.id,
        "email": user.email,
        "requested_at": date.today().isoformat()
    })

    # Thêm vào user.pending_requests
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

async def handle_group_request(
    session: Session,
    group_id: int,
    profile_id: int,
    action: str,  # accept, reject, kick
    current_user
) -> Dict:
    group = session.exec(select(TravelGroup).where(TravelGroup.id == group_id)).first()
    owner = session.exec(select(Profiles).where(Profiles.email == current_user.email)).first()
    target_user = session.exec(select(Profiles).where(Profiles.id == profile_id)).first()

    if not group or not owner or not target_user:
        raise ValueError("Not found")
    if group.owner_id != owner.id:
        raise ValueError("Only owner can manage")

    if action == "accept":
        # Kiểm tra capacity
        if len(group.members) >= group.max_members:
            raise ValueError("Group is full")

        # Xóa khỏi pending
        group.pending_requests = [r for r in group.pending_requests if r["profile_id"] != profile_id]
        group.members.append({"profile_id": profile_id, "email": target_user.email, "role": "member"})

        # Cập nhật target_user
        target_user.joined_groups = [{"group_id": group.id, "name": group.name}]
        target_user.pending_requests = []  # Xóa hết

        # Xóa profile_id khỏi tất cả pending_requests của các group khác
        all_groups = session.exec(select(TravelGroup)).all()
        for g in all_groups:
            g.pending_requests = [r for r in g.pending_requests if r["profile_id"] != profile_id]
            session.add(g)

    elif action == "reject":
        group.pending_requests = [r for r in group.pending_requests if r["profile_id"] != profile_id]
        target_user.pending_requests = [r for r in (target_user.pending_requests or []) if r["group_id"] != group_id]

    elif action == "kick":
        group.members = [m for m in group.members if m["profile_id"] != profile_id]
        target_user.joined_groups = []

    # Cập nhật status
    if len(group.members) >= group.max_members:
        group.status = "full"
    elif len(group.members) == 1:
        group.status = "open"

    session.add(group)
    session.add(target_user)
    session.commit()

    return {"message": f"Đã {action}"}

# ====================================================================
# GỢI Ý NHÓM THEO EMAIL (GĐ 5.5)
# ====================================================================
from typing import List, Dict
from sqlmodel import select
from fastapi import HTTPException

async def group_suggest_by_email_service(
    session: Session,
    email: EmailStr
) -> List[Dict[str, Any]]:
    """
    Gợi ý nhóm cho user dựa trên:
    - preferred_city
    - travel_dates (trùng ít nhất 1 ngày)
    - interests (trùng ≥ 2)
    → Tính điểm → sắp xếp giảm dần
    """
    print(f"Đang gợi ý nhóm cho email: {email}")

    # 1. Lấy profile của user
    user_profile = session.exec(
        select(Profiles).where(Profiles.email == email)
    ).first()
    if not user_profile:
        raise HTTPException(status_code=404, detail="Không tìm thấy profile")

    user_city = user_profile.preferred_city
    user_interests = set(user_profile.interests or [])
    user_dates = user_profile.travel_dates  # DATERANGE

    if not user_city or not user_interests or not user_dates:
        raise HTTPException(status_code=400, detail="Profile thiếu thông tin: city, interests, travel_dates")

    # 2. Lấy tất cả nhóm mở (status = 'open')
    groups = session.exec(
        select(TravelGroup).where(TravelGroup.status == "open")
    ).all()

    if not groups:
        return []

    suggestions = []

    for group in groups:
        if group.owner_id == user_profile.id:
            continue

        score = 0
        reason = []

        # +30 điểm nếu cùng thành phố
        if group.preferred_city == user_city:
            score += 30
            reason.append("Cùng thành phố")

        # +40 điểm nếu trùng thời gian (có ít nhất 1 ngày chung)
        if group.travel_dates and user_dates:
            overlap = group.travel_dates.overlaps(user_dates)
            if overlap:
                score += 40
                reason.append("Trùng thời gian")

        # +10 điểm cho mỗi sở thích chung (tối đa 30)
        common_interests = user_interests.intersection(set(group.interests or []))
        if common_interests:
            points = min(len(common_interests) * 10, 30)
            score += points
            reason.append(f"{len(common_interests)} sở thích chung")

        # Chỉ gợi ý nếu score ≥ 60
        if score >= 60:
            suggestions.append({
                "group_id": group.id,
                "name": group.name,
                "score": score,
                "reason": ", ".join(reason) if reason else "Phù hợp"
            })

    # 3. Sắp xếp giảm dần theo score
    suggestions.sort(key=lambda x: x["score"], reverse=True)

    print(f"Gợi ý {len(suggestions)} nhóm cho {email}")
    return suggestions