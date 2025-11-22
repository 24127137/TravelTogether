from pydantic import BaseModel, Field, EmailStr, validator
# === SỬA ĐỔI (GĐ 15.2): Thêm Any, Dict ===
from typing import List, Optional, Any, Dict
from datetime import datetime

# ====================================================================
# Models cho TÍNH NĂNG NHÓM (Group) (GĐ 15.2)
# ====================================================================

class CreateGroupInput(BaseModel):
    name: str = Field(..., min_length=3, max_length=100)
    max_members: int = Field(..., gt=1, lt=20) 

class RequestJoinInput(BaseModel):
    group_id: int

class ActionRequestInput(BaseModel):
    profile_uuid: str 
    action: str  # "accept", "reject", "kick"

class PendingRequestPublic(BaseModel):
    profile_uuid: str
    email: EmailStr
    fullname: Optional[str] = None
    requested_at: Optional[datetime] = None
    class Config:
        from_attributes = True

class GroupExitInput(BaseModel):
    action: str 
    new_host_uuid: Optional[str] = None 
    @validator('action')
    def validate_action(cls, v):
        if v not in ('dissolve', 'transfer'):
            raise ValueError("Hành động chỉ có thể là 'dissolve' hoặc 'transfer'")
        return v
    @validator('new_host_uuid')
    def validate_new_host_uuid(cls, v, values):
        if 'action' in values and values['action'] == 'transfer' and not v:
            raise ValueError("new_host_uuid là bắt buộc khi 'action' là 'transfer'")
        return v

# === SỬA ĐỔI (GĐ 15.2): Model "Kế hoạch" (Thêm City) ===
class GroupPlanOutput(BaseModel): # Đổi tên
    """
    Output: Trả về Kế hoạch (Plan) của nhóm
    (Đã thêm City GĐ 15.2)
    """
    # === THÊM LẠI THEO YÊU CẦU ===
    preferred_city: str
    # ==========================
    travel_dates: Optional[Any] = None
    itinerary: Optional[Dict[str, Any]] = None # Lịch trình

    class Config:
        from_attributes = True # Tự động đọc từ SQLModel
# ===============================================