### Bước 1: Cài đặt các thư viện (6 thư viện)

Mở terminal của bạn và chạy 6 lệnh sau:
```bash
# 1. Server FastAPI
pip install fastapi "uvicorn[standard]"

# 2. Thư viện Database (Nói chuyện với Supabase)
pip install sqlmodel psycopg2-binary

# 3. Thư viện AI (Nói chuyện với Google Gemini)
pip install google-generativeai

# 4. Thư viện Config (Đọc "bí mật" từ file)
pip install pydantic-settings

# 5. THƯ VIỆN MỚI: Dùng để gọi Supabase Auth (Tạo user)
pip install supabase
# (Lệnh này có nghĩa là: "Hãy cài pydantic, và cài thêm các gói phụ trợ [extras] cần thiết cho việc validate email").
pip install "pydantic[email]"

