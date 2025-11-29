"""
security_model.py
Pydantic models for request/response validation
"""

from pydantic import BaseModel, Field, field_validator
from typing import Optional, Literal
from datetime import datetime


class PinSetupRequest(BaseModel):
    pin: str = Field(..., min_length=4, max_length=6, description="Mã PIN (thường là 4-6 số)")

class LocationData(BaseModel):
    """Schema mô tả cấu trúc JSON tọa độ gửi từ Frontend"""
    latitude: float
    longitude: float
    accuracy: Optional[float] = None
    device_info: Optional[str] = None

class PinVerifyRequest(BaseModel):
    pin: str
    location: Optional[LocationData] = None # Location có thể None nếu user tắt GPS (nhưng nên bắt buộc ở Client)

class SecurityStatusResponse(BaseModel):
    status: str
    message: str