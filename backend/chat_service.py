from fastapi import HTTPException
from sqlmodel import Session, select
from typing import List, Any
import traceback

# === SỬA LỖI (GĐ 11.3): Đổi 'TravelGroups' -> 'TravelGroup' ===
from db_tables import TravelGroup, GroupMessages, Profiles
# =======================================================
from chat_models import MessageCreate, MessagePublic

# ====================================================================
# HÀM HỖ TRỢ (GĐ 9.8): Lấy Group ID (Đã sửa logic trả về UUID)
# ====================================================================

async def get_user_group_info(session: Session, auth_uuid: str) -> tuple[str, int]:
    """
    (Nâng cấp GĐ 9.8)
    Hàm "thông minh": Lấy sender_id (là UUID) và ID Nhóm (là INT).
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
        
        # 2. Nếu không, kiểm tra 'host'
        elif profile.owned_groups and len(profile.owned_groups) > 0:
            group_id = profile.owned_groups[0]['group_id']
            
        if group_id is None:
            raise HTTPException(status_code=400, detail="Bạn chưa tham gia (hoặc sở hữu) bất kỳ nhóm nào.")
        
        return sender_id, group_id

    except KeyError:
        raise HTTPException(status_code=500, detail="Lỗi cấu trúc dữ liệu: JSON của nhóm không hợp lệ.")
    except Exception as e:
        raise e

# ====================================================================
# LOGIC (GĐ 9.8) Logic lấy lịch sử chat
# ====================================================================

async def get_messages_service_auto(
    session: Session, 
    auth_uuid: str
) -> List[MessagePublic]:
    """
    (Logic GĐ 9.4)
    Tự động lấy lịch sử chat (mặc định 30 tin mới nhất)
    """
    sender_id, group_id = await get_user_group_info(session, auth_uuid)
    
    page = 1
    limit = 30
    print(f"Đang lấy {limit} tin nhắn mới nhất cho Nhóm ID: {group_id}")
    
    offset = (page - 1) * limit

    try:
        statement = select(GroupMessages)\
            .where(GroupMessages.group_id == group_id)\
            .order_by(GroupMessages.created_at.desc())\
            .offset(offset)\
            .limit(limit)
            
        messages_db = session.exec(statement).all()
        
        messages_public = [MessagePublic.model_validate(msg) for msg in messages_db]
        messages_public.reverse()
        
        return messages_public

    except Exception as e:
        print(f"LỖI khi lấy tin nhắn: {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Lỗi máy chủ khi lấy tin nhắn: {e}")

# ====================================================================
# LOGIC (GĐ 9.8) Logic gửi tin nhắn
# ====================================================================

async def create_message_service_auto(
    session: Session, 
    auth_uuid: str, 
    message_data: MessageCreate
) -> MessagePublic:
    """
    (Logic GĐ 9.4)
    Tự động gửi/lưu một tin nhắn mới.
    """
    
    sender_id, group_id = await get_user_group_info(session, auth_uuid)
    
    print(f"Đang lưu tin nhắn (loại: {message_data.message_type}) cho Nhóm ID: {group_id}")
    
    try:
        new_message = GroupMessages(
            group_id=group_id,
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
        # === SỬA LỖI (GĐ 11.4): Thêm 'e' và '}' ===
        print(f"LỖI khi lưu tin nhắn: {e}")
        # =====================================
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Lỗi máy chủ khi lưu tin nhắn: {e}")