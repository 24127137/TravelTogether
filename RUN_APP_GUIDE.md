# 🚀 Hướng Dẫn Chạy Ứng Dụng Travel Together

## 📋 Mục lục
1. [Yêu cầu hệ thống](#yêu-cầu-hệ-thống)
2. [Cài đặt Backend](#cài-đặt-backend)
3. [Cài đặt Frontend](#cài-đặt-frontend)
4. [Chạy ứng dụng](#chạy-ứng-dụng)
5. [Xử lý lỗi thường gặp](#xử-lý-lỗi-thường-gặp)

---

## ✅ Yêu cầu hệ thống

### Backend
- **Python**: 3.9 trở lên
- **pip**: Phiên bản mới nhất
- **Windows PowerShell** (để chạy script)

### Frontend
- **Flutter SDK**: 3.0 trở lên
- **Android Studio** hoặc **VS Code**
- **Android Device/Emulator** (Android 5.0+)

### Mạng
- **WiFi**: Thiết bị Android và máy tính phải cùng mạng WiFi
- **Firewall**: Cho phép kết nối port 8000

---

## 🔧 Cài đặt Backend

### Bước 1: Cài đặt dependencies

```powershell
cd D:\TDTT TRAVEL PROJECT\my_travel_app\TravelTogether\backend
pip install -r requirements.txt
```

### Bước 2: Kiểm tra file cấu hình

File `config.py` phải có thông tin Supabase hợp lệ:
```python
SUPABASE_URL = "https://meuqntvawakdzntewscp.supabase.co"
SUPABASE_KEY = "eyJhbGci..."
```

---

## 📱 Cài đặt Frontend

### Bước 1: Cài đặt Flutter packages

```powershell
cd D:\TDTT TRAVEL PROJECT\my_travel_app\TravelTogether\frontend
flutter pub get
```

### Bước 2: Cấu hình IP Server

1. **Lấy IP của máy tính:**
   ```powershell
   ipconfig
   ```
   Tìm dòng `IPv4 Address` (ví dụ: `10.132.240.17`)

2. **Cập nhật IP trong code:**
   
   Mở file `lib/config/api_config.dart`:
   ```dart
   static const String baseUrl = 'http://10.132.240.17:8000';
   ```
   
   Thay `10.132.240.17` bằng IP thực tế của máy bạn.

---

## 🏃 Chạy ứng dụng

### 1️⃣ Khởi động Backend

```powershell
cd D:\TDTT TRAVEL PROJECT\my_travel_app\TravelTogether\backend
.\run_server.bat
```

**Kết quả mong đợi:**
```
=== Khởi động Backend Travel Together ===
Backend sẽ lắng nghe trên 0.0.0.0:8000 (cho phép thiết bị Android kết nối)

Khởi động server...
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
INFO:     Started reloader process [12788] using WatchFiles
Đã khởi tạo Supabase Auth client (cho auth_service) thành công.
Đã khởi tạo Supabase client (cho user_service) thành công.
INFO:     Started server process [10104]
INFO:     Waiting for application startup.
Server đang khởi động (Phiên bản 11.0 - UUID Toàn diện)...
Đã sẵn sàng kết nối database...
INFO:     Application startup complete.
```

✅ Nếu thấy `Application startup complete.` → Backend đã sẵn sàng!

### 2️⃣ Kết nối thiết bị Android

**Qua USB:**
```powershell
# Kiểm tra thiết bị đã kết nối
flutter devices
```

**Qua WiFi (không cần dây):**
1. Kết nối thiết bị qua USB lần đầu
2. Chạy:
   ```powershell
   adb tcpip 5555
   adb connect <IP_THIẾT_BỊ>:5555
   ```
3. Rút dây USB ra

### 3️⃣ Chạy Frontend

```powershell
cd D:\TDTT TRAVEL PROJECT\my_travel_app\TravelTogether\frontend
flutter run
```

**Hoặc từ Android Studio:**
1. Mở project `frontend`
2. Chọn thiết bị
3. Nhấn nút Run (▶️)

---

## 🐛 Xử lý lỗi thường gặp

### ❌ Lỗi: "Connection refused" khi đăng ký/đăng nhập

**Nguyên nhân:** App không kết nối được đến backend

**Giải pháp:**

1. **Kiểm tra backend có chạy không:**
   ```powershell
   # Kiểm tra xem port 8000 có đang được sử dụng không
   netstat -ano | findstr :8000
   ```

2. **Kiểm tra IP trong code:**
   - Mở `lib/config/api_config.dart`
   - Đảm bảo IP đúng với IP máy tính (dùng `ipconfig` để check)

3. **Kiểm tra firewall:**
   ```powershell
   # Mở PowerShell với quyền Admin và chạy:
   cd D:\TDTT TRAVEL PROJECT\my_travel_app\TravelTogether\backend
   .\open_firewall.ps1
   ```

4. **Kiểm tra thiết bị và máy tính cùng WiFi:**
   - Vào Settings → WiFi trên Android
   - Xem IP của thiết bị (phải cùng dải với máy tính)
   - Ví dụ: Máy `10.132.240.17` và điện thoại `10.132.240.xx`

### ❌ Lỗi: "Server error '556'"

**Nguyên nhân:** Lỗi từ Supabase khi đăng ký

**Có thể do:**
- Email đã tồn tại → Thử email khác
- Mật khẩu quá yếu → Dùng mật khẩu ít nhất 8 ký tự, có chữ và số
- Supabase API key hết hạn → Liên hệ admin

**Giải pháp:**
1. Thử email khác
2. Dùng mật khẩu mạnh hơn (ví dụ: `Test123456`)
3. Kiểm tra log backend để xem lỗi chi tiết

### ❌ Lỗi: "Không tải được lịch sử chat"

**Nguyên nhân:** Chưa tham gia nhóm nào

**Giải pháp:**
1. Tạo một nhóm mới
2. Hoặc tham gia một nhóm có sẵn
3. Sau đó mới có thể chat

### ❌ Lỗi: "Session expired"

**Nguyên nhân:** Access token hết hạn

**Giải pháp:**
1. Đăng xuất
2. Đăng nhập lại

### ❌ Cần restart Android Studio không?

**Sau khi cài dependencies (pip install):**
- ❌ **KHÔNG** cần restart Android Studio
- ✅ Chỉ cần restart backend server (Ctrl+C rồi chạy lại `.\run_server.bat`)

**Sau khi cài Flutter packages:**
- ❌ **KHÔNG** cần restart Android Studio
- ✅ Nhưng nên:
  1. Stop app hiện tại
  2. Chạy `flutter pub get` lại
  3. Run app mới

---

## 📝 Checklist trước khi chạy

- [ ] Backend dependencies đã cài (`pip install -r requirements.txt`)
- [ ] Frontend dependencies đã cài (`flutter pub get`)
- [ ] IP trong `api_config.dart` đã cập nhật đúng
- [ ] Backend đang chạy (`.\run_server.bat`)
- [ ] Thiết bị Android đã kết nối và hiển thị trong `flutter devices`
- [ ] Thiết bị và máy tính cùng mạng WiFi
- [ ] Firewall đã mở cho port 8000

---

## 🎯 Luồng sử dụng cơ bản

1. **Đăng ký tài khoản mới:**
   - Nhập email, mật khẩu, tên, ngày sinh, giới tính
   - Chọn ít nhất 3 sở thích
   - Nhấn "Hoàn tất"

2. **Đăng nhập:** (nếu đã có tài khoản)
   - Nhập email và mật khẩu
   - Nhấn "Đăng nhập"

3. **Tạo/Tham gia nhóm:**
   - Vào tab "Personal"
   - Chọn "Create Group" hoặc "Join Group"

4. **Chat trong nhóm:**
   - Vào tab "Messages"
   - Chọn nhóm
   - Bắt đầu chat (tin nhắn tự động refresh mỗi 3 giây)

---

## 🔗 Tài liệu liên quan

- [CHAT_REALTIME_GUIDE.md](./CHAT_REALTIME_GUIDE.md) - Hướng dẫn chi tiết về chat realtime
- [backend/README.md](./backend/README.md) - Tài liệu Backend API
- [backend/FIX_CONNECTION.md](./backend/FIX_CONNECTION.md) - Sửa lỗi kết nối

---

## 💡 Tips

1. **Xem log backend:** Giúp debug lỗi
   - Log hiển thị ngay trong terminal khi chạy `.\run_server.bat`

2. **Xem API documentation:**
   - Mở trình duyệt: `http://localhost:8000/docs`
   - Hoặc: `http://<IP_MÁY_TÍNH>:8000/docs`

3. **Clear cache Flutter (nếu app lỗi lạ):**
   ```powershell
   flutter clean
   flutter pub get
   flutter run
   ```

4. **Kiểm tra kết nối server từ điện thoại:**
   - Mở trình duyệt trên điện thoại
   - Truy cập `http://<IP_MÁY_TÍNH>:8000/docs`
   - Nếu không mở được → Vấn đề về mạng/firewall

---

## 📞 Hỗ trợ

Nếu gặp lỗi không có trong tài liệu:
1. Check log backend
2. Check log Flutter (trong terminal)
3. Kiểm tra version Python, Flutter
4. Thử restart cả backend lẫn app

---

**Chúc bạn code vui vẻ! 🎉**

