from pydantic import BaseModel, Field, field_validator, ValidationInfo
from typing import List, Optional, Any, Dict
from datetime import datetime

# ====================================================================
# Models cho TÍNH NĂNG CHAT (Message) (Đã sửa GĐ 9.8)
# ====================================================================

class MessageCreate(BaseModel):
    """
    Input: Dữ liệu JSON để GỬI một tin nhắn (text hoặc image)
    """
    message_type: str = Field(..., pattern="^(text|image)$") 
    content: Optional[str] = None
    image_url: Optional[str] = None

    @field_validator('*', mode='before')
    @classmethod
    def check_content_vs_type(cls, v, info: ValidationInfo):
        values = info.data
        if info.field_name == 'image_url':
            message_type = values.get('message_type')
            content = values.get('content')
            image_url = v 
            if message_type == 'text' and not content:
                raise ValueError("Tin nhắn 'text' không được có nội dung rỗng.")
            if message_type == 'image' and not image_url:
                raise ValueError("Tin nhắn 'image' phải có image_url.")
        return v 

    class Config:
        json_schema_extra = {
            "examples": [
                {"message_type": "text", "content": "Chào mọi người!"},
                {"message_type": "image", "image_url": "https://...url.png"}
            ]
        }

class MessagePublic(BaseModel):
    """
    Output: Dữ liệu JSON trả về khi LẤY lịch sử chat
    """
    id: int
    group_id: int
    # === SỬA ĐỔI (GĐ 9.8): Đổi sender_id sang string (UUID) ===
    sender_id: str 
    message_type: str
    content: Optional[str] = None
    image_url: Optional[str] = None
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True