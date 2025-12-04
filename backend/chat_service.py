from fastapi import HTTPException
from sqlmodel import Session, select, func
from typing import List, Any
import traceback
import json

# === SỬA LỖI (GĐ 11.3): Đổi 'TravelGroups' -> 'TravelGroup' ===
from db_tables import TravelGroup, GroupMessages, Profiles
# =======================================================
from chat_models import MessageCreate, MessagePublic

# ====================================================================
# HÀM HỖ TRỢ: Kiểm tra tư cách thành viên nhóm
# ====================================================================
def _validate_group_membership(session: Session, auth_uuid: str, group_id: int) -> bool:
    """
    Kiểm tra xem user (auth_uuid) có phải là thành viên/chủ sở hữu của group_id hay không.
    Sử dụng JSONB column 'joined_groups' và 'owned_groups'.
    """
    try:
        profile = session.exec(
            select(Profiles.joined_groups, Profiles.owned_groups)
            .where(Profiles.auth_user_id == auth_uuid)
        ).first()

        if not profile:
            return False

        # 1. Kiểm tra trong joined_groups
        if profile.joined_groups:
            # Kiểm tra xem group_id có tồn tại trong danh sách nhóm đã tham gia không
            if any(group.get('group_id') == group_id for group in profile.joined_groups):
                return True
        
        # 2. Kiểm tra trong owned_groups
        if profile.owned_groups:
            # Kiểm tra xem group_id có tồn tại trong danh sách nhóm sở hữu không
            if any(group.get('group_id') == group_id for group in profile.owned_groups):
                return True

        return False

    except Exception as e:
        print(f"Lỗi kiểm tra tư cách thành viên: {e}")
        return False


# ====================================================================
# LOGIC MỚI: Lấy lịch sử tin nhắn theo Group ID (Cho API HTTP)
# ====================================================================

async def get_messages_service_by_group(session: Session, auth_uuid: str, group_id: int) -> List[MessagePublic]:
    """
    Lấy lịch sử chat của một nhóm, sau khi xác thực user là thành viên.
    """
    # 1. XÁC THỰC TƯ CÁCH THÀNH VIÊN
    is_member = _validate_group_membership(session, auth_uuid, group_id)
    if not is_member:
        raise HTTPException(status_code=403, detail="Bạn không phải là thành viên của nhóm này.")
        
    print(f"Đang lấy lịch sử tin nhắn cho Nhóm ID: {group_id} (User: {auth_uuid})")
    
    try:
        # 2. LẤY TIN NHẮN: Chỉ lấy tin nhắn của group_id này
        statement = select(GroupMessages).where(GroupMessages.group_id == group_id).order_by(GroupMessages.created_at)
        messages_db = session.exec(statement).all()
        
        # 3. CHUYỂN ĐỔI SANG MODEL PUBLIC
        messages_public = [MessagePublic.model_validate(msg) for msg in messages_db]
        return messages_public

    except Exception as e:
        print(f"Lỗi khi lấy lịch sử tin nhắn: {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail="Lỗi máy chủ khi truy vấn lịch sử chat.")


# ====================================================================
# LOGIC MỚI: Logic gửi tin nhắn (Cho API WebSocket)
# ====================================================================

async def create_message_service_by_group( # <-- ĐÃ THAY ĐỔI TÊN VÀ THÊM group_id
    session: Session, 
    auth_uuid: str, 
    group_id: int, # <-- THÊM THAM SỐ group_id (TRUYỀN TỪ WS)
    message_data: MessageCreate
) -> MessagePublic:
    """
    Lưu một tin nhắn mới vào database, sử dụng group_id được truyền vào và xác thực.
    """
    # 1. XÁC THỰC TƯ CÁCH THÀNH VIÊN
    is_member = _validate_group_membership(session, auth_uuid, group_id)
    if not is_member:
        raise HTTPException(status_code=403, detail="Bạn không được phép gửi tin nhắn vào nhóm này.")
    
    sender_id = auth_uuid 
    
    print(f"Đang lưu tin nhắn (loại: {message_data.message_type}) cho Nhóm ID: {group_id} (Sender: {sender_id})")
    
    try:
        new_message = GroupMessages(
            group_id=group_id, # <--- DÙNG group_id ĐƯỢC TRUYỀN VÀO
            sender_id=sender_id, # sender_id bây giờ là UUID
            message_type=message_data.message_type,
            content=message_data.content, 
            image_url=message_data.image_url 
        )
        
        session.add(new_message)
        session.commit()
        session.refresh(new_message)
        
        print(f"Lưu tin nhắn ID: {new_message.id} thành công.")
        
        return MessagePublic.model_validate(new_message)

    except HTTPException as he:
        raise he 
    except Exception as e:
        print(f"Lỗi khi lưu tin nhắn: {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail="Lỗi máy chủ khi lưu tin nhắn.")

# ====================================================================
# HÀM HỖ TRỢ CŨ (get_user_group_info) - Giữ lại để tránh phá vỡ các code cũ (nếu có)
# ====================================================================

async def get_user_group_info(session: Session, auth_uuid: str) -> tuple[str, int]:
    """
    Hàm cũ: Lấy sender_id (là UUID) và ID Nhóm (là INT) (Chỉ hoạt động khi user chỉ có 1 nhóm)
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
        # 1. Ưu tiên kiểm tra 'member'
        if profile.joined_groups and len(profile.joined_groups) > 0:
            group_id = profile.joined_groups[0]['group_id']
        # 2. Nếu không phải member, kiểm tra 'owner'
        elif profile.owned_groups and len(profile.owned_groups) > 0:
            group_id = profile.owned_groups[0]['group_id']
            
        if not group_id:
            raise HTTPException(status_code=400, detail="Bạn chưa tham gia nhóm nào")

        return sender_id, group_id

    except Exception as e:
        print(f"Lỗi khi lấy thông tin nhóm: {e}")
        raise HTTPException(status_code=500, detail="Lỗi máy chủ khi tìm thông tin nhóm.")