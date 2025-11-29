from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import List, Optional
from sqlmodel import Session
import logging

# Import Service
from chat_ai_service import ChatService
from database import get_session  # Adjust import based on your DB setup

# -----------------------
# Pydantic Models (Schemas)
# -----------------------

class SendMessageRequest(BaseModel):
    message: str

class MessageResponse(BaseModel):
    id: int
    role: str  # "user" or "model"
    content: str
    message_type: str
    image_url: Optional[str] = None
    created_at: Optional[str] = None

class SendMessageResponse(BaseModel):
    response: str
    message_id: int

class ChatHistoryResponse(BaseModel):
    user_id: str
    messages: List[MessageResponse]

# -----------------------
# Router Configuration
# -----------------------

router = APIRouter(
    prefix="/ai",
    tags=["AI Chat (Gemini)"]
)

def get_chat_service(db: Session = Depends(get_session)) -> ChatService:
    """Dependency injection untuk ChatService"""
    return ChatService(db)

@router.post("/new_session", response_model=NewSessionResponse)
async def create_ai_session(payload: NewSessionRequest):
    """
    ✅ FIXED: Tạo session chat AI mới HOẶC restore session cũ theo user_id.
    - Nếu user_id đã có session → trả về session cũ
    - Nếu chưa có → tạo mới
    """
    try:
        result = chat_service.create_or_restore_session(user_id=payload.user_id)
        return NewSessionResponse(
            session_id=result["session_id"],
            is_restored=result["is_restored"]
        )
    except Exception as e:
        logging.error(f"Lỗi tạo session: {e}")
        raise HTTPException(status_code=500, detail="Lỗi server khi tạo session")

@router.post("/send", response_model=SendMessageResponse)
async def send_message(
    payload: SendMessageRequest,
    user_id: str,
    service: ChatService = Depends(get_chat_service)
):
    """
    ✅ Gửi tin nhắn đến Gemini.
    - Tự động lưu tin nhắn user và AI vào DB
    - Trả về phản hồi từ AI
    """
    try:
        response_text = await service.process_user_message(
            user_id=user_id,
            message=payload.message
        )
        
        # Lấy message_id vừa lưu
        messages = service._get_user_messages(user_id, limit=1)
        message_id = messages[-1].id if messages else None
        
        return SendMessageResponse(
            response=response_text,
            message_id=message_id
        )
    
    except TimeoutError:
        raise HTTPException(status_code=504, detail="AI phản hồi quá lâu, vui lòng thử lại.")
    except Exception as e:
        logging.exception("Error at send_message endpoint")
        raise HTTPException(status_code=500, detail=f"Lỗi nội bộ: {str(e)}")

@router.get("/history/{session_id}", response_model=GetHistoryResponse)
async def get_chat_history(session_id: str):
    """
    Lấy lịch sử chat của một session.
    """
    try:
        history = chat_service._get_history_from_db(session_id)
        if history is None:
            raise HTTPException(status_code=404, detail="Session không tồn tại")
        return GetHistoryResponse(session_id=session_id, history=history)
    except Exception as e:
        logging.error(f"Lỗi lấy history: {e}")
        raise HTTPException(status_code=500, detail="Lỗi server khi lấy lịch sử")

@router.get("/chat-history", response_model=ChatHistoryResponse)
async def get_chat_history(
    user_id: str,
    limit: int = 50,
    service: ChatService = Depends(get_chat_service)
):
    """
    Lấy lịch sử chat của user (tất cả tin nhắn).
    """
    try:
        history = service.get_chat_history(user_id, limit=limit)
        return ChatHistoryResponse(
            user_id=user_id,
            messages=[MessageResponse(**msg) for msg in history]
        )
    except Exception as e:
        logging.error(f"Error getting chat history: {e}")
        raise HTTPException(status_code=500, detail="Lỗi server khi lấy lịch sử")

@router.get("/sessions/{user_id}", response_model=UserSessionsResponse)
async def get_user_sessions(user_id: str):
    """
    Lấy tất cả sessions của một user.
    """
    try:
        sessions = chat_service._get_all_sessions_by_user(user_id)
        return UserSessionsResponse(sessions=sessions)
    except Exception as e:
        logging.error(f"Lỗi lấy sessions: {e}")
        raise HTTPException(status_code=500, detail="Lỗi server khi lấy sessions")

@router.delete("/session/{session_id}")
async def delete_session(session_id: str):
    """
    Xóa một session.
    """
    try:
        chat_service._delete_session_from_db(session_id)
        return {"message": "Session đã bị xóa"}
    except Exception as e:
        logging.error(f"Lỗi xóa session: {e}")
        raise HTTPException(status_code=500, detail="Lỗi server khi xóa session")

@router.delete("/clear-chat")
async def clear_chat(
    user_id: str,
    service: ChatService = Depends(get_chat_service)
):
    """
    Xóa toàn bộ lịch sử chat của user.
    """
    try:
        service.delete_chat_history(user_id)
        return {"message": "Lịch sử chat đã được xóa"}
    except Exception as e:
        logging.error(f"Error clearing chat: {e}")
        raise HTTPException(status_code=500, detail="Lỗi server khi xóa lịch sử")
