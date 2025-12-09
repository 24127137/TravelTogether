from fastapi import APIRouter, HTTPException, Depends, Request
from typing import Any  
from auth_models import (
    SignInInput, SignInResponse, 
    RefreshInput, RefreshResponse, 
    SignOutResponse, ProfileCreate,
    UserInfo,
    ChangePasswordInput 
)
from auth_guard import (
    api_key_scheme, 
    get_user_id_from_token, 
    hash_token, 
    get_current_user 
)
from db_tables import Profiles, TokenSecurity
import auth_service 
import traceback
from database import get_session
from sqlmodel import Session, select
from auth_guard import api_key_scheme, get_user_id_from_token

router = APIRouter(prefix="/auth", tags=["GĐ 8 - Authentication"])

# ====================================================================
# API SIGN UP
# ====================================================================
@router.post("/signup", response_model=Profiles)
async def create_profile_endpoint(
    profile_data: ProfileCreate, 
    session: Session = Depends(get_session)
):
    try:
        return await auth_service.create_profile_service(session, profile_data)
    except Exception as e:
        error_str = str(e)
        if "duplicate key" in error_str:
             raise HTTPException(status_code=400, detail="Email đã tồn tại.")
        if "Password should be at least" in error_str:
            raise HTTPException(status_code=400, detail="Mật khẩu quá yếu.")
        raise HTTPException(status_code=500, detail=str(e))

# ====================================================================
# API SIGN IN (Single Session)
# ====================================================================
@router.post("/signin", response_model=SignInResponse)
async def sign_in_endpoint(
    signin_data: SignInInput,
    request: Request,
    session: Session = Depends(get_session)
):
    try:
        # 1. Login Supabase
        res = await auth_service.sign_in_service(signin_data)
        
        # 2. Lưu Session (Ghi đè session cũ nếu có)
        await auth_service.save_active_session(
            session=session,
            user_id=str(res.user.id),
            access_token=res.session.access_token,
            ip=request.client.host,
            user_agent=request.headers.get("user-agent", ""),
            device_token=signin_data.device_token
        )

        # 3. Return (Fix lỗi UserInfo)
        return SignInResponse(
            message="Đăng nhập thành công",
            access_token=res.session.access_token,
            refresh_token=res.session.refresh_token,
            user=UserInfo(id=str(res.user.id), email=res.user.email)
        )
    except Exception as e:
        error_str = str(e)
        if "Invalid login credentials" in error_str:
            raise HTTPException(status_code=401, detail="Sai thông tin đăng nhập.")
        if "Email not confirmed" in error_str:
            raise HTTPException(status_code=401, detail="Email chưa được xác nhận.")
        raise HTTPException(status_code=500, detail=str(e))

# ====================================================================
# API REFRESH (IP Protected)
# ====================================================================
@router.post("/refresh", response_model=RefreshResponse)
async def refresh_token_endpoint(
    refresh_data: RefreshInput,
    request: Request,
    session: Session = Depends(get_session)
):
    try:
        # 1. Lấy token mới từ Supabase
        new_session = await auth_service.refresh_token_service(refresh_data)
        user_id = str(new_session.user.id)
        client_ip = request.client.host
        
        # 2. KIỂM TRA IP CỦA PHIÊN CŨ (Chống trộm Refresh Token)
        active_record = session.exec(select(TokenSecurity).where(TokenSecurity.user_id == user_id)).first()
        
        if active_record:
            # Nếu IP người refresh KHÁC IP gốc -> HACKER -> Xóa Session
            if active_record.ip_address != client_ip:
                session.delete(active_record)
                session.commit()
                print(f"SECURITY: Refresh Token stolen! IP gốc: {active_record.ip_address}, IP lạ: {client_ip}")
                raise HTTPException(401, "Phát hiện IP lạ. Phiên đã bị hủy.")
        
        # 3. Cập nhật Token mới vào DB (Giữ nguyên IP cũ)
        await auth_service.save_active_session(
            session=session,
            user_id=user_id,
            access_token=new_session.access_token,
            ip=client_ip, 
            user_agent=request.headers.get("user-agent", "")
        )
        
        return RefreshResponse(
            access_token=new_session.access_token,
            refresh_token=new_session.refresh_token
        )
    except HTTPException as he:
        raise he
    except Exception as e:
        raise HTTPException(status_code=401, detail="Refresh token không hợp lệ")

# ====================================================================
# API SIGN OUT
# ====================================================================
@router.post("/signout", response_model=SignOutResponse)
async def sign_out_endpoint(
    token_str: str = Depends(api_key_scheme),
    session: Session = Depends(get_session)
):
    if not token_str: raise HTTPException(401, "Thiếu token")
    
    real_token = token_str.split(" ")[1]
    user_uuid = get_user_id_from_token(real_token)
    
    if user_uuid:
        # Xóa khỏi DB -> Lần sau gọi API sẽ bị AuthGuard chặn
        await auth_service.sign_out_service(session, user_uuid)

    return {"message": "Đăng xuất thành công"}

@router.post("/change-password")
async def change_password_endpoint(
    password_data: ChangePasswordInput,
    session: Session = Depends(get_session),
    user_object: Any = Depends(get_current_user) 
):
    """
    Đổi mật khẩu và đăng xuất khỏi tất cả thiết bị.
    """
    try:
        user_id = str(user_object.id)
        await auth_service.change_password_service(session, user_id, password_data.new_password)
        return {"message": "Đổi mật khẩu thành công. Vui lòng đăng nhập lại."}
        
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Lỗi đổi mật khẩu: {e}")