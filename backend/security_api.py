from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session
from typing import Optional, Dict, Any
from pydantic import BaseModel, Field

# 1. Import hàm gốc trả về Object User
from auth_guard import get_current_user 

# Các import khác
from database import get_session
from security_service import SecurityService

router = APIRouter(prefix="/security", tags=["User Security"])
service = SecurityService()

# ==========================================
# HELPER (CẦU NỐI): Lấy ID từ User Object
# ==========================================
def get_user_id(user: Any = Depends(get_current_user)) -> str:
    """
    Hàm này nhận User Object từ auth_guard, 
    sau đó chỉ lấy ra phần .id (chuỗi UUID) để trả về.
    """
    return user.id

# ==========================================
# PYDANTIC MODELS
# ==========================================

class PinSetupRequest(BaseModel):
    pin: str = Field(..., min_length=4, max_length=6, description="Mã PIN 4-6 số")

class LocationData(BaseModel):
    latitude: float
    longitude: float
    accuracy: Optional[float] = None
    device_info: Optional[str] = None

class PinVerifyRequest(BaseModel):
    pin: str
    location: Optional[LocationData] = None 

class SecurityStatusResponse(BaseModel):
    status: str
    message: str

# ==========================================
# API ENDPOINTS
# ==========================================

@router.post("/set-safe-pin", response_model=SecurityStatusResponse)
def set_safe_pin(
    payload: PinSetupRequest,
    # SỬ DỤNG HÀM CẦU NỐI Ở ĐÂY
    user_id: str = Depends(get_user_id), 
    session: Session = Depends(get_session)
):
    try:
        service.set_safe_pin(session, user_id, payload.pin)
        return {"status": "success", "message": "Safe PIN set successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/set-danger-pin", response_model=SecurityStatusResponse)
def set_danger_pin(
    payload: PinSetupRequest,
    user_id: str = Depends(get_user_id),
    session: Session = Depends(get_session)
):
    try:
        service.set_danger_pin(session, user_id, payload.pin)
        return {"status": "success", "message": "Danger PIN set successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/verify-pin")
def verify_pin(
    payload: PinVerifyRequest,
    user_id: str = Depends(get_user_id),
    session: Session = Depends(get_session)
):
    """
    Xác thực PIN + Location
    """
    location_dict = payload.location.model_dump() if payload.location else None

    # Gọi Service
    result_status = service.validate_pin(
        session=session, 
        user_id=user_id, 
        pin=payload.pin, 
        current_location=location_dict
    )

    if result_status == "safe":
        return {"status": "safe", "action": "unlock", "message": "Xác thực thành công."}
    
    elif result_status == "danger":
        return {"status": "danger", "action": "fake_mode", "message": "Chế độ khách."}
    
    elif result_status == "wrong":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail="Mã PIN không chính xác."
        )

    raise HTTPException(status_code=500, detail="Unknown error")

@router.get("/status")
def check_security_status(
    user_id: str = Depends(get_user_id),
    session: Session = Depends(get_session)
):
    is_overdue = service.check_overdue(session, user_id)
    sec_record = service.get_user_security(session, user_id)
    
    if not sec_record:
        return {"status": "setup_required", "is_overdue": False}

    return {
        "status": sec_record.status,
        "is_overdue": is_overdue,
        "last_confirmation": sec_record.last_confirmation_ts
    }