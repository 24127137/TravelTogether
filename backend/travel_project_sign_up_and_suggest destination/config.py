from pydantic_settings import BaseSettings, SettingsConfigDict
import os

class Settings(BaseSettings):
    """
    Quản lý tất cả các biến môi trường và "bí mật" (secrets)
    """
    
    # === 1. DÁN CHUỖI KẾT NỐI DATABASE (cho SQLModel) ===
    DATABASE_URL: str = "postgresql://postgres:ntcuong2413@db.meuqntvawakdzntewscp.supabase.co:5432/postgres"
    
    # === 2. DÁN API KEY CỦA GEMINI (cho AI) ===
    GEMINI_API_KEY: str = "AIzaSyCxRKOBWI5rw2OcPA9EO1TzearcKiyzU10"
    
    # === 3. DÁN SUPABASE URL (MỚI - CẦN CHO AUTH) ===
    SUPABASE_URL: str = "https://meuqntvawakdzntewscp.supabase.co"
    
    # === 4. DÁN SUPABASE KEY (MỚI - CẦN CHO AUTH) ===
    SUPABASE_KEY: str = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1ldXFudHZhd2FrZHpudGV3c2NwIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTYzNTE5MSwiZXhwIjoyMDc3MjExMTkxfQ.C0brrSJsZZayMEJLDt4nGgnB0lvkOqLZ2hCOFbXTrec"
    
    
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

# Tạo một instance duy nhất của Settings
settings = Settings()