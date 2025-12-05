from pydantic import BaseModel, Field
from typing import Optional, List
from sqlmodel import SQLModel, Field as SQLField, Column, ForeignKey
from datetime import datetime
from sqlalchemy.dialects.postgresql import TEXT, ARRAY

# SQLModel table
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

# Pydantic models for API input/output
class CreateFeedbackInput(BaseModel):
    rev_id: int = Field(..., description="ID profile người nhận")
    group_id: Optional[int] = Field(None, description="ID của nhóm du lịch liên quan")
    group_image_url: Optional[str] = Field(None, description="URL ảnh đại diện của group")
    rating: Optional[int] = Field(None, ge=1, le=5)
    content: Optional[List[str]] = Field(None, description="List tags cho nội dung đánh giá (e.g., ['friendly', 'punctual'])")
    anonymous: Optional[bool] = Field(False)

class BatchCreateFeedbackInput(BaseModel):
    group_id: int = Field(..., description="ID nhóm để validate")
    feedbacks: List[CreateFeedbackInput] = Field(..., description="List feedbacks cho multiple recipients")

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
        orm_mode = True

# Public models cho list groups với feedback
class UserGroupFeedbackSummary(BaseModel):
    group_id: int
    group_name: str
    group_image_url: Optional[str]
    average_rating: float  # Trung bình sao cho user trong group

class FeedbackDetail(FeedbackPublic):
    sender_name: Optional[str]  # Chỉ hiển thị nếu không anonymous
    rev_name: Optional[str]  # Tên người nhận