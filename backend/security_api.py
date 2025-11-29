from fastapi import APIRouter, Depends, HTTPException, status, Body
from sqlmodel import Session
from typing import Optional, Dict, Any
from pydantic import BaseModel, Field

# Import các thành phần từ project của bạn
# Giả sử file cấu hình db nằm ở database.py và auth nằm ở dependencies.py
from database import get_session
from sqlmodel import Session
from auth_guard import get_current_user  # Hàm dependency lấy user_id từ Token
from database import get_session
from security_service import SecurityService
from security_model import PinSetupRequest, PinVerifyRequest, SecurityStatusResponse

router = APIRouter(prefix="/security", tags=["User Security"])
service = SecurityService()


def get_current_user_id(user: Any = Depends(get_current_user)) -> str:
    """
    Hàm này nhận User Object từ auth_guard, 
    sau đó chỉ lấy ra phần .id (chuỗi UUID) để trả về.
    """
    return user.id
# ==========================================
# 2. API Endpoints
# ==========================================

@router.post("/set-safe-pin", response_model=SecurityStatusResponse)
def set_safe_pin(
    payload: PinSetupRequest,
    user_id: str = Depends(get_current_user_id),
    session: Session = Depends(get_session)
):
    """
    Thiết lập mã PIN an toàn.
    """
    try:
        service.set_safe_pin(session, user_id, payload.pin)
        return {"status": "success", "message": "Safe PIN set successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/set-danger-pin", response_model=SecurityStatusResponse)
def set_danger_pin(
    payload: PinSetupRequest,
    user_id: str = Depends(get_current_user_id),
    session: Session = Depends(get_session)
):
    """
    Thiết lập mã PIN nguy hiểm (giả mạo).
    """
    try:
        service.set_danger_pin(session, user_id, payload.pin)
        return {"status": "success", "message": "Danger PIN set successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/verify-pin")
def verify_pin(
    payload: PinVerifyRequest,
    user_id: str = Depends(get_current_user_id),
    session: Session = Depends(get_session)
):
    """
    Xác thực PIN hàng ngày.
    Frontend cần gửi kèm location lấy từ `navigator.geolocation`.
    """
    # Chuyển đổi model Pydantic thành Dict để lưu vào JSONB
    location_dict = payload.location.model_dump() if payload.location else None

    # Gọi service (Logic đã refactor ở bước trước)
    result_status = service.validate_pin(
        session=session, 
        user_id=user_id, 
        pin=payload.pin, 
        current_location=location_dict
    )

    # Xử lý phản hồi dựa trên kết quả verify
    if result_status == "safe":
        return {
            "status": "safe", 
            "action": "unlock", 
            "message": "Xác thực thành công."
        }
    
    elif result_status == "danger":
        # Quan trọng: Vẫn trả về HTTP 200 để Frontend không báo lỗi đỏ lòm,
        # nhưng hành động bên trong là xoá cache/ẩn dữ liệu nhạy cảm.
        return {
            "status": "danger", 
            "action": "fake_mode", 
            "message": "Mở chế độ khách." # Giả vờ bình thường
        }
    
    elif result_status == "wrong":
        # Trả về 400 hoặc 401 để Frontend hiển thị "Sai mã PIN"
        # service đã tự động đếm số lần sai và lưu log nếu cần.
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail="Mã PIN không chính xác."
        )

    raise HTTPException(status_code=500, detail="Unknown error")

# ==========================================
# 3. Endpoint kiểm tra trạng thái (Optional)
# ==========================================

@router.get("/status")
def check_security_status(
    user_id: str = Depends(get_current_user_id),
    session: Session = Depends(get_session)
):
    """
    API này dùng để kiểm tra xem user có bị 'overdue' hay không 
    khi vừa mở app lên.
    """
    # Trigger kiểm tra overdue
    is_overdue = service.check_overdue(session, user_id)
    
    sec_record = service.get_user_security(session, user_id)
    
    if not sec_record:
        return {"status": "setup_required", "is_overdue": False}

    return {
        "status": sec_record.status,
        "is_overdue": is_overdue,
        "last_confirmation": sec_record.last_confirmation_ts
    }