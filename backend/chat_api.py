from fastapi import APIRouter, HTTPException, Depends, WebSocket, WebSocketDisconnect, Query
from typing import List, Any
from sqlmodel import Session, select
import traceback
import json

# Import Models và Services
from chat_models import MessageCreate, MessagePublic
import chat_service
from socket_manager import manager # Import bộ quản lý socket mới

# Import Hỗ trợ
from database import get_session, engine # Import engine để tạo session thủ công trong WebSocket
from auth_guard import get_current_user
from config import settings
from supabase import create_client, Client

# Khởi tạo Supabase Client riêng cho WebSocket (vì WebSocket không dùng Dependency auth_guard dễ dàng)
try:
    sb_client: Client = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
except:
    sb_client = None

router = APIRouter(
    prefix="/chat", 
    tags=["GĐ 9 - Chat Realtime (WebSocket)"]
)

# ====================================================================
# API HTTP (Đã cập nhật: Lấy lịch sử theo Group ID)
# ====================================================================
@router.get("/{group_id}/history", response_model=List[MessagePublic])
async def get_chat_history_by_group( # Tên hàm mới rõ ràng hơn
    group_id: int, # <-- Thêm tham số group_id từ URL path
    session: Session = Depends(get_session),
    user_object: Any = Depends(get_current_user)
):
    """
    Lấy lịch sử chat của một Group ID cụ thể. Endpoint: GET /chat/{group_id}/history
    """
    try:
        auth_uuid = str(user_object.id)
        # SỬA ĐỔI: Gọi service mới có group_id và logic xác thực
        messages = await chat_service.get_messages_service_by_group(session, auth_uuid, group_id)
        return messages
    except HTTPException:
        raise
    except Exception as e:
        print(f"LỖI HTTP Get History: {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Lỗi máy chủ nội bộ: {e}")

# ====================================================================
# API WebSocket (Vẫn là endpoint chính cho chat realtime)
# ====================================================================
@router.websocket("/{group_id}")
async def websocket_endpoint(
    websocket: WebSocket,
    group_id: int # <-- Lấy group_id từ URL Path (Quan trọng)
):
    # 1. XÁC THỰC (Tái sử dụng logic cũ)
    token_str = websocket.headers.get("Authorization")
    if not token_str or not sb_client:
        await websocket.close(code=1008, reason="Unauthorized or Server Error")
        return

    try:
        real_token = token_str.split(" ")[1]
        user_response = sb_client.auth.get_user(real_token)
        auth_uuid = str(user_response.user.id)
    except Exception as e:
        print(f"Lỗi xác thực WS: {e}")
        await websocket.close(code=1008, reason="Authentication failed")
        return

    # 2. KẾT NỐI VÀ VÒNG LẶP
    session = None
    try:
        # 2a. CONNECT
        await manager.connect(websocket, group_id)

        # 2b. MESSAGE LOOP
        while True:
            data_str = await websocket.receive_text()
            
            # Mở một Session Database thủ công cho mỗi tin nhắn (Đảm bảo transaction)
            with Session(engine) as session:
                try:
                    # 3. PHÂN TÍCH VÀ LƯU VÀO DB
                    data = json.loads(data_str)
                    
                    # Validate với Pydantic Model
                    msg_input = MessageCreate(**data)
                    
                    # GỌI SERVICE MỚI VÀ TRUYỀN group_id
                    saved_msg = await chat_service.create_message_service_by_group( # <-- ĐÃ THAY ĐỔI
                        session=session,
                        auth_uuid=auth_uuid,
                        group_id=group_id, # <-- TRUYỀN group_id TƯỜNG MINH
                        message_data=msg_input
                    )
                    
                    # Convert sang Dict để gửi qua mạng
                    msg_json = saved_msg.model_dump()
                    # Convert datetime sang string (vì JSON không hiểu datetime)
                    if msg_json.get("created_at"):
                        msg_json["created_at"] = str(msg_json["created_at"])
                    
                    # 5. BROADCAST (GỬI CHO TẤT CẢ)
                    await manager.broadcast(msg_json, group_id)
                    
                except Exception as e:
                    print(f"Lỗi khi lưu/gửi tin nhắn: {e}")
                    # Gửi thông báo lỗi riêng cho người gửi (tùy chọn)
                    await websocket.send_json({"error": "Không thể gửi tin nhắn"})
                    
    except WebSocketDisconnect:
        manager.disconnect(websocket, group_id)
        print(f"User {auth_uuid} đã ngắt kết nối khỏi Group {group_id}.")
    except Exception as e:
        print(f"WS Loop Error: {e}")
        manager.disconnect(websocket, group_id)
        
    # Đóng session nếu còn mở
    if session:
        session.close()

# Gỡ bỏ endpoint HTTP cũ (get_my_chat_history_auto) nếu còn tồn tại