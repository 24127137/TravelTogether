from sqlmodel import Session, select
from typing import List, Dict, Any
# SỬA ĐỔI (GĐ 5): Import thêm ProfileUpdate
from models import Profiles, Destination, ProfileCreate, RecommendationOutput, EmailStr, ProfileUpdate
import ai_service # Import file AI service
import traceback
from config import settings # Import config để lấy Supabase keys
from supabase import create_client, Client
from typing import Any # <-- Sửa lỗi GĐ 4.8

# ====================================================================
# KHỞI TẠO (GĐ 4.4): Tạo 1 client Supabase
# ====================================================================
try:
    supabase: Client = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
    print("Đã khởi tạo Supabase Auth client (cho services.py) thành công.")
except Exception as e:
    print(f"LỖI: Không thể khởi tạo Supabase Auth client (trong services.py): {e}")
    supabase = None

# ====================================================================
# SỬA ĐỔI (GĐ 4.6): Quay lui về logic GĐ 4.4 (Đăng ký Trực tiếp)
# ====================================================================
async def create_profile_service(session: Session, profile_data: ProfileCreate) -> Profiles:
    """
    (Logic GĐ 4.4 - Luồng Đăng ký Trực tiếp)
    1. Nhận email/password/profile.
    2. Tạo user trong Supabase Auth (và tự động xác nhận).
    3. Lấy UUID mới.
    4. Tạo user trong bảng 'profiles' (public).
    """
    if not supabase:
        raise Exception("Supabase Auth client chưa được khởi tạo.")
        
    print(f"Đang tạo profile (GĐ 4.4 - Trực tiếp) cho: {profile_data.email}")
    
    auth_user_id = None
    
    try:
        # === VIỆC A: TẠO AUTH USER ===
        print(f"Việc A: Đang gọi Supabase Auth để tạo user cho: {profile_data.email}")
        auth_response = supabase.auth.sign_up({
            "email": profile_data.email,
            "password": profile_data.password,
            # Bỏ qua "options.data"
            # Bỏ qua việc gửi email xác nhận (nếu bạn đã TẮT "Confirm email" trong Supabase)
        })
        
        # Lấy auth_user_id (UUID)
        auth_user_id = auth_response.user.id
        print(f"Việc A: Tạo Auth user thành công. UUID mới: {auth_user_id}")

        # === VIỆC C: TẠO PROFILE (Ngay lập tức) ===
        print(f"Việc C: Đang tạo profile trong bảng 'public.profiles'")
        
        # 1. Chuyển Pydantic sang dict, *loại bỏ* 'password'
        profile_dict = profile_data.model_dump(exclude={"password"})
        
        # 2. Thêm 'auth_user_id' (UUID) mà chúng ta vừa nhận được
        profile_dict["auth_user_id"] = str(auth_user_id) # Đảm bảo là string
        
        # 3. Tạo SQLModel từ dict (model 'Profiles' mới đã có 'fullname')
        db_profile = Profiles.model_validate(profile_dict)
        
        session.add(db_profile)
        session.commit()
        session.refresh(db_profile)
        
        print(f"Việc C: Tạo profile thành công, ID: {db_profile.id}")
        return db_profile
        
    except Exception as e:
        print(f"LỖI khi tạo profile GĐ 4.4: {e}")
        traceback.print_exc()
        session.rollback()
        
        # [QUAN TRỌNG] Rollback Auth: Nếu lưu profile lỗi, phải xóa Auth user đã tạo
        if auth_user_id:
            print(f"Rollback: Đang xóa Auth user (UUID: {auth_user_id}) do lỗi...")
            try:
                supabase.auth.admin.delete_user(auth_user_id)
                print("Rollback: Xóa Auth user thành công.")
            except Exception as admin_e:
                print(f"LỖI NGHIÊM TRỌNG KHI ROLLBACK: {admin_e}")
                
        raise e # Báo lỗi ra cho 'api.py' xử lý

# ====================================================================
# LOGIC GĐ 4.5: Tìm kiếm bằng EMAIL (Vẫn giữ nguyên)
# ====================================================================
async def get_ranked_recommendations_service(session: Session, email: EmailStr) -> List[RecommendationOutput]:
    """
    (Logic GĐ 4.5)
    Thực hiện toàn bộ logic gợi ý (tìm bằng email).
    """
    try:
        # Bước 1: Tìm profile bằng EMAIL
        print(f"Bước 1: Tìm profile cho email '{email}'")
        statement_profile = select(Profiles).where(Profiles.email == email)
        profile = session.exec(statement_profile).first()
        
        if not profile:
            raise Exception(f"Profile cho email '{email}' not found.")
            
        user_interests = profile.interests
        user_city_pref = profile.preferred_city
        
        if not user_city_pref or not user_interests:
            raise Exception(f"Profile cho '{email}' is incomplete (missing interests or preferred_city).")

        print(f"Đã tìm thấy: Sở thích={user_interests}, Thành phố={user_city_pref}")

        # Bước 2: Lấy địa điểm (Không thay đổi)
        print(f"Bước 2: Lấy tất cả địa điểm tại '{user_city_pref}'")
        statement_dest = select(Destination).where(Destination.city == user_city_pref)
        destinations_in_city = session.exec(statement_dest).all()
        
        if not destinations_in_city:
            raise Exception(f"No destinations found in database for city '{user_city_pref}'.")

        print(f"Tìm thấy {len(destinations_in_city)} địa điểm. Chuẩn bị gọi AI...")

        # Bước 3: Gửi AI (Không thay đổi)
        ranked_list = await ai_service.rank_destinations_by_ai(
            user_interests=user_interests,
            destinations=destinations_in_city
        )
        
        return ranked_list

    except Exception as e:
        print(f"LỖI trong chuỗi logic gợi ý: {e}")
        traceback.print_exc()
        raise e

# ====================================================================
# THÊM MỚI (GĐ 5): Logic Lấy Profile (để test "Bảo vệ")
# ====================================================================
async def get_profile_by_uuid_service(session: Session, auth_user_id: str) -> Profiles:
    """
    (Logic GĐ 5)
    Tìm "tủ đồ" (profile) bằng "Số CCCD" (UUID).
    """
    print(f"Đang tìm profile cho auth_user_id: {auth_user_id}")
    
    statement = select(Profiles).where(Profiles.auth_user_id == auth_user_id)
    profile = session.exec(statement).first()
    
    if not profile:
        raise Exception("Profile không tồn tại (lỗi đồng bộ?)")
        
    return profile

# ====================================================================
# THÊM MỚI (GĐ 5): Logic Cập nhật Profile (tất tần tật)
# ====================================================================
async def update_profile_service(session: Session, auth_user_id: str, update_data: ProfileUpdate) -> Profiles:
    """
    (Logic GĐ 5)
    Cập nhật "tất tần tật" cho user (cả Auth và Profile).
    """
    if not supabase:
        raise Exception("Supabase Auth client chưa được khởi tạo.")
        
    print(f"Đang cập nhật profile (GĐ 5) cho auth_user_id: {auth_user_id}")

    # 1. Chuyển Pydantic model (ProfileUpdate) thành dict
    update_dict = update_data.model_dump(exclude_unset=True)
    
    if not update_dict:
        raise Exception("Không có thông tin nào để cập nhật.")

    # 2. Tách biệt 2 phần: Dữ liệu cho Auth và Dữ liệu cho Profile
    auth_updates = {}
    profile_updates = {}

    if "email" in update_dict:
        auth_updates["email"] = update_dict.pop("email")
    if "password" in update_dict:
        auth_updates["password"] = update_dict.pop("password")
        
    profile_updates = update_dict

    try:
        # === VIỆC A: CẬP NHẬT AUTH (Email/Password) ===
        if auth_updates:
            print(f"Đang cập nhật Auth (Email/Password) cho {auth_user_id}...")
            supabase.auth.admin.update_user_by_id(
                auth_user_id, 
                auth_updates
            )
            print("Cập nhật Auth thành công.")

        # === VIỆC B: CẬP NHẬT PROFILE (Fullname/Interests...) ===
        statement = select(Profiles).where(Profiles.auth_user_id == auth_user_id)
        profile_to_update = session.exec(statement).first()
        
        if not profile_to_update:
            raise Exception("Không tìm thấy profile để cập nhật.")
        
        if profile_updates:
            print(f"Đang cập nhật Profile (Fullname/Interests...) cho {auth_user_id}...")
            for key, value in profile_updates.items():
                setattr(profile_to_update, key, value)
            
            session.add(profile_to_update)
            session.commit()
            session.refresh(profile_to_update)
            print("Cập nhật Profile thành công.")

        return profile_to_update

    except Exception as e:
        print(f"LỖI khi cập nhật profile GĐ 5: {e}")
        traceback.print_exc()
        session.rollback()
        raise e