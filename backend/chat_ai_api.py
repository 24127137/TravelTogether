from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Dict, List, Any
import os
import uuid
import asyncio
import logging

import google.generativeai as genai
from google.generativeai import GenerationConfig, GenerativeModel

from config import settings
# -----------------------
# Cấu hình an toàn cho API key (từ biến môi trường)
# -----------------------
genai.configure(api_key=settings.GEMINI_API_KEY)

# Tạo model instance sử dụng gemini-2.5-flash (như yêu cầu)
generation_config = GenerationConfig(
    response_mime_type="text/plain"
)

# Tên model theo yêu cầu
MODEL_NAME = "gemini-2.5-flash"

try:
    model = GenerativeModel(MODEL_NAME, generation_config=generation_config)
except Exception as e:
    # Ghi log và raise để dev biết cấu hình model có vấn đề
    logging.exception("Không thể khởi tạo model Gemini: %s", e)
    raise

# ====================================================================
# Storage (In-memory) và Helper Functions
# ====================================================================

# In-memory session store: session_id -> list of messages
chat_sessions: Dict[str, List[Dict[str, str]]] = {}

class NewSessionResponse(BaseModel):
    session_id: str

class SendRequest(BaseModel):
    session_id: str
    message: str

class SendResponse(BaseModel):
    response: str

# In-memory session store: session_id -> list of messages (each: {"role": "user"|"assistant", "text": "..."})
chat_sessions: Dict[str, List[Dict[str, str]]] = {}

# Helper: build prompt from history + incoming message
def build_prompt(history: List[Dict[str, str]], user_message: str) -> str:
    # Đơn giản: nối lịch sử theo thứ tự xuất hiện, mỗi message có role và text.
    pieces = []
    for msg in history:
        role = msg.get("role", "user")
        text = msg.get("text", "")
        pieces.append(f"{role.upper()}: {text}")
    pieces.append(f"USER: {user_message}")
    pieces.append("ASSISTANT:")
    # Bạn có thể tùy chỉnh hệ thống prompt / instruction ở đây
    system_instruction = (
        "Bạn là một trợ lý du lịch thân thiện, trả lời ngắn gọn, rõ ràng và lịch sự."
    )
    full_prompt = system_instruction + "\n\n" + "\n".join(pieces)
    return full_prompt

# Async helper to call Gemini model
async def call_gemini_async(prompt: str, timeout: float = 30.0) -> str:
    """
    Gọi model.generate_content_async và trả về text output.
    """
    try:
        # model.generate_content_async có thể là coroutine; gọi và chờ kết quả
        response = await model.generate_content_async(prompt)
        # response.text chứa plain text response (theo cấu hình response_mime_type)
        text = getattr(response, "text", None)
        if text is None:
            # Fall back: try str(response)
            text = str(response)
        return text
    except Exception as e:
        logging.exception("Lỗi khi gọi Gemini: %s", e)
        raise

# -----------------------
# Endpoints
# -----------------------
router = APIRouter(
    prefix="/ai",  # Đặt prefix là /ai để phân biệt hoàn toàn với /chat của Group
    tags=["GĐ 12 - AI Chat (Gemini)"]
)

@router.post("/new_session", response_model=NewSessionResponse)
async def create_ai_session():
    """
    Tạo session chat AI mới, trả về session_id. 
    (Endpoint này hoàn toàn khác biệt với API Group)
    """
    session_id = uuid.uuid4().hex
    chat_sessions[session_id] = []
    logging.info(f"Tạo session AI mới: {session_id}")
    return NewSessionResponse(session_id=session_id)

@router.post("/send", response_model=SendResponse)
async def send_ai_message(payload: SendRequest):
    """
    Gửi message đến Gemini (gemini-2.5-flash) theo session.
    Body: {"session_id": "...", "message": "..."}
    Trả về: {"response": "..."}
    """
    sid = payload.session_id
    message_text = payload.message

    if sid not in chat_sessions:
        raise HTTPException(status_code=404, detail="Session_id không tồn tại")

    # Lấy history và thêm message user
    history = chat_sessions[sid]
    history.append({"role": "user", "text": message_text})

    # Xây prompt từ lịch sử + message mới
    prompt = build_prompt(history, message_text)

    # Gọi model (async)
    try:
        ai_response_text = await asyncio.wait_for(call_gemini_async(prompt), timeout=30.0)
    except asyncio.TimeoutError:
        raise HTTPException(status_code=504, detail="Timeout khi gọi model Gemini")
    except Exception as e:
        logging.exception("Lỗi khi gọi model Gemini: %s", e)
        raise HTTPException(status_code=500, detail=f"Lỗi nội bộ khi gọi AI: {e}")

    # Lưu response vào history
    history.append({"role": "assistant", "text": ai_response_text})

    return SendResponse(response=ai_response_text)

