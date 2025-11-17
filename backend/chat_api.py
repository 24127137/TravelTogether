from fastapi import APIRouter, HTTPException, Depends, Query
from typing import List, Any
from sqlmodel import Session, select
import traceback

# Import Models và Services
from chat_models import MessageCreate, MessagePublic
import chat_service

# Import Hỗ trợ
from database import get_session
from auth_guard import get_current_user # "Người Bảo vệ"
# === SỬA ĐỔI (GĐ 9.8): Không cần import Bảng ở đây nữa ===
# from db_tables import Profiles, TravelGroups 

# ====================================================================
# API cho Tính năng Chat (Đã sửa GĐ 9.8)
# ====================================================================

router = APIRouter(
    prefix="/chat", 
    tags=["GĐ 9 - Chat (UUID)"]
)

@router.get("/history", response_model=List[MessagePublic])
async def get_my_chat_history_auto(
    session: Session = Depends(get_session),
    user_object: Any = Depends(get_current_user)
):
    """
    (API Nâng cấp GĐ 9.8)
    Lấy lịch sử chat (Mặc định 30 tin nhắn mới nhất).
    Tự động tìm Group ID từ Access Token (Dùng UUID).
    """
    try:
        auth_uuid = str(user_object.id)
        
        # === SỬA ĐỔI (GĐ 9.8): Không cần check quyền ở đây ===
        # (Vì service 'get_messages_service_auto' đã bao gồm
        # logic 'get_user_group_info' để tìm nhóm hợp lệ)
        
        messages = await chat_service.get_messages_service_auto(
            session=session,
            auth_uuid=auth_uuid
        )
        return messages
        
    except HTTPException as he:
        raise he
    except Exception as e:
        print(f"LỖI API LẤY TIN NHẮN: {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Lỗi máy chủ nội bộ: {e}")

@router.post("/send", response_model=MessagePublic)
async def send_new_message_auto(
    message_data: MessageCreate, 
    session: Session = Depends(get_session),
    user_object: Any = Depends(get_current_user) 
):
    """
    (API Nâng cấp GĐ 9.8)
    Gửi một tin nhắn mới (text hoặc image).
    Tự động tìm Group ID và Sender ID (UUID) từ Access Token.
    """
    try:
        auth_uuid = str(user_object.id)
        
        # === SỬA ĐỔI (GĐ 9.8): Không cần lấy sender_id ở đây ===
        # (Service 'create_message_service_auto' sẽ tự làm)
        
        new_message = await chat_service.create_message_service_auto(
            session=session,
            auth_uuid=auth_uuid,
            message_data=message_data
        )
        return new_message
        
    except HTTPException as he:
        raise he
    except Exception as e:
        print(f"LỖI API GỬI TIN NHẮN: {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Lỗi máy chủ nội bộ: {e}")