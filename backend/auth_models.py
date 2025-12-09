from pydantic import BaseModel, EmailStr, Field, field_validator, ValidationInfo
from typing import Optional, List, Any

# ====================================================================
# Model cho Đăng Ký (Sign Up)
# ====================================================================
class ProfileCreate(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6)
    
    fullname: Optional[str] = None
    gender: Optional[str] = None 
    interests: List[str]
    preferred_city: str
    
    # Cho phép nhập liên hệ khẩn cấp lúc đăng ký
    emergency_contact: Optional[EmailStr] = None 

    @field_validator("email", "password")
    @classmethod
    def validate_no_spaces(cls, v: str, info: ValidationInfo):
        if " " in v:
            raise ValueError(f"{info.field_name} không được phép chứa dấu cách")
        return v

    @field_validator("gender", mode='before')
    @classmethod
    def normalize_gender(cls, v: Optional[str]):
        if v is None: return None
        v_clean = v.strip().lower()
        allowed_genders = ["male", "female", "other", "prefer_not_to_say"]
        if v_clean not in allowed_genders:
            raise ValueError(f"Giới tính không hợp lệ. Phải là một trong: {allowed_genders}")
        return v_clean

# ====================================================================
# Models cho Đăng nhập (Sign In)
# ====================================================================
class SignInInput(BaseModel):
    email: EmailStr
    password: str
    device_token: Optional[str] = None

class UserInfo(BaseModel):
    id: str 
    email: EmailStr

class SignInResponse(BaseModel):
    message: str
    access_token: str
    refresh_token: str
    device_token: Optional[str] = None
    user: UserInfo

# Dùng nội bộ trong Service
class SignInServiceResponse(BaseModel):
    session: Any 
    user: Any
    class Config:
        arbitrary_types_allowed = True

# ====================================================================
# Models cho "Đổi vé" (Refresh Token)
# ====================================================================
class RefreshInput(BaseModel):
    refresh_token: str = Field(..., min_length=1, max_length=4096)

class RefreshResponse(BaseModel):
    access_token: str
    refresh_token: str

# ====================================================================
# Model cho Sign Out
# ====================================================================
class SignOutResponse(BaseModel):
    message: str

class ChangePasswordInput(BaseModel):
    new_password: str = Field(..., min_length=6, description="Mật khẩu mới")