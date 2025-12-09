from pydantic import BaseModel, Field, EmailStr, field_validator
from typing import List, Optional, Any, Dict
from datetime import datetime

# ====================================================================
# INPUT MODELS
# ====================================================================

class CreateGroupInput(BaseModel):
    name: str = Field(..., min_length=3, max_length=100)
    max_members: int = Field(..., gt=1, lt=20) 
    group_image_url: Optional[str] = None

class RequestJoinInput(BaseModel):
    group_id: int

class CancelRequestInput(BaseModel):
    group_id: int

class ActionRequestInput(BaseModel):
    group_id: int  # <--- [QUAN TRỌNG] Host phải chỉ định nhóm nào
    profile_uuid: str 
    action: str 

    @field_validator('action', mode='before')
    @classmethod
    def normalize_action(cls, v: str):
        if not v: raise ValueError("Hành động không được để trống")
        v_clean = v.strip().lower()
        if v_clean not in ('accept', 'reject', 'kick'):
            raise ValueError("Hành động chỉ có thể là 'accept', 'reject' hoặc 'kick'")
        return v_clean

# ====================================================================
# OUTPUT MODELS
# ====================================================================

class PendingRequestPublic(BaseModel):
    profile_uuid: str
    email: EmailStr
    fullname: Optional[str] = None
    avatar_url: Optional[str] = None  # <--- [MỚI] Hiện ảnh user xin vào
    requested_at: Optional[datetime] = None
    class Config:
        from_attributes = True

class GroupPlanOutput(BaseModel):
    group_id: int
    group_name: str
    preferred_city: str
    travel_dates: Optional[Any] = None
    itinerary: Optional[Dict[str, str]] = None 
    group_image_url: Optional[str] = None
    interests: Optional[List[str]] = None # <--- [MỚI] Hiện sở thích nhóm
    class Config:
        from_attributes = True

class SuggestionOutput(BaseModel):
    group_id: int
    name: str
    score: float
    group_image_url: Optional[str] = None
    member_count: int # <--- [MỚI] Hiện sĩ số (3/5)
    max_members: int

class GroupMemberPublic(BaseModel):
    profile_uuid: str
    role: str             
    fullname: str         
    email: str            
    avatar_url: Optional[str] = None 

class GroupDetailPublic(BaseModel):
    id: int
    name: str
    status: str
    member_count: int
    max_members: int
    group_image_url: Optional[str] = None
    members: List[GroupMemberPublic]