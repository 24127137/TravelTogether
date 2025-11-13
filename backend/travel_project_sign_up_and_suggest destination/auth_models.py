from pydantic import BaseModel, EmailStr
from typing import Dict, Any, Optional

# ====================================================================
# THÊM MỚI (GĐ 4.6/4.7): Models cho Sign In
# ====================================================================

class SignInInput(BaseModel):
    """
    Dữ liệu (JSON) mà API /auth/signin mong đợi nhận vào
    """
    email: EmailStr
    password: str

class UserInfo(BaseModel):
    """
    Model con để chứa thông tin user trả về
    """
    id: str # UUID
    email: EmailStr

class SignInResponse(BaseModel):
    """
    (SỬA ĐỔI GĐ 4.7 - Mobile App)
    Dữ liệu (JSON) mà API /auth/signin trả về cho App
    """
    message: str
    access_token: str
    refresh_token: str
    user: UserInfo # Trả về thông tin user

# ====================================================================
# THÊM MỚI (GĐ 5): Models cho "Đổi vé" (Refresh Token)
# ====================================================================

class RefreshInput(BaseModel):
    """
    Dữ liệu (JSON) mà API /auth/refresh mong đợi nhận vào
    (Frontend gửi "vé dự phòng" lên)
    """
    refresh_token: str

class RefreshResponse(BaseModel):
    """
    Dữ liệu (JSON) mà API /auth/refresh trả về
    (Backend trả về "vé vào cửa" mới)
    """
    access_token: str
    refresh_token: str # Supabase cũng trả về 1 refresh token mới