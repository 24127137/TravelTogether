from pydantic import BaseModel, Field
from typing import Optional, List
from sqlmodel import SQLModel, Field as SQLField, Column, ForeignKey
from datetime import datetime

# SQLModel table
class Feedbacks(SQLModel, table=True):
    __tablename__ = "feedbacks"
    id: Optional[int] = SQLField(default=None, primary_key=True)
    send_id: int = SQLField(foreign_key="profiles.id")
    rev_id: int = SQLField(foreign_key="profiles.id")
    rating: Optional[int] = SQLField(default=None, sa_column=Column("rating", nullable=True))
    content: Optional[str] = SQLField(default=None, sa_column=Column("content", nullable=True))
    anonymous: bool = SQLField(default=False)
    created_at: Optional[datetime] = SQLField(default=None, sa_column_kwargs={"default": "NOW()"})

# Pydantic models for API input/output
class CreateFeedbackInput(BaseModel):
    rev_id: int = Field(..., description="ID profile người nhận")
    rating: Optional[int] = Field(None, ge=1, le=5)
    content: Optional[str] = Field(None, max_length=5000)
    anonymous: Optional[bool] = Field(False)

class UpdateFeedbackInput(BaseModel):
    rating: Optional[int] = Field(None, ge=1, le=5)
    content: Optional[str] = Field(None, max_length=5000)
    anonymous: Optional[bool] = None

class FeedbackPublic(BaseModel):
    id: int
    send_id: int
    rev_id: int
    rating: Optional[int]
    content: Optional[str]
    anonymous: bool
    created_at: Optional[datetime]

    class Config:
        orm_mode = True
