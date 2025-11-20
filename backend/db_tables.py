<<<<<<< HEAD:backend/db_tables.py
from sqlmodel import SQLModel, Field, Column, ForeignKey
from typing import List, Optional, Any, Dict
=======
from sqlmodel import SQLModel, Field, Column
from typing import List, Optional, Any, Dict
# === SỬA ĐỔI (GĐ 8.4): Import 'date' ===
>>>>>>> develop:backend/travel_project_sign_up_and_suggest destination/db_tables.py
from datetime import datetime, date
from sqlalchemy.dialects.postgresql import TEXT, UUID, JSONB, DATERANGE, ARRAY

# ====================================================================
<<<<<<< HEAD:backend/db_tables.py
# BẢNG (SQLModel): "Profiles" (KHÔNG THAY ĐỔI)
# ====================================================================
class Profiles(SQLModel, table=True):
=======
# BẢNG (SQLModel): "Profiles"
# ====================================================================
class Profiles(SQLModel, table=True):
    """
    Model cho bảng 'profiles' (Thiết kế "Tất cả trong một")
    """
>>>>>>> develop:backend/travel_project_sign_up_and_suggest destination/db_tables.py
    id: Optional[int] = Field(default=None, primary_key=True)
    fullname: Optional[str] = None
    auth_user_id: str = Field(sa_column=Column(UUID(as_uuid=False), unique=True))
    email: str = Field(sa_column=Column(TEXT, unique=True, index=True))
    gender: Optional[str] = None
    interests: Optional[List[str]] = Field(default=None, sa_column=Column(ARRAY(TEXT)))
    preferred_city: Optional[str] = Field(default=None)
    travel_dates: Optional[Any] = Field(default=None, sa_column=Column(DATERANGE))
<<<<<<< HEAD:backend/db_tables.py
    itinerary: Optional[Dict[str, Any]] = Field(default=None, sa_column=Column(JSONB)) # <-- CỘT NÀY QUAN TRỌNG
=======
    itinerary: Optional[Dict[str, Any]] = Field(default=None, sa_column=Column(JSONB))
>>>>>>> develop:backend/travel_project_sign_up_and_suggest destination/db_tables.py
    owned_groups: Optional[List[Dict[str, Any]]] = Field(default=None, sa_column=Column(JSONB))
    joined_groups: Optional[List[Dict[str, Any]]] = Field(default=None, sa_column=Column(JSONB))
    pending_requests: Optional[List[Dict[str, Any]]] = Field(default=None, sa_column=Column(JSONB))
    created_at: Optional[datetime] = Field(default=None, sa_column_kwargs={"default": "NOW()"})
<<<<<<< HEAD:backend/db_tables.py
    birthday: Optional[date] = Field(default=None)
    description: Optional[str] = Field(default=None, sa_column=Column(TEXT))
    avatar_url: Optional[str] = Field(default=None, sa_column=Column(TEXT))

# ====================================================================
# BẢNG (SQLModel): "Destination" (KHÔNG THAY ĐỔI)
# ====================================================================
class Destination(SQLModel, table=True):
    # (Code không thay đổi)
    id: Optional[int] = Field(default=None, primary_key=True)
    city: str
    location_name: str = Field(sa_column=Column(TEXT, unique=True))
    description: str

# ====================================================================
# BẢNG (SQLModel): "TravelGroups" (CẬP NHẬT GĐ 12)
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
    
    # === THÊM MỚI (GĐ 12): Thêm cột Itinerary ===
    itinerary: Optional[Dict[str, Any]] = Field(default=None, sa_column=Column(JSONB))
    # ========================================

# ====================================================================
# BẢNG (SQLModel): "GroupMessages" (KHÔNG THAY ĐỔI)
# ====================================================================
class GroupMessages(SQLModel, table=True):
    # (Code không thay đổi)
    __tablename__ = "group_messages" 
    id: Optional[int] = Field(default=None, primary_key=True)
    group_id: int = Field(foreign_key="travel_groups.id")
    sender_id: str = Field(sa_column=Column(UUID(as_uuid=False), ForeignKey("profiles.auth_user_id")))
    message_type: str = Field(default="text") 
    content: Optional[str] = Field(default=None, sa_column=Column(TEXT))
    image_url: Optional[str] = Field(default=None, sa_column=Column(TEXT))
    created_at: Optional[datetime] = Field(default=None, sa_column_kwargs={"default": "NOW()"})
=======

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
>>>>>>> develop:backend/travel_project_sign_up_and_suggest destination/db_tables.py
