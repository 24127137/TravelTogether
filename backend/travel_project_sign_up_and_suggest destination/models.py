# models.py
from sqlmodel import SQLModel, Field, Column
from pydantic import BaseModel, EmailStr
from typing import List, Optional, Any, Dict
from datetime import datetime
from sqlalchemy.dialects.postgresql import TEXT, UUID, JSONB, DATERANGE, ARRAY

# ====================================================================
# SQLModel: BẢNG DATABASE
# ====================================================================
class Profiles(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    fullname: Optional[str] = None
    auth_user_id: str = Field(sa_column=Column(UUID(as_uuid=False), unique=True))
    email: str = Field(sa_column=Column(TEXT, unique=True, index=True))
    gender: Optional[str] = None
    interests: Optional[List[str]] = Field(default=None, sa_column=Column(ARRAY(TEXT)))
    preferred_city: Optional[str] = None
    travel_dates: Optional[Any] = Field(default=None, sa_column=Column(DATERANGE))
    itinerary: Optional[Dict[str, Any]] = Field(default=None, sa_column=Column(JSONB))
    owned_groups: Optional[List[Dict[str, Any]]] = Field(default=None, sa_column=Column(JSONB))
    joined_groups: Optional[List[Dict[str, Any]]] = Field(default=None, sa_column=Column(JSONB))
    pending_requests: Optional[List[Dict[str, Any]]] = Field(default=None, sa_column=Column(JSONB))
    created_at: Optional[datetime] = Field(default=None, sa_column_kwargs={"default": "NOW()"})


class Destination(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    city: str
    location_name: str = Field(sa_column=Column(TEXT, unique=True))
    description: str


class TravelGroup(SQLModel, table=True):
    __tablename__ = "travel_groups"
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str
    owner_id: int = Field(foreign_key="profiles.id")
    status: Optional[str] = Field(default="open")
    max_members: int = 5
    preferred_city: str
    travel_dates: Optional[Any] = Field(sa_column=Column(DATERANGE))
    interests: List[str] = Field(default_factory=list, sa_column=Column(ARRAY(TEXT)))
    members: List[Dict[str, Any]] = Field(default_factory=list, sa_column=Column(JSONB))
    pending_requests: List[Dict[str, Any]] = Field(default_factory=list, sa_column=Column(JSONB))
    created_at: Optional[datetime] = None


# ====================================================================
# Pydantic: INPUT / OUTPUT
# ====================================================================
class ProfileCreate(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6)
    fullname: Optional[str] = None
    gender: Optional[str] = None
    interests: List[str]
    preferred_city: str

    class Config:
        json_schema_extra = {
            "example": {
                "email": "alice@travel.vn",
                "password": "123456KKK@",
                "fullname": "Alice Nguyễn",
                "interests": ["cà phê", "leo núi"],
                "preferred_city": "Đà Lạt"
            }
        }


class RecommendationOutput(BaseModel):
    location_name: str
    score: int

    class Config:
        json_schema_extra = {
            "example": {"location_name": "Biển Mỹ Khê", "score": 95}
        }


class ProfilePublic(BaseModel):
    id: int
    fullname: Optional[str] = None
    email: EmailStr
    gender: Optional[str] = None
    interests: Optional[List[str]] = None
    preferred_city: Optional[str] = None
    travel_dates: Optional[Any] = Field(default=None, sa_column=Column(DATERANGE))
    itinerary: Optional[Dict[str, Any]] = Field(default=None, sa_column=Column(JSONB))
    owned_groups: Optional[List[Dict[str, Any]]] = None
    joined_groups: Optional[List[Dict[str, Any]]] = None
    pending_requests: Optional[List[Dict[str, Any]]] = None
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class ProfileUpdate(BaseModel):
    fullname: Optional[str] = None
    gender: Optional[str] = None
    interests: Optional[List[str]] = None
    preferred_city: Optional[str] = None
    email: Optional[EmailStr] = None
    password: Optional[str] = Field(default=None, min_length=6)
    travel_dates: Optional[Any] = Field(default=None, sa_column=Column(DATERANGE))
    itinerary: Optional[Dict[str, Any]] = Field(default=None, sa_column=Column(JSONB))

    class Config:
        json_schema_extra = {
            "example": {
                "fullname": "Alice Nguyễn",
                "preferred_city": "Đà Lạt",
                "travel_dates": ["2025-12-20", "2025-12-25"],
                "itinerary": [{"name": "Hồ Xuân Hương"}, {"name": "Cà phê Tùng"}],
                "interests": ["cà phê", "leo núi"]
            }
        }


class CreateGroupInput(BaseModel):
    name: str
    max_members: int = 5
    travel_dates: List[str]


class RequestJoinInput(BaseModel):
    group_id: int


class ActionRequestInput(BaseModel):
    profile_id: int
    action: str  # "accept", "reject", "kick"