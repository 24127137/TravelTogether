from pydantic import BaseModel, EmailStr, Field, field_validator, ValidationInfo
from typing import List, Optional, Any, Dict, Union
from datetime import datetime, date

# ====================================================================
# Model cho /users/me (Lấy thông tin của tôi)
# ====================================================================
class ProfilePublic(BaseModel):
    id: int
    fullname: Optional[str] = None
    email: EmailStr
    gender: Optional[str] = None
    interests: Optional[List[str]] = None
    preferred_city: Optional[str] = None
    travel_dates: Optional[Any] = None
    
    # === CẬP NHẬT: Itinerary đơn giản (Số thứ tự : Địa điểm) ===
    # Ví dụ: {"1": "Hồ Tây", "2": "Lăng Bác"}
    itinerary: Optional[Dict[str, str]] = None
    
    owned_groups: Optional[List[Dict[str, Any]]] = None
    joined_groups: Optional[List[Dict[str, Any]]] = None
    pending_requests: Optional[List[Dict[str, Any]]] = None
    created_at: Optional[datetime] = None
    birthday: Optional[date] = None
    description: Optional[str] = None
    avatar_url: Optional[str] = None

    class Config:
        from_attributes = True 

# ====================================================================
# Model cho Cập nhật Profile (PATCH /users/me)
# ====================================================================
class ProfileUpdate(BaseModel):
    fullname: Optional[str] = None
    gender: Optional[str] = None
    interests: Optional[List[str]] = None
    preferred_city: Optional[str] = None
    email: Optional[EmailStr] = None
    password: Optional[str] = Field(default=None, min_length=6)
    travel_dates: Optional[Any] = None
    
    # === CẬP NHẬT: Itinerary đơn giản ===
    itinerary: Optional[Dict[str, str]] = None
    
    owned_groups: Optional[List[Dict[str, Any]]] = None
    joined_groups: Optional[List[Dict[str, Any]]] = None
    pending_requests: Optional[List[Dict[str, Any]]] = None
    birthday: Optional[date] = None
    description: Optional[str] = None
    avatar_url: Optional[str] = None

    @field_validator("gender", mode='before')
    @classmethod
    def normalize_gender(cls, v: Optional[str]):
        if v is None: return None
        v_clean = v.strip().lower()
        allowed_genders = ["male", "female", "other", "prefer_not_to_say"]
        if v_clean not in allowed_genders:
            raise ValueError(f"Giới tính không hợp lệ. Phải là: {allowed_genders}")
        return v
    
    class Config:
        json_schema_extra = {
            "example": {
                "fullname": "Nguyễn Văn A",
                "preferred_city": "Hà Nội",
                "itinerary": {
                    "1": "Hồ Tây",
                    "2": "Lăng Bác",
                    "3": "Phố Cổ"
                }
            }
        }