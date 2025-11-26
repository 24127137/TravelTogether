# Hướng dẫn khắc phục lỗi kết nối Backend từ thiết bị Android

## ✅ Đã sửa:
1. **Frontend**: Đã cập nhật `api_config.dart` để dùng IP máy `10.132.240.17:8000`
2. **Backend**: Tạo script khởi động với `--host 0.0.0.0`

## 🚀 Các bước thực hiện:

### Bước 1: TẮT backend hiện tại
- Nếu backend đang chạy, hãy **tắt nó** (Ctrl+C trong terminal)

### Bước 2: KHỞI ĐỘNG LẠI backend với host 0.0.0.0
Chọn một trong hai cách:

**Cách 1 (Khuyến nghị): Dùng file script**
```powershell
cd "D:\TDTT TRAVEL PROJECT\my_travel_app\TravelTogether\backend"
.\run_server.bat
```

**Cách 2: Chạy lệnh trực tiếp**
```powershell
cd "D:\TDTT TRAVEL PROJECT\my_travel_app\TravelTogether\backend"
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### Bước 3: MỞ FIREWALL (nếu cần)
Nếu vẫn không kết nối được, chạy **PowerShell với quyền Administrator**:
```powershell
cd "D:\TDTT TRAVEL PROJECT\my_travel_app\TravelTogether\backend"
.\open_firewall.ps1
```

### Bước 4: KIỂM TRA backend đang lắng nghe đúng
Mở terminal mới và chạy:
```powershell
netstat -a -n -o | Select-String ":8000"
```

**Kết quả mong đợi:**
```
TCP    0.0.0.0:8000          0.0.0.0:0              LISTENING
```
Hoặc:
```
TCP    [::]:8000             [::]:0                 LISTENING
```

**KHÔNG phải:**
```
TCP    127.0.0.1:8000        0.0.0.0:0              LISTENING  ❌ (SAI - chỉ local)
```

### Bước 5: ĐẢM BẢO thiết bị Android và máy Windows CÙNG MẠNG WiFi

### Bước 6: CHẠY LẠI app Flutter
```bash
flutter run
```

## 🔍 Kiểm tra kết nối:

### Từ máy Windows:
```powershell
curl http://10.132.240.17:8000/docs
# hoặc
Invoke-WebRequest -Uri http://10.132.240.17:8000/docs -UseBasicParsing
```

### Từ trình duyệt trên thiết bị Android:
Mở browser và truy cập: `http://10.132.240.17:8000/docs`

## ⚠️ Lưu ý:

1. **IP máy có thể thay đổi** khi kết nối mạng khác. Kiểm tra lại IP bằng:
   ```powershell
   ipconfig | Select-String "IPv4"
   ```

2. **Cả thiết bị Android và máy Windows phải cùng mạng WiFi**

3. **Tắt VPN** nếu đang bật

4. **Firewall/Antivirus** có thể chặn - cần mở port 8000

## 📝 Các file đã tạo:
- `run_server.bat` / `run_server.ps1`: Script khởi động backend
- `open_firewall.ps1`: Script mở firewall (cần admin)
- `FIX_CONNECTION.md`: File này

## 🆘 Vẫn lỗi?

1. Kiểm tra log backend khi gọi API
2. Kiểm tra thiết bị Android có ping được máy Windows không
3. Thử tắt Windows Firewall tạm thời để test
4. Dùng `adb logcat` để xem log chi tiết từ Flutter app

