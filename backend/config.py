from pydantic_settings import BaseSettings, SettingsConfigDict
import os

class Settings(BaseSettings):
    """
    Quản lý biến môi trường.
    Tự động đọc từ file ..env (khi chạy local) hoặc Environment Variables (khi chạy trên Render).
    """
    # Khai báo tên biến (KHÔNG điền giá trị mặc định để bảo mật)
    DATABASE_URL: str
    GEMINI_API_KEY: str
    SUPABASE_URL: str
    SUPABASE_KEY: str
    
    # Cấu hình để tự động tìm và đọc file ..env
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

# Khởi tạo settings
settings = Settings()