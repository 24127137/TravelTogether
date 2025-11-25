from pydantic_settings import BaseSettings, SettingsConfigDict
import os

class Settings(BaseSettings):
    """
    Quản lý tất cả các biến môi trường và "bí mật" (secrets)
    ĐỌC TỪ FILE .env - KHÔNG BAO GIỜ HARDCODE TRỰC TIẾP!
    """
    
    # === 1. CHUỖI KẾT NỐI DATABASE (cho SQLModel) ===
    DATABASE_URL: str

    # === 2. API KEY CỦA GEMINI (cho AI) ===
    GEMINI_API_KEY: str

    # === 3. SUPABASE URL (CHO AUTH) ===
    SUPABASE_URL: str

    # === 4. SUPABASE KEY (CHO AUTH) ===
    SUPABASE_KEY: str

    
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

# Tạo một instance duy nhất của Settings
settings = Settings()