from fastapi import Depends, HTTPException, Request
from fastapi.security import APIKeyHeader 
from config import settings
from supabase import create_client, Client
from typing import Any
import hashlib
import json
import base64
from sqlmodel import Session, select
from database import engine 
from db_tables import TokenSecurity 

# Khởi tạo client Supabase
try:
    supabase_guard_client: Client = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
    print("Đã khởi tạo Supabase Auth client (cho auth_guard) thành công.")
except Exception as e:
    print(f"LỖI: Không thể khởi tạo Supabase Auth client (trong auth_guard): {e}")
    supabase_guard_client = None

api_key_scheme = APIKeyHeader(
    name="Authorization", 
    description="Bearer <token>",
    auto_error=False 
)

def hash_token(token: str) -> str:
    """Băm token để so sánh với DB"""
    return hashlib.sha256(token.encode()).hexdigest()

def get_user_id_from_token(token: str) -> str:
    """Giải mã nhanh JWT lấy UUID (sub)"""
    try:
        parts = token.split(".")
        if len(parts) < 2: return None
        payload = parts[1]
        payload += "=" * ((4 - len(payload) % 4) % 4) 
        decoded = base64.urlsafe_b64decode(payload)
        return json.loads(decoded).get("sub")
    except Exception:
        return None

async def get_current_user(
    request: Request,
    token_str: str = Depends(api_key_scheme) 
) -> Any:
    """
    Guard V3: White-list Only + IP Protection
    """
    if not supabase_guard_client:
        raise HTTPException(status_code=500, detail="Supabase client lỗi")
    
    if not token_str or not token_str.startswith("Bearer "):
         raise HTTPException(status_code=401, detail="Token không hợp lệ")
        
    real_token = token_str.split(" ")[1]
    token_hash = hash_token(real_token)
    
    # 1. LẤY UUID NHANH
    user_uuid = get_user_id_from_token(real_token)
    if not user_uuid:
        raise HTTPException(status_code=401, detail="Token lỗi cấu trúc")

    client_ip = request.client.host

    # 2. KIỂM TRA DB (WHITELIST)
    with Session(engine) as session:
        active = session.exec(select(TokenSecurity).where(TokenSecurity.user_id == user_uuid)).first()
        
        # A. Nếu không có trong DB -> Chưa đăng nhập hoặc Đã SignOut
        if not active:
             raise HTTPException(status_code=401, detail="Phiên đăng nhập không tồn tại (Vui lòng đăng nhập lại).")

        # B. Nếu Hash khác -> Token cũ (Đăng nhập máy khác)
        if active.token_signature != token_hash:
             raise HTTPException(status_code=401, detail="Phiên hết hạn (Tài khoản đang được dùng ở nơi khác).")
        
        # C. Nếu Hash khớp nhưng IP khác -> IP Mismatch (Hack)
        if active.ip_address != client_ip:
            print(f"SECURITY: User {user_uuid} đổi IP đột ngột. Gốc: {active.ip_address}, Mới: {client_ip}")
            
            # Xóa session ngay lập tức để chặn
            session.delete(active)
            session.commit()
            
            raise HTTPException(status_code=401, detail="Phát hiện IP bất thường. Phiên đã bị hủy để bảo vệ tài khoản.")

    # 3. GỌI SUPABASE AUTH (Verify Expiration & Signature)
    try:
        user_response = supabase_guard_client.auth.get_user(real_token)
        return user_response.user
    except Exception:
        raise HTTPException(status_code=401, detail="Token hết hạn")