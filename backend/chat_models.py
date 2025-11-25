from pydantic import BaseModel, Field, field_validator, ValidationInfo
from typing import List, Optional, Any, Dict
from datetime import datetime

# ====================================================================
# Models cho TÍNH NĂNG CHAT (Message)
# ====================================================================

class MessageCreate(BaseModel):
    """
    Input: Dữ liệu JSON để GỬI một tin nhắn.
    (Đã cập nhật: Tự động chuẩn hóa message_type)
    """
    message_type: str # Input: "Text", "IMAGE"...
    content: Optional[str] = None
    image_url: Optional[str] = None

    # --- VALIDATOR: CHUẨN HÓA MESSAGE TYPE (FIX LỖI ENUM) ---
    @field_validator('message_type', mode='before')
    @classmethod
    def normalize_message_type(cls, v: Any):
        if isinstance(v, str):
            # Chuyển về chữ thường: "Text" -> "text"
            v_clean = v.strip().lower()
            if v_clean not in ('text', 'image'):
                raise ValueError("message_type phải là 'text' hoặc 'image'")
            return v_clean
        return v

    # --- VALIDATOR: CHECK CHÉO NỘI DUNG (Giữ nguyên) ---
    @field_validator('*', mode='before')
    @classmethod
    def check_content_vs_type(cls, v, info: ValidationInfo):
        values = info.data
        
        # Lưu ý: Lúc này 'message_type' có thể chưa chạy qua validator ở trên
        # nên ta truy cập an toàn
        if info.field_name == 'image_url':
            message_type_raw = values.get('message_type', '').lower()
            content = values.get('content')
            image_url = v 
            
            if message_type_raw == 'text' and not content:
                raise ValueError("Tin nhắn 'text' không được có nội dung rỗng.")
            if message_type_raw == 'image' and not image_url:
                raise ValueError("Tin nhắn 'image' phải có image_url.")
        return v 

    class Config:
        json_schema_extra = {
            "examples": [
                {"message_type": "Text", "content": "Chào mọi người!"},
                {"message_type": "IMAGE", "image_url": "https://..."}
            ]
        }

class MessagePublic(BaseModel):
    """
    Output: Dữ liệu JSON trả về khi LẤY lịch sử chat
    """
    id: int
    group_id: int
    sender_id: str 
    message_type: str
    content: Optional[str] = None
    image_url: Optional[str] = None
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True