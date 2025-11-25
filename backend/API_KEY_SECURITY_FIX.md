# 🔐 BẢO MẬT API KEY - HƯỚNG DẪN KHẮC PHỤC

## ⚠️ VẤN ĐỀ
API Key của Gemini đã bị leak (lộ ra công cộng) và Google đã vô hiệu hóa nó vì lý do bảo mật.

## ✅ GIẢI PHÁP

### Bước 1: Tạo API Key mới
1. Truy cập: https://aistudio.google.com/app/apikey
2. Đăng nhập với tài khoản Google của bạn
3. Nhấn **"Create API Key"**
4. Copy API key mới (chỉ hiển thị 1 lần!)

### Bước 2: Cập nhật file `.env`
1. Mở file `backend/.env`
2. Tìm dòng: `GEMINI_API_KEY=YOUR_NEW_GEMINI_API_KEY_HERE`
3. Thay `YOUR_NEW_GEMINI_API_KEY_HERE` bằng API key mới của bạn
4. Lưu file

### Bước 3: Khởi động lại server
```powershell
cd backend
python main.py
```

## 🛡️ BẢO MẬT ĐÃ ĐƯỢC CẢI THIỆN

✅ **ĐÃ LÀM:**
- ✅ Xóa API key hardcode khỏi `config.py`
- ✅ Tạo file `.env` để lưu secrets
- ✅ Thêm `.env` vào `.gitignore` (không commit lên Git)
- ✅ Tạo `.env.example` làm template

✅ **QUY TẮC BẢO MẬT:**
- ❌ KHÔNG BAO GIỜ commit file `.env` lên Git
- ❌ KHÔNG BAO GIỜ hardcode API key vào code
- ✅ CHỈ lưu API key trong file `.env`
- ✅ CHỈ commit file `.env.example` (không chứa key thật)

## 📝 LƯU Ý
- File `.env` chỉ tồn tại trên máy local của bạn
- Mỗi developer cần tự tạo file `.env` riêng
- Nếu deploy lên server, cần cấu hình environment variables trên server

## 🔄 NẾU VẪN GẶP LỖI
Nếu sau khi đổi key mới vẫn bị lỗi 403:
1. Kiểm tra API key có đúng không
2. Kiểm tra quota của Gemini API (có thể đã hết free tier)
3. Kiểm tra billing trong Google Cloud Console

