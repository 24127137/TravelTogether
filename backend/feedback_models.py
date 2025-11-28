from pydantic import BaseModel, Field
from typing import Optional, List
from sqlmodel import SQLModel, Field as SQLField, Column, ForeignKey
from datetime import datetime
from sqlalchemy.dialects.postgresql import TEXT, ARRAY

# ====================================================================
# SQLModel table
# ====================================================================
class Feedbacks(SQLModel, table=True):
    __tablename__ = "feedbacks"
    id: Optional[int] = SQLField(default=None, primary_key=True)
    send_id: int = SQLField(foreign_key="profiles.id")
    rev_id: int = SQLField(foreign_key="profiles.id")
    group_id: Optional[int] = SQLField(default=None, foreign_key="travel_groups.id")
    group_image_url: Optional[str] = SQLField(default=None, sa_column=Column(TEXT))
    rating: Optional[int] = SQLField(default=None, sa_column=Column("rating", nullable=True))
    content: Optional[List[str]] = SQLField(default=None, sa_column=Column(ARRAY(TEXT)))
    anonymous: bool = SQLField(default=False)
    created_at: Optional[datetime] = SQLField(default=None, sa_column_kwargs={"default": "NOW()"})

# ====================================================================
# Pydantic models for API input/output
# ====================================================================
class CreateFeedbackInput(BaseModel):
    rev_id: int = Field(..., description="ID profile người nhận")
    group_id: int = Field(..., description="ID của nhóm du lịch (bắt buộc)")
    group_image_url: Optional[str] = Field(None, description="URL ảnh đại diện của group")
    rating: Optional[int] = Field(None, ge=1, le=5)
    content: Optional[List[str]] = Field(None, description="List tags cho nội dung đánh giá (e.g., ['friendly', 'punctual'])")
    anonymous: Optional[bool] = Field(False)

class UpdateFeedbackInput(BaseModel):
    rating: Optional[int] = Field(None, ge=1, le=5)
    content: Optional[List[str]] = Field(None, description="List tags cho nội dung đánh giá")
    anonymous: Optional[bool] = None

class FeedbackPublic(BaseModel):
    id: int
    send_id: int
    rev_id: int
    group_id: Optional[int]
    group_image_url: Optional[str]
    rating: Optional[int]
    content: Optional[List[str]]
    anonymous: bool
    created_at: Optional[datetime]

    class Config:
        from_attributes = True

class FeedbackDetail(FeedbackPublic):
    sender_name: Optional[str]  # Chỉ hiển thị nếu không anonymous
    sender_email: Optional[str]  # Email sender (ẩn nếu anonymous)
    receiver_name: Optional[str]  # Tên người nhận
    receiver_email: Optional[str]  # Email người nhận

# ====================================================================
# Models cho My Reputation
# ====================================================================
class GroupReputationSummary(BaseModel):
    group_id: int
    group_name: str
    group_image_url: Optional[str]
    feedbacks: List[FeedbackDetail]

class MyReputationResponse(BaseModel):
    average_rating: float
    total_feedbacks: int
    groups: List[GroupReputationSummary]

# ====================================================================
# Models cho Pending Reviews
# ====================================================================
class UnreviewedMember(BaseModel):
    profile_id: int
    profile_uuid: str
    email: str
    fullname: Optional[str]

class PendingReviewGroup(BaseModel):
    group_id: int
    group_name: str
    group_image_url: Optional[str]
    unreviewed_members: List[UnreviewedMember]

class PendingReviewsResponse(BaseModel):
    pending_groups: List[PendingReviewGroup]
