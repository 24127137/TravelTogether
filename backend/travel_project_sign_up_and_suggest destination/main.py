from fastapi import FastAPI
from contextlib import asynccontextmanager
# Import các API đã tách
from auth_api import router as auth_router
from user_api import router as user_router
from recommend_api import router as recommend_router
from fastapi.middleware.cors import CORSMiddleware 

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Sự kiện chạy khi server khởi động"""
    print("Server đang khởi động (Phiên bản 8.1 - Refactor hoàn chỉnh)...")
    print("Đã sẵn sàng kết nối database...")
    yield
    print("Server đang tắt...")

# 1. Tạo app
app = FastAPI(
    title="Travel Recommender API",
    description="API cho Ứng dụng Du lịch (Phiênbản 8.1 - Refactor hoàn chỉnh)",
    version="8.1.0",
    lifespan=lifespan
)

# 2. Cấu hình CORS (Để Frontend gọi được)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Cho phép TẤT CẢ
    allow_credentials=True,
    allow_methods=["*"], # Cho phép POST, GET, v.v.
    allow_headers=["*"],
)

# 3. "Bao gồm" (Cắm) tất cả các API endpoints
app.include_router(auth_router) # Cắm API (Đăng ký, Đăng nhập)
app.include_router(user_router) # Cắm API (Lấy/Sửa Profile)
app.include_router(recommend_router) # Cắm API (Lấy Gợi ý)
# (Chúng ta sẽ cắm router_group.py ở đây trong tương lai)

# Hoàn thành!
# Để chạy, dùng: uvicorn main:app --reload