from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import logging

# Import Service
from chat_ai_service import chat_service

# -----------------------
# Pydantic Models (Schemas)
# -----------------------
class NewSessionRequest(BaseModel):
    user_id: str 

class NewSessionResponse(BaseModel):
    session_id: str
    is_restored: bool  

class SendRequest(BaseModel):
    session_id: str
    message: str

class SendResponse(BaseModel):
    response: str

class GetHistoryResponse(BaseModel):
    session_id: str
    history: list

class UserSessionsResponse(BaseModel):
    sessions: list

# -----------------------
# Router Configuration
# -----------------------
router = APIRouter(
    prefix="/ai",
    tags=["GÄ 12 - AI Chat (Gemini)"]
)

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

@router.post("/send", response_model=SendResponse)
async def send_ai_message(payload: SendRequest):
    """
    Gửi message đến Gemini.
    """
    try:
        response_text = await chat_service.process_message(
            session_id=payload.session_id, 
            message=payload.message
        )
        return SendResponse(response=response_text)
    
    except ValueError as ve:
        raise HTTPException(status_code=404, detail=str(ve))
    
    except TimeoutError:
        raise HTTPException(status_code=504, detail="AI phản hồi quá lâu, vui lòng thử lại.")
    
    except Exception as e:
        logging.exception("Lỗi không xác định tại endpoint send_ai_message")
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