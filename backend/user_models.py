from pydantic import BaseModel, EmailStr, Field
from typing import List, Optional, Any, Dict
# === SỬA ĐỔI (GĐ 8.4): Import 'date' ===
from datetime import datetime, date

# ====================================================================
# Model cho /users/me (Lấy thông tin của tôi)
# ====================================================================
class ProfilePublic(BaseModel):
    """
    (Model đã refactor GĐ 8.1)
    Model Pydantic cho Dữ liệu Profile CÔNG KHAI
    """
    id: int
    fullname: Optional[str] = None
    email: EmailStr
    gender: Optional[str] = None
    interests: Optional[List[str]] = None
    preferred_city: Optional[str] = None
    travel_dates: Optional[Any] = None
    itinerary: Optional[Dict[str, Any]] = None
    owned_groups: Optional[List[Dict[str, Any]]] = None
    joined_groups: Optional[List[Dict[str, Any]]] = None
    pending_requests: Optional[List[Dict[str, Any]]] = None
    created_at: Optional[datetime] = None

    # === THÊM MỚI (GĐ 8.4): 3 cột mới ===
    birthday: Optional[date] = None
    description: Optional[str] = None
    avatar_url: Optional[str] = None
    # ==================================

    class Config:
        from_attributes = True 
        json_schema_extra = {
            "example": {
                "id": 1,
                "fullname": "Nguyễn Văn Cường",
                "email": "cuong_final_v2@example.com",
                "gender": "male",
                "interests": ["biển", "ẩm thực", "sôi động"],
                "preferred_city": "Đà Nẵng",
                "travel_dates": {"lower": "2025-12-20", "upper": "2025-12-25"},
                "itinerary": {"Day 1": "Đi biển Mỹ Khê"},
                "owned_groups": [],
                "joined_groups": [],
                "pending_requests": [],
                "created_at": "2025-11-10T08:30:00Z",
                # === THÊM MỚI (GĐ 8.4) ===
                "birthday": "2000-10-20",
                "description": "Xin chào, tôi là Cường.",
                "avatar_url": "https://...supabase.co/storage/v1/object/public/avatars/user_uuid.png"
            }
        }

# ====================================================================
# Model cho Cập nhật Profile (PATCH /users/me)
# ====================================================================
class ProfileUpdate(BaseModel):
    """
    (Model đã refactor GĐ 8.1)
    Dữ liệu (JSON) mà API /users/me (PATCH) mong đợi nhận vào.
    """
    fullname: Optional[str] = None
    gender: Optional[str] = None 
    interests: Optional[List[str]] = None
    preferred_city: Optional[str] = None
    email: Optional[EmailStr] = None
    password: Optional[str] = Field(default=None, min_length=6)
    travel_dates: Optional[Any] = None
    itinerary: Optional[Dict[str, Any]] = None
    owned_groups: Optional[List[Dict[str, Any]]] = None
    joined_groups: Optional[List[Dict[str, Any]]] = None
    pending_requests: Optional[List[Dict[str, Any]]] = None
    
    # === THÊM MỚI (GĐ 8.4): 3 cột mới ===
    birthday: Optional[date] = None
    description: Optional[str] = None
    avatar_url: Optional[str] = None
    # ==================================
    
    class Config:
        json_schema_extra = {
            "example": {
                "fullname": "Tên Mới Của Tôi",
                "interests": ["leo núi", "cà phê", "yên tĩnh"],
                "avatar_url": "https://...url_moi.png"
            }
        }