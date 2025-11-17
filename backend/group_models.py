from pydantic import BaseModel, Field, EmailStr, validator
from typing import List, Optional
from datetime import datetime

# ====================================================================
# Models cho TÍNH NĂNG NHÓM (Group) (GĐ 14 - Thêm Out Group)
# ====================================================================

class CreateGroupInput(BaseModel):
    """
    Input: Dùng để TẠO nhóm
    """
    name: str = Field(..., min_length=3, max_length=100)
    max_members: int = Field(..., gt=1, lt=20) 

class RequestJoinInput(BaseModel):
    """
    Input: Dùng để XIN VÀO nhóm
    """
    group_id: int

class ActionRequestInput(BaseModel):
    """
    Input: Dùng để Host DUYỆT/KICK
    """
    profile_uuid: str 
    action: str  # "accept", "reject", "kick"

class PendingRequestPublic(BaseModel):
    """
    Output: Thông tin người dùng đang chờ duyệt
    """
    profile_uuid: str
    email: EmailStr
    fullname: Optional[str] = None
    requested_at: Optional[datetime] = None

    class Config:
        from_attributes = True

# === THÊM MỚI (GĐ 14): Model cho Rời/Giải tán Nhóm ===
class GroupExitInput(BaseModel):
    """
    Input: Dùng cho API /groups/exit (Host)
    """
    action: str # Phải là 'dissolve' hoặc 'transfer'
    new_host_uuid: Optional[str] = None # Bắt buộc nếu action='transfer'

    @validator('action')
    def validate_action(cls, v):
        if v not in ('dissolve', 'transfer'):
            raise ValueError("Hành động chỉ có thể là 'dissolve' hoặc 'transfer'")
        return v

    @validator('new_host_uuid')
    def validate_new_host_uuid(cls, v, values):
        # Kiểm tra xem 'new_host_uuid' có tồn tại không nếu 'action' là 'transfer'
        if 'action' in values and values['action'] == 'transfer' and not v:
            raise ValueError("new_host_uuid là bắt buộc khi 'action' là 'transfer'")
        return v
# ===============================================