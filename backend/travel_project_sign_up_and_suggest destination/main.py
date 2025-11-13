from fastapi import FastAPI
from contextlib import asynccontextmanager
from api import router as api_router # <-- Import router CŨ (profile, recommend)
from auth_api import router as auth_router # <-- Import router CŨ (signin, refresh)
from profile_api import router as profile_router # <-- Import router MỚI (users/me)
from fastapi.middleware.cors import CORSMiddleware 

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Sự kiện chạy khi server khởi động"""
    print("Server đang khởi động (Phiênbản 5.0 - Đăng ký Trực tiếp + Bảo vệ)...")
    print("Đã sẵn sàng kết nối database...")
    yield
    print("Server đang tắt...")

# 1. Tạo app
app = FastAPI(
    title="Travel Recommender API",
    description="API cho Ứng dụng Du lịch (Phiênbản 5.0 - Đăng ký Trực tiếp + Bảo vệ)",
    version="5.0.0",
    lifespan=lifespan
)

# === THÊM CODE CHO CORS (Để Frontend gọi được) ===
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Cho phép TẤT CẢ
    allow_credentials=True,
    allow_methods=["*"], # Cho phép POST, GET, v.v.
    allow_headers=["*"],
)
# =================================================

# 2. "Bao gồm" (Cắm) tất cả các API endpoints
app.include_router(api_router) # Cắm API (profile, recommend)
app.include_router(auth_router) # CẮM API (signin, refresh)
app.include_router(profile_router) # <-- CẮM API MỚI (users/me, profiles/me)

# Hoàn thành!
# Để chạy, dùng: uvicorn main:app --reload