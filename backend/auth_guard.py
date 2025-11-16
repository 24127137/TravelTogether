from fastapi import Depends, HTTPException
from fastapi.security import APIKeyHeader 
from config import settings
from supabase import create_client, Client
from typing import Any

# ====================================================================
# "NGƯỜI BẢO VỆ" (Security Guard) (GĐ 8.5 - Thêm giới hạn độ dài)
# ====================================================================

# Khởi tạo client Supabase
try:
    supabase_guard_client: Client = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
    print("Đã khởi tạo Supabase Auth client (cho auth_guard) thành công.")
except Exception as e:
    print(f"LỖI: Không thể khởi tạo Supabase Auth client (trong auth_guard): {e}")
    supabase_guard_client = None

# 1. ĐỊNH NGHĨA "NƠI LẤY VÉ"
api_key_scheme = APIKeyHeader(
    name="Authorization", 
    description="Dán 'Bearer <token>' vào đây (Ví dụ: Bearer eyJ...)",
    auto_error=False 
)

async def get_current_user(
    token_str: str = Depends(api_key_scheme) 
) -> Any:
    """
    "Người Bảo vệ" (Dependency)
    Nhiệm vụ: Lấy "vé" (token) từ ô "Authorization", kiểm tra nó.
    """
    if not supabase_guard_client:
        raise HTTPException(status_code=500, detail="Supabase client chưa được khởi tạo")
    
    # 2. KIỂM TRA "VÉ" (TOKEN) CÓ RỖNG KHÔNG
    if not token_str:
        raise HTTPException(
            status_code=401, 
            detail="Chưa cung cấp token (Header 'Authorization')"
        )
    
    # === THÊM MỚI (GĐ 8.5): Chặn lỗi (Vấn đề 3) token siêu dài ===
    # Header "Authorization" (bao gồm "Bearer ") không bao giờ
    # được dài hơn 8192 ký tự.
    if len(token_str) > 8192:
        raise HTTPException(
            status_code=413, # 413 Payload Too Large
            detail="Header 'Authorization' quá dài."
        )
    # ======================================================

    # 3. KIỂM TRA ĐỊNH DẠNG "Bearer <token>"
    if not token_str.startswith("Bearer "):
         raise HTTPException(
            status_code=401, 
            detail="Token phải có định dạng 'Bearer <token>'"
        )
        
    # 4. TÁCH LẤY TOKEN THẬT
    real_token = token_str.split(" ")[1]
    
    try:
        # 5. "Bảo vệ" gọi Supabase Auth: "Kiểm tra cái 'vé' (token) này"
        user_response = supabase_guard_client.auth.get_user(real_token)
        
        user = user_response.user
        
        if not user:
             raise HTTPException(status_code=401, detail="Token hợp lệ nhưng không tìm thấy user")
        
        # 6. "Bảo vệ" trả về đối tượng User (chứa UUID, email...)
        return user
        
    except Exception as e:
        # 7. XỬ LÝ "VÉ HẾT HẠN"
        print(f"LỖI BẢO MẬT (auth_guard): {e}")
        raise HTTPException(
            status_code=401, # 401 Unauthorized
            detail="Token không hợp lệ hoặc đã hết hạn"
        )