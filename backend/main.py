from fastapi import FastAPI
from contextlib import asynccontextmanager
# Import các API đã tách
from auth_api import router as auth_router
from user_api import router as user_router
from recommend_api import router as recommend_router
from chat_api import router as chat_router
# === THÊM MỚI (GĐ 11): Import API Nhóm ===
from group_api import router as group_router
from chat_ai_api import router as ai_chat_router
# ========================================
from fastapi.middleware.cors import CORSMiddleware 

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Sự kiện chạy khi server khởi động"""
    print("Server đang khởi động (Phiên bản 11.0 - UUID Toàn diện)...")
    print("Đã sẵn sàng kết nối database...")
    yield
    print("Server đang tắt...")

# 1. Tạo app
app = FastAPI(
    title="Travel Recommender API",
    description="API cho Ứng dụng Du lịch (Phiênbản 11.0 - UUID Toàn diện)",
    version="11.0.0",
    lifespan=lifespan
)

# 2. Cấu hình CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"], 
    allow_headers=["*"],
)

# 3. "Bao gồm" (Cắm) tất cả các API endpoints
app.include_router(auth_router) # Cắm API (Auth)
app.include_router(user_router) # Cắm API (User)
app.include_router(recommend_router) # Cắm API (Recommend)
app.include_router(group_router) # Cắm API (Group)
app.include_router(chat_router) # Cắm API (Chat)
app.include_router(ai_chat_router) # API (AI Chat)

# Hoàn thành!
# Để chạy, dùng: uvicorn main:app --reload