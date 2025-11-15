from pydantic import BaseModel, EmailStr, Field
from typing import Dict, Any, Optional, List

# ====================================================================
# Model cho Đăng Ký (Sign Up)
# ====================================================================
class ProfileCreate(BaseModel):
    """
    (Đã di chuyển GĐ 8)
    Dữ liệu (JSON) mà API /auth/signup mong đợi nhận vào
    """
    email: EmailStr
    password: str = Field(min_length=6)
    
    fullname: Optional[str] = None
    gender: Optional[str] = None
    interests: List[str]
    preferred_city: str

    class Config:
        json_schema_extra = {
            "example": {
                "email": "cuong_final_v3@example.com",
                "password": "PasswordCucManh123!",
                "fullname": "Nguyễn Văn Cường",
                "gender": "male",
                "interests": ["biển", "ẩm thực", "sôi động"],
                "preferred_city": "Đà Nẵng"
            }
        }

# ====================================================================
# Models cho Đăng nhập (Sign In)
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
    Dữ liệu (JSON) mà API /auth/signin trả về cho App
    """
    message: str
    access_token: str
    refresh_token: str
    user: UserInfo

# ====================================================================
# Models cho "Đổi vé" (Refresh Token)
# ====================================================================
class RefreshInput(BaseModel):
    """
    Dữ liệu (JSON) mà API /auth/refresh mong đợi nhận vào
    """
    refresh_token: str

class RefreshResponse(BaseModel):
    """
    Dữ liệu (JSON) mà API /auth/refresh trả về
    """
    access_token: str
    refresh_token: str