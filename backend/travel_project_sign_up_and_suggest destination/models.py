from sqlmodel import SQLModel, Field, Column
from pydantic import BaseModel, EmailStr # Import EmailStr để validate
from typing import List, Optional, Any, Dict
# Đã sửa lỗi NameError: Thêm ARRAY
from sqlalchemy.dialects.postgresql import TEXT, UUID, JSONB, DATERANGE, ARRAY

# ====================================================================
# LỚP SQLModel: Đại diện cho BẢNG trong Database
# (Khớp 100% với file build_profiles_v4.5.sql của bạn)
# ====================================================================

class Profiles(SQLModel, table=True):
    """
    Model cho bảng 'profiles' (Thiết kế "Tất cả trong một")
    """
    id: Optional[int] = Field(default=None, primary_key=True)
    
    # === THAY ĐỔI GĐ 4.5 ===
    fullname: Optional[str] = None # Họ và Tên (gộp)
    
    # Thông tin tài khoản (KHÔNG CÓ MẬT KHẨU)
    auth_user_id: str = Field(sa_column=Column(UUID(as_uuid=False), unique=True))
    email: str = Field(sa_column=Column(TEXT, unique=True, index=True)) # Email là key mới
    # username: ĐÃ BỎ
    
    # Thông tin cá nhân
    gender: Optional[str] = None # Sẽ được DB validate bằng gender_enum
    
    # Thông tin gợi ý (Từ mô tả của bạn)
    interests: Optional[List[str]] = Field(default=None, sa_column=Column(ARRAY(TEXT))) # Sở thích
    preferred_city: Optional[str] = Field(default=None) # Địa điểm đi du lịch
    
    # Thông tin chuyến đi (Từ mô tả của bạn)
    travel_dates: Optional[Any] = Field(default=None, sa_column=Column(DATERANGE)) # thời gian đi du lịch
    itinerary: Optional[Dict[str, Any]] = Field(default=None, sa_column=Column(JSONB)) # lộ trình du lịch
    
    # Thông tin nhóm (JSONB) (Từ mô tả của bạn)
    owned_groups: Optional[List[Dict[str, Any]]] = Field(default=None, sa_column=Column(JSONB)) # nhóm đang tạo
    joined_groups: Optional[List[Dict[str, Any]]] = Field(default=None, sa_column=Column(JSONB)) # nhóm đang tham gia
    pending_requests: Optional[List[Dict[str, Any]]] = Field(default=None, sa_column=Column(JSONB)) # nhóm đang gửi request
    
    # created_at: SQLModel sẽ tự xử lý vì DB có DEFAULT NOW()

class Destination(SQLModel, table=True):
    """
    Model cho bảng 'destination' (Khớp 100% với DB của bạn)
    """
    id: Optional[int] = Field(default=None, primary_key=True)
    city: str
    location_name: str = Field(sa_column=Column(TEXT, unique=True))
    description: str

# ====================================================================
# LỚP Pydantic: Đại diện cho DỮ LIỆU API (Input/Output)
# ====================================================================

class ProfileCreate(BaseModel):
    """
    (ĐÃ SỬA GĐ 4.5)
    Dữ liệu (JSON) mà API /create-profile mong đợi nhận vào
    Bây giờ nhận email/password/fullname, không nhận username
    """
    email: EmailStr # Dùng EmailStr để Pydantic tự validate
    password: str = Field(min_length=6) # Supabase yêu cầu tối thiểu 6
    
    # Các thông tin profile khác
    fullname: Optional[str] = None
    gender: Optional[str] = None # Ví dụ: "male", "female", "other"
    interests: List[str]
    preferred_city: str # "Địa điểm đi du lịch"

    class Config:
        json_schema_extra = {
            "example": {
                "email": "cuong_final_v2@example.com",
                "password": "PasswordCucManh123!",
                "fullname": "Nguyễn Văn Cường",
                "gender": "male",
                "interests": ["biển", "ẩm thực", "sôi động", "náo nhiệt", "chụp ảnh"],
                "preferred_city": "Đà Nẵng"
            }
        }

class RecommendationOutput(BaseModel):
    """
    Dữ liệu (JSON) mà AI sẽ trả về, và cũng là output của API
    (ĐÃ SỬA: Bỏ "reasoning" theo yêu cầu)
    """
    location_name: str
    score: int # Điểm tương thích, ví dụ: 90
    
    class Config:
        json_schema_extra = {
            "example": {
                "location_name": "Biển Mỹ Khê",
                "score": 95
            }
        }