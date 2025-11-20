from sqlmodel import SQLModel, Field, Column
from typing import List, Optional, Any, Dict
# === SỬA ĐỔI (GĐ 8.4): Import 'date' ===
from datetime import datetime, date
from sqlalchemy.dialects.postgresql import TEXT, UUID, JSONB, DATERANGE, ARRAY

# ====================================================================
# BẢNG (SQLModel): "Profiles"
# ====================================================================
class Profiles(SQLModel, table=True):
    """
    Model cho bảng 'profiles' (Thiết kế "Tất cả trong một")
    """
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

    # === THÊM MỚI (GĐ 8.4): 3 cột mới ===
    birthday: Optional[date] = Field(default=None)
    description: Optional[str] = Field(default=None, sa_column=Column(TEXT))
    avatar_url: Optional[str] = Field(default=None, sa_column=Column(TEXT))
    # ==================================

# ====================================================================
# BẢNG (SQLModel): "Destination"
# ====================================================================
class Destination(SQLModel, table=True):
    """
    Model cho bảng 'destination' (Khớp 100% với DB của bạn)
    """
    id: Optional[int] = Field(default=None, primary_key=True)
    city: str
    location_name: str = Field(sa_column=Column(TEXT, unique=True))
    description: str