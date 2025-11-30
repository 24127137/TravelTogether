from fastapi import APIRouter, HTTPException, Depends, WebSocket, WebSocketDisconnect, Query
from typing import List, Any
from sqlmodel import Session, select
import traceback
import json

# Import Models và Services
from chat_models import MessageCreate, MessagePublic
import chat_service
from socket_manager import manager 

# Import Hỗ trợ
from database import get_session, engine 
from auth_guard import get_current_user
from config import settings
from supabase import create_client, Client
from db_tables import Profiles # Cần import để query

# Khởi tạo Supabase Client
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
# API WEBSOCKET (ĐÃ TỐI ƯU HÓA SESSION)
# ====================================================================
@router.websocket("/ws")
async def websocket_chat_endpoint(
    websocket: WebSocket,
    token: str = Query(...) 
):
    """
    Endpoint Chat Real-time Tối ưu hóa tốc độ.
    Cải tiến: Chỉ mở Session DB 1 lần duy nhất cho toàn bộ cuộc hội thoại.
    """
    
    # 1. XÁC THỰC TOKEN
    user = None
    try:
        if not sb_client:
            await websocket.close(code=1008) 
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
    
    # === TỐI ƯU: MỞ SESSION DUY NHẤT Ở ĐÂY ===
    # Session này sẽ sống cùng với vòng đời của WebSocket
    with Session(engine) as session:
        
        # 2. TÌM GROUP ID (Sử dụng ngay session vừa tạo)
        group_id = None
        try:
            profile = session.exec(
                select(Profiles).where(Profiles.auth_user_id == auth_uuid)
            ).first()
            
            if profile:
                if profile.joined_groups:
                    group_id = profile.joined_groups[0]['group_id']
                elif profile.owned_groups:
                    group_id = profile.owned_groups[0]['group_id']
            
            if not group_id:
                print(f"User {auth_uuid} chưa có nhóm.")
                await websocket.close(code=1000) 
                return

        except Exception as e:
            print(f"WS Group Error: {e}")
            await websocket.close(code=1000)
            return

        # 3. KẾT NỐI VÀO MANAGER
        await manager.connect(websocket, group_id)

        try:
            # 4. VÒNG LẶP NHẬN TIN NHẮN
            while True:
                # Chờ nhận data từ Client
                data = await websocket.receive_json()
                
                # Tại đây không cần mở session mới nữa -> Tốc độ xử lý tăng vọt
                try:
                    # Validate dữ liệu
                    msg_input = MessageCreate(**data)
                    
                    # Gọi Service (Truyền session đang mở vào)
                    saved_msg = await chat_service.create_message_service_auto(
                        session=session, # <--- Tái sử dụng session
                        auth_uuid=auth_uuid,
                        message_data=msg_input
                    )
                    
                    # Broadcast ngay lập tức
                    msg_json = saved_msg.model_dump()
                    if msg_json.get("created_at"):
                        msg_json["created_at"] = str(msg_json["created_at"])
                    
                    await manager.broadcast(msg_json, group_id)
                    
                except Exception as inner_e:
                    # Quan trọng: Nếu lỗi DB, phải rollback để session không bị kẹt
                    print(f"Lỗi xử lý tin nhắn: {inner_e}")
                    session.rollback() 
                    # Gửi báo lỗi về cho riêng client này
                    await websocket.send_json({"error": "Không thể gửi tin nhắn, vui lòng thử lại."})
                    
        except WebSocketDisconnect:
            manager.disconnect(websocket, group_id)
            print(f"User {auth_uuid} đã ngắt kết nối.")
        except Exception as e:
            print(f"WS Loop Error: {e}")
            manager.disconnect(websocket, group_id)