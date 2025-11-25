from pydantic import BaseModel, EmailStr, Field, field_validator, ValidationInfo
from typing import Dict, Any, Optional, List

# ====================================================================
# Model cho Đăng Ký (Sign Up)
# ====================================================================
class ProfileCreate(BaseModel):
    """
    (Đã cập nhật: Fix lỗi ENUM Gender)
    Dữ liệu (JSON) mà API /auth/signup mong đợi nhận vào
    """
    email: EmailStr
    password: str = Field(min_length=6)
    
    fullname: Optional[str] = None
    gender: Optional[str] = None # Input có thể là "Male", "FEMALE"...
    interests: List[str]
    preferred_city: str

    # --- VALIDATOR 1: Kiểm tra dấu cách (Giữ nguyên) ---
    @field_validator("email", "password")
    @classmethod
    def validate_no_spaces(cls, v: str, info: ValidationInfo):
        if " " in v:
            raise ValueError(f"{info.field_name} không được phép chứa dấu cách")
        return v

    # --- VALIDATOR 2: CHUẨN HÓA GENDER (FIX LỖI ENUM) ---
    @field_validator("gender", mode='before')
    @classmethod
    def normalize_gender(cls, v: Optional[str]):
        """
        Chuyển đổi mọi định dạng đầu vào thành chữ thường chuẩn Database.
        Ví dụ: "Male" -> "male", "  FEMALE " -> "female"
        """
        if v is None:
            return None
        
        # 1. Cắt khoảng trắng và viết thường
        v_clean = v.strip().lower()
        
        # 2. Danh sách cho phép (Khớp với Database Enum)
        allowed_genders = ["male", "female", "other", "prefer_not_to_say"]
        
        if v_clean not in allowed_genders:
            raise ValueError(f"Giới tính không hợp lệ. Phải là một trong: {allowed_genders}")
            
        return v_clean

    class Config:
        json_schema_extra = {
            "example": {
                "email": "cuong_final_v4@example.com",
                "password": "PasswordCucManh123!",
                "fullname": "Nguyễn Văn Cường",
                "gender": "Male", # Thử nhập viết hoa để test
                "interests": ["biển", "ẩm thực"],
                "preferred_city": "Đà Nẵng"
            }
        }

# ====================================================================
# Models cho Đăng nhập (Sign In)
# ====================================================================
class SignInInput(BaseModel):
    email: EmailStr
    password: str

class UserInfo(BaseModel):
    id: str # UUID
    email: EmailStr

class SignInResponse(BaseModel):
    message: str
    access_token: str
    refresh_token: str
    user: UserInfo

# ====================================================================
# Models cho "Đổi vé" (Refresh Token)
# ====================================================================
class RefreshInput(BaseModel):
    refresh_token: str = Field(..., min_length=1, max_length=4096)

class RefreshResponse(BaseModel):
    access_token: str
    refresh_token: str