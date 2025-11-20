from pydantic import BaseModel, EmailStr, Field
# === SỬA ĐỔI (GĐ 8.6): Import validator MỚI của Pydantic V2 ===
from pydantic import field_validator, ValidationInfo
from typing import Dict, Any, Optional, List

# ====================================================================
# Model cho Đăng Ký (Sign Up)
# ====================================================================
class ProfileCreate(BaseModel):
    """
    (Đã cập nhật GĐ 8.6: Sửa lỗi Pydantic V2)
    Dữ liệu (JSON) mà API /auth/signup mong đợi nhận vào
    """
    email: EmailStr
    password: str = Field(min_length=6)
    
    fullname: Optional[str] = None
    gender: Optional[str] = None
    interests: List[str]
    preferred_city: str

    # === SỬA ĐỔI (GĐ 8.6): Dùng cú pháp Pydantic V2 ===
    @field_validator("email", "password")
    @classmethod
    def validate_no_spaces(cls, v: str, info: ValidationInfo):
        """Kiểm tra xem email và password có chứa dấu cách không"""
        if " " in v:
            # Dùng info.field_name thay cho field.alias
            raise ValueError(f"{info.field_name} không được phép chứa dấu cách")
        return v
    # ===============================================

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
    (Đã cập nhật GĐ 8.5: Thêm validation độ dài)
    Dữ liệu (JSON) mà API /auth/refresh mong đợi nhận vào
    """
    refresh_token: str = Field(
        ..., 
        min_length=1, 
        max_length=4096, # Chặn lỗi rỗng và siêu dài
        examples=["eyJ..."]
    )

class RefreshResponse(BaseModel):
    """
    Dữ liệu (JSON) mà API /auth/refresh trả về
    """
    access_token: str
    refresh_token: str