from sqlmodel import SQLModel, Field, Column, ForeignKey
from typing import List, Optional, Any, Dict
from datetime import datetime, date
from sqlalchemy.dialects.postgresql import TEXT, UUID, JSONB, DATERANGE, ARRAY

# ====================================================================
# BẢNG (SQLModel): "Profiles" (KHÔNG THAY ĐỔI)
# ====================================================================
class Profiles(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    fullname: Optional[str] = None
    auth_user_id: str = Field(sa_column=Column(UUID(as_uuid=False), unique=True))
    email: str = Field(sa_column=Column(TEXT, unique=True, index=True))
    gender: Optional[str] = None
    interests: Optional[List[str]] = Field(default=None, sa_column=Column(ARRAY(TEXT)))
    preferred_city: Optional[str] = Field(default=None)
    travel_dates: Optional[Any] = Field(default=None, sa_column=Column(DATERANGE))
    itinerary: Optional[Dict[str, Any]] = Field(default=None, sa_column=Column(JSONB)) 
    owned_groups: Optional[List[Dict[str, Any]]] = Field(default=None, sa_column=Column(JSONB))
    joined_groups: Optional[List[Dict[str, Any]]] = Field(default=None, sa_column=Column(JSONB))
    pending_requests: Optional[List[Dict[str, Any]]] = Field(default=None, sa_column=Column(JSONB))
    created_at: Optional[datetime] = Field(default=None, sa_column_kwargs={"default": "NOW()"})
    birthday: Optional[date] = Field(default=None)
    description: Optional[str] = Field(default=None, sa_column=Column(TEXT))
    avatar_url: Optional[str] = Field(default=None, sa_column=Column(TEXT))

# ====================================================================
# BẢNG (SQLModel): "Destination" (KHÔNG THAY ĐỔI)
# ====================================================================
class Destination(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    city: str
    location_name: str = Field(sa_column=Column(TEXT, unique=True))
    description: str

# ====================================================================
# BẢNG (SQLModel): "TravelGroups" (ĐÃ BỔ SUNG CỘT THIẾU)
# ====================================================================
class TravelGroup(SQLModel, table=True):
    __tablename__ = "travel_groups"
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str
    owner_id: str = Field(sa_column=Column(UUID(as_uuid=False), ForeignKey("profiles.auth_user_id")))
    status: Optional[str] = Field(default="open")
    max_members: int = 5
    preferred_city: str
    travel_dates: Optional[Any] = Field(sa_column=Column(DATERANGE))
    interests: List[str] = Field(default_factory=list, sa_column=Column(ARRAY(TEXT)))
    members: List[Dict[str, Any]] = Field(default_factory=list, sa_column=Column(JSONB))
    pending_requests: List[Dict[str, Any]] = Field(default_factory=list, sa_column=Column(JSONB))
    created_at: Optional[datetime] = Field(default=None, sa_column_kwargs={"default": "NOW()"})
    
    itinerary: Optional[Dict[str, Any]] = Field(default=None, sa_column=Column(JSONB))
    
    # === CỘT QUAN TRỌNG BẠN VỪA THIẾU ===
    group_image_url: Optional[str] = Field(default=None, sa_column=Column(TEXT))
    # ====================================

# ====================================================================
# BẢNG (SQLModel): "GroupMessages" (KHÔNG THAY ĐỔI)
# ====================================================================
class GroupMessages(SQLModel, table=True):
    __tablename__ = "group_messages" 
    id: Optional[int] = Field(default=None, primary_key=True)
    group_id: int = Field(foreign_key="travel_groups.id")
    sender_id: str = Field(sa_column=Column(UUID(as_uuid=False), ForeignKey("profiles.auth_user_id")))
    message_type: str = Field(default="text") 
    content: Optional[str] = Field(default=None, sa_column=Column(TEXT))
    image_url: Optional[str] = Field(default=None, sa_column=Column(TEXT))
    created_at: Optional[datetime] = Field(default=None, sa_column_kwargs={"default": "NOW()"})

class UserSecurity(SQLModel, table=True):
    __tablename__ = "user_security"
    
    id: Optional[int] = Field(default=None, primary_key=True)
    
    # Liên kết với Profiles.auth_user_id
    user_id: str = Field(sa_column=Column(UUID(as_uuid=False), ForeignKey("profiles.auth_user_id", ondelete="CASCADE")))
    
    safe_pin_hash: Optional[str] = Field(default=None, sa_column=Column(TEXT))
    danger_pin_hash: Optional[str] = Field(default=None, sa_column=Column(TEXT))
    
    last_confirmation_ts: Optional[str] = Field(default=None, sa_column=Column(TEXT)) # Lưu timestamp dạng chuỗi
    
    default_confirmation_time: Optional[int] = Field(default=5) # Mặc định (ví dụ 5 phút)
    wrong_attempt_count: int = Field(default=0)
    
    status: Optional[str] = Field(default="active", sa_column=Column(TEXT))
    
    created_at: Optional[datetime] = Field(default=None, sa_column_kwargs={"default": "NOW()"})
    updated_at: Optional[datetime] = Field(default=None, sa_column_kwargs={"default": "NOW()"})

# ====================================================================
# BẢNG MỚI: "SecurityLocations"
# ====================================================================
class SecurityLocations(SQLModel, table=True):
    __tablename__ = "security_locations"
    
    id: Optional[int] = Field(default=None, primary_key=True)
    
    # Liên kết với Profiles.auth_user_id
    user_id: str = Field(sa_column=Column(UUID(as_uuid=False), ForeignKey("profiles.auth_user_id", ondelete="CASCADE")))
    
    location: Optional[str] = Field(default=None, sa_column=Column(TEXT)) # Có thể lưu toạ độ dạng "lat,long" hoặc JSON string
    reason: Optional[str] = Field(default=None, sa_column=Column(TEXT))
    
    timestamp: Optional[datetime] = Field(default=None, sa_column_kwargs={"default": "NOW()"})