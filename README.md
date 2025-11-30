# 🚀 Travel Together - Hướng Dẫn Chạy Dự Án

## 📋 Mục Lục
- [Tổng Quan](#-tổng-quan)
- [Yêu Cầu Hệ Thống](#-yêu-cầu-hệ-thống)
- [Hướng Dẫn Chạy](#-hướng-dẫn-chạy)
- [Xử Lý Lỗi](#-xử-lý-lỗi)
- [Lưu Ý Quan Trọng](#-lưu-ý-quan-trọng)

---

## 🎯 Tổng Quan

### Cấu Hình Hiện Tại:
- ✅ **Backend:** Chạy trên `0.0.0.0:8000` (cho phép thiết bị Android kết nối)
- ✅ **Frontend:** Sử dụng IP máy `10.132.240.17` (thay vì 127.0.0.1)
- ✅ **Firewall:** Đã mở port 8000
- ✅ **Kết nối:** Máy tính và điện thoại cùng WiFi

---

## 💻 Yêu Cầu Hệ Thống

### Backend:
- Python 3.8+
- FastAPI
- Uvicorn
- Virtual Environment (venv)

### Frontend:
- Flutter SDK
- Dart SDK
- Android Studio / VS Code
- Android device với USB Debugging enabled

### Mạng:
- Máy tính và điện thoại **PHẢI** cùng mạng WiFi
- Port 8000 không bị firewall chặn

---

## 🚀 Hướng Dẫn Chạy

### **BƯỚC 1: Khởi Động Backend**

#### Cách 1: Sử dụng file batch (Khuyến nghị)

1. Mở thư mục `backend`:
   ```bash
   cd D:\TDTT TRAVEL PROJECT\my_travel_app\TravelTogether\backend
   ```

2. Chạy file `run_server.bat`:
   - **Double-click** vào file `run_server.bat`
   - HOẶC từ terminal: `.\run_server.bat`

3. Kiểm tra output thấy dòng:
   ```
   INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
   ```

#### Cách 2: Chạy thủ công

```bash
cd backend
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

---

### **BƯỚC 2: Cấu Hình Firewall (Chỉ làm 1 lần)**

**Mở PowerShell với quyền Administrator** (chuột phải → Run as Administrator):

```powershell
New-NetFirewallRule -DisplayName "Travel Backend API" -Direction Inbound -LocalPort 8000 -Protocol TCP -Action Allow
```

**Kiểm tra firewall đã mở:**
```powershell
Get-NetFirewallRule -DisplayName "Travel Backend API"
```

---

### **BƯỚC 3: Kiểm Tra Kết Nối Mạng**

#### 3.1. Kiểm tra IP máy tính

```powershell
ipconfig
```

Tìm dòng **IPv4 Address** (ví dụ: `10.132.240.17`)

#### 3.2. Cập nhật IP trong Frontend (nếu IP thay đổi)

Mở file `frontend/lib/config/api_config.dart` và cập nhật:

```dart
static const String baseUrl = 'http://<IP_MÁY_TÍNH>:8000';
```

**IP hiện tại:** `10.132.240.17`

#### 3.3. Test kết nối từ điện thoại

Mở trình duyệt trên điện thoại Android, truy cập:
```
http://10.132.240.17:8000/docs
```

✅ Thấy trang **Swagger UI** = Kết nối thành công!

---

### **BƯỚC 4: Chạy Flutter App**

#### 4.1. Chuẩn bị thiết bị Android

1. Bật **USB Debugging** trên điện thoại:
   - Settings → About phone → Tap 7 lần vào Build number
   - Settings → Developer options → USB debugging → ON

2. Kết nối điện thoại vào máy tính qua USB

3. Kiểm tra thiết bị đã kết nối:
   ```bash
   flutter devices
   ```

#### 4.2. Chạy app

**Cách 1: Từ Android Studio**
- Chọn thiết bị ở thanh toolbar
- Nhấn nút **Run** (▶️) hoặc `Shift + F10`

**Cách 2: Từ Terminal**
```bash
cd frontend
flutter run
```

**Cách 3: Hot reload khi đang chạy**
- Trong terminal: Nhấn `r` để reload
- `R` để restart
- `q` để thoát

---

## 🔧 Xử Lý Lỗi

### ❌ Lỗi "Connection refused"

**Nguyên nhân:**
- Backend chưa chạy hoặc chạy trên `127.0.0.1`
- Firewall chặn port 8000
- Không cùng mạng WiFi
- IP máy tính thay đổi

**Giải pháp:**

1. **Kiểm tra backend có chạy:**
   ```powershell
   netstat -a -n -o | Select-String ":8000"
   ```
   Phải thấy `0.0.0.0:8000` (KHÔNG phải `127.0.0.1:8000`)

2. **Tắt backend cũ (nếu có):**
   ```powershell
   # Tìm process ID
   netstat -a -n -o | Select-String ":8000"
   # Tắt process (thay <PID> bằng số thật)
   Stop-Process -Id <PID> -Force
   ```

3. **Chạy lại backend với `run_server.bat`**

4. **Kiểm tra firewall:** Chạy lại lệnh ở Bước 2

5. **Kiểm tra cùng WiFi:** Máy tính và điện thoại phải cùng mạng

---

### ❌ Lỗi "No device found"

**Giải pháp:**
- Kiểm tra USB đã cắm chưa
- Bật USB Debugging trên điện thoại
- Chạy lại `flutter devices`
- Thử cáp USB khác
- Chấp nhận popup "Allow USB debugging" trên điện thoại

---

### ❌ Backend chạy nhưng app vẫn lỗi

**Kiểm tra IP trong `api_config.dart`:**

```dart
// frontend/lib/config/api_config.dart
static const String baseUrl = 'http://10.132.240.17:8000'; // Phải khớp với IP máy
```

**Test bằng browser trên điện thoại:**
```
http://10.132.240.17:8000/docs
```

---

### ❌ Lỗi "Port already in use"

**Backend đang chạy rồi hoặc port bị chiếm:**

```powershell
# Tìm process chiếm port 8000
netstat -a -n -o | Select-String ":8000"

# Tắt process (thay <PID> bằng số thật)
Stop-Process -Id <PID> -Force
```

---

## 📝 Lưu Ý Quan Trọng

### ⚠️ Giữ terminal backend mở
- **KHÔNG tắt** terminal backend khi chạy app
- Tắt backend = app lỗi "Connection refused"

### ⚠️ IP thay đổi khi đổi WiFi
- Mỗi lần đổi WiFi → kiểm tra lại IP máy (`ipconfig`)
- Cập nhật `baseUrl` trong `frontend/lib/config/api_config.dart`
- Restart app Flutter

### ⚠️ Cùng mạng WiFi
- Máy tính và điện thoại **PHẢI** kết nối cùng WiFi
- Không dùng mobile data trên điện thoại

### ⚠️ USB Debugging
- Phải bật USB Debugging trên điện thoại
- Chấp nhận popup "Allow USB debugging" khi cắm USB lần đầu

---

## 📋 Checklist Trước Khi Chạy

- [ ] Backend đang chạy với `0.0.0.0:8000`
- [ ] Terminal backend hiển thị: `Uvicorn running on http://0.0.0.0:8000`
- [ ] Firewall đã mở port 8000
- [ ] Máy tính và điện thoại cùng WiFi
- [ ] `api_config.dart` dùng IP máy (không phải `127.0.0.1`)
- [ ] Điện thoại đã bật USB Debugging
- [ ] Test thử `http://<IP>:8000/docs` trên browser điện thoại thành công

---

## 🛠️ Các File Quan Trọng

### Backend:
- `backend/run_server.bat` - Script khởi động backend
- `backend/run_server.ps1` - PowerShell script
- `backend/open_firewall.ps1` - Script mở firewall
- `backend/main.py` - Main server file
- `backend/FIX_CONNECTION.md` - Hướng dẫn sửa lỗi kết nối

### Frontend:
- `frontend/lib/config/api_config.dart` - Cấu hình API endpoints
- `frontend/pubspec.yaml` - Dependencies Flutter

---

## 🔍 Debug & Troubleshooting

### Kiểm tra backend đang chạy:
```powershell
# Xem process Python
Get-Process | Where-Object {$_.ProcessName -like "*python*"}

# Xem port 8000
netstat -a -n -o | Select-String ":8000"

# Test API từ máy Windows
curl http://10.132.240.17:8000/docs
# hoặc
Invoke-WebRequest -Uri http://10.132.240.17:8000/docs
```

### Kiểm tra kết nối từ điện thoại:
- Mở browser trên điện thoại
- Truy cập: `http://10.132.240.17:8000/docs`
- Phải thấy giao diện Swagger UI

### Xem log Flutter:
```bash
flutter logs
```

### Xem log Android (ADB):
```bash
adb logcat | grep -i flutter
```

---

## 🎯 Quick Start (TL;DR)

```bash
# 1. Khởi động backend
cd backend
.\run_server.bat

# 2. Mở firewall (PowerShell Admin - chỉ 1 lần)
New-NetFirewallRule -DisplayName "Travel Backend API" -Direction Inbound -LocalPort 8000 -Protocol TCP -Action Allow

# 3. Kiểm tra IP máy
ipconfig

# 4. Cập nhật IP trong frontend/lib/config/api_config.dart (nếu cần)

# 5. Chạy Flutter app
cd frontend
flutter run
```

---

## 📊 Cấu Trúc Dự Án

```
TravelTogether/
├── backend/
│   ├── main.py                 # FastAPI main app
│   ├── auth_api.py             # Authentication endpoints
│   ├── user_api.py             # User endpoints
│   ├── group_api.py            # Group endpoints
│   ├── chat_api.py             # Chat endpoints
│   ├── requirements.txt        # Python dependencies
│   ├── run_server.bat          # Script khởi động
│   └── FIX_CONNECTION.md       # Hướng dẫn sửa lỗi
│
├── frontend/
│   ├── lib/
│   │   ├── config/
│   │   │   └── api_config.dart # API configuration
│   │   ├── screens/            # UI screens
│   │   ├── services/           # API services
│   │   └── main.dart           # Flutter entry point
│   └── pubspec.yaml            # Flutter dependencies
│
└── README.md                   # File này
```

---

## 📞 Liên Hệ & Hỗ Trợ

Nếu gặp vấn đề:
1. ✅ Kiểm tra lại các bước trong checklist
2. ✅ Xem phần **Xử Lý Lỗi**
3. ✅ Check terminal backend có lỗi không
4. ✅ Chụp screenshot lỗi để debug
5. ✅ Xem file `backend/FIX_CONNECTION.md`

---

## 🌟 Tips & Tricks

### Chạy backend nền (background):
```powershell
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd 'D:\TDTT TRAVEL PROJECT\my_travel_app\TravelTogether\backend'; .\run_server.bat"
```

### Hot reload Flutter:
- Nhấn `r` trong terminal để reload UI
- Nhấn `R` để restart app hoàn toàn

### Xem API documentation:
- Truy cập: `http://10.132.240.17:8000/docs`
- Swagger UI để test API trực tiếp

---

**Chúc bạn chạy thành công! 🚀**

_Last updated: 2025-01-28_

