from fastapi import FastAPI
from contextlib import asynccontextmanager
from api import router as api_router # <-- Import router từ file api.py
from fastapi.middleware.cors import CORSMiddleware # <-- Import CORS

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Sự kiện chạy khi server khởi động"""
    print("Server đang khởi động (Phiênbản 4.5 - Luồng Email)...")
    print("Đã sẵn sàng kết nối database...")
    yield
    print("Server đang tắt...")

# 1. Tạo app
app = FastAPI(
    title="Travel Recommender API",
    description="API cho Ứng dụng Du lịch (Phiênbản 4.5 - Luồng Email)",
    version="4.5.0",
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

# 2. "Bao gồm" tất cả các API endpoints từ file api.py
app.include_router(api_router)

# Hoàn thành!
# Để chạy, dùng: uvicorn main:app --reload