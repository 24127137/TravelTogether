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
# API HTTP (Giữ nguyên để lấy lịch sử)
# ====================================================================
@router.get("/history", response_model=List[MessagePublic])
async def get_my_chat_history_auto(
    session: Session = Depends(get_session),
    user_object: Any = Depends(get_current_user)
):
    try:
        auth_uuid = str(user_object.id)
        messages = await chat_service.get_messages_service_auto(
            session=session,
            auth_uuid=auth_uuid
        )
        return messages
    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Lỗi: {e}")

# ====================================================================
# API WEBSOCKET (MỚI - QUAN TRỌNG)
# ====================================================================
@router.websocket("/ws")
async def websocket_chat_endpoint(
    websocket: WebSocket,
    token: str = Query(...) # Nhận token qua URL: ws://.../chat/ws?token=...
):
    """
    Endpoint WebSocket để chat Real-time.
    Quy trình:
    1. Xác thực Token.
    2. Tìm Group ID của User.
    3. Kết nối vào Manager.
    4. Vòng lặp: Nhận tin -> Lưu DB -> Broadcast cho cả nhóm.
    """
    
    # 1. XÁC THỰC TOKEN (Thủ công vì WS không dùng Header 'Authorization')
    user = None
    try:
        if not sb_client:
            await websocket.close(code=1008) # Policy Violation
            return
            
        user_response = sb_client.auth.get_user(token)
        user = user_response.user
        if not user:
            print("WS: Token không hợp lệ")
            await websocket.close(code=1008)
            return
    except Exception as e:
        print(f"WS Auth Error: {e}")
        await websocket.close(code=1008)
        return

    auth_uuid = str(user.id)
    
    # 2. TÌM GROUP ID (Cần Session DB)
    group_id = None
    sender_id = auth_uuid
    
    # Mở Session thủ công (vì WebSocket là async loop dài)
    with Session(engine) as session:
        try:
            # Tái sử dụng hàm logic tìm nhóm
            # Lưu ý: Hàm get_user_group_info là async, nhưng trong context này
            # ta có thể query trực tiếp hoặc wrapper lại. 
            # Để đơn giản và an toàn, ta query lại logic tìm nhóm ở đây:
            from db_tables import Profiles
            profile = session.exec(
                select(Profiles).where(Profiles.auth_user_id == auth_uuid)
            ).first()
            
            if profile:
                if profile.joined_groups:
                    group_id = profile.joined_groups[0]['group_id']
                elif profile.owned_groups:
                    group_id = profile.owned_groups[0]['group_id']
        except Exception as e:
            print(f"WS Group Error: {e}")
            await websocket.close(code=1000)
            return

    if not group_id:
        print(f"User {auth_uuid} chưa có nhóm.")
        await websocket.close(code=1000) # Normal Closure
        return

    # 3. KẾT NỐI VÀO MANAGER
    await manager.connect(websocket, group_id)

    try:
        # 4. VÒNG LẶP NHẬN TIN NHẮN
        while True:
            # Chờ nhận data từ Client (Frontend gửi lên)
            # Client gửi JSON: { "message_type": "text", "content": "Alo 123", "image_url": null }
            data = await websocket.receive_json()
            
            print(f"WS nhận tin từ {auth_uuid}: {data}")

            # Mở session mới để lưu tin nhắn vào DB
            with Session(engine) as session:
                try:
                    # Validate dữ liệu đầu vào bằng Pydantic Model
                    msg_input = MessageCreate(**data)
                    
                    # Gọi Service để lưu vào DB (Tái sử dụng logic cũ)
                    # Lưu ý: Service cũ là async, ta gọi await
                    saved_msg = await chat_service.create_message_service_auto(
                        session=session,
                        auth_uuid=auth_uuid,
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
        print(f"User {auth_uuid} đã ngắt kết nối.")
    except Exception as e:
        print(f"WS Loop Error: {e}")
        manager.disconnect(websocket, group_id)