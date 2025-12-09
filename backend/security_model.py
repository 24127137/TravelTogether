"""
security_model.py
Pydantic models for request/response validation
"""

from pydantic import BaseModel, Field, field_validator
from typing import Optional, Literal
from datetime import datetime


# ==================== REQUEST MODELS ====================

class RegisterPinRequest(BaseModel):
    user_id: str
    safe_pin: str
    danger_pin: str
    default_confirmation_time: str = Field(..., regex=r"^([0-1][0-9]|2[0-3]):[0-5][0-9]$")
    
    @field_validator('danger_pin')
    def pins_must_differ(cls, v, values):
        if 'safe_pin' in values and v == values['safe_pin']:
            raise ValueError('danger_pin must be different from safe_pin')
        return v


class VerifyPinRequest(BaseModel):
    user_id: str
    pin: str


class ResetPinRequest(BaseModel):
    admin_token: str
    user_id: str
    new_safe_pin: Optional[str] = Field(None, min_length=4, max_length=8)
    new_danger_pin: Optional[str] = Field(None, min_length=4, max_length=8)
    
    @field_validator('new_danger_pin')
    def pins_must_differ_if_both(cls, v, values):
        if v and 'new_safe_pin' in values and values['new_safe_pin']:
            if v == values['new_safe_pin']:
                raise ValueError('new_danger_pin must be different from new_safe_pin')
        return v


class HeartbeatRequest(BaseModel):
    user_id: str
    device_info: Optional[str] = None


# ==================== RESPONSE MODELS ====================

class GenericResponse(BaseModel):
    success: bool
    message: str
    data: Optional[dict] = None


class StatusResponse(BaseModel):
    last_confirmation_ts: Optional[str]
    last_online_ts: Optional[str]
    next_required_time: Optional[str]
    state: Literal["safe", "danger_pending", "locked"]
    hours_since_confirmation: Optional[float]
    hours_since_online: Optional[float]


class InternalJobResponse(BaseModel):
    success: bool
    processed_count: int
    details: list[dict]


# ==================== INTERNAL MODELS ====================

class PinVerifyResult:
    SAFE = "SAFE"
    DANGER = "DANGER"
    WRONG_PIN = "WRONG_PIN"
    LOCKED = "LOCKED"


class UserSecurityData(BaseModel):
    user_id: str
    safe_pin_hash: str
    danger_pin_hash: str
    default_confirmation_time: str
    last_confirmation_ts: Optional[datetime]
    last_online_ts: Optional[datetime]
    retry_fail_count: int = 0
    is_locked: bool = False
    created_at: datetime
    updated_at: datetime
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat() if v else None
        }