  <div align="center">

# 🌍 **TRAVEL TOGETHER**
### *SMART TOURISM SYSTEM - Kết nối người du lịch thông minh*

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-11.0.0-009688?logo=fastapi)](https://fastapi.tiangolo.com)
[![Python](https://img.shields.io/badge/Python-3.13-blue?logo=python)](https://python.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

### **ĐẠI HỌC QUỐC GIA TP.HCM**
### **ĐẠI HỌC KHOA HỌC TỰ NHIÊN**
### **KHOA CÔNG NGHỆ THÔNG TIN**

**Môn học:** Tư duy tính toán  
**Học kỳ:** 1 - Năm học 2025

---

### 👥 **NHÓM SINH VIÊN THỰC HIỆN**

| MSSV | Họ và Tên | Email |
|------|-----------|-------|
| 24127137 | Nguyễn Thanh Trúc | 24127137@student.hcmus.edu.vn |
| 24127422 | Đào Minh Khoa | 24127422@student.hcmus.edu.vn |
| 24127018 | Trần Lưu Gia Bảo | 24127018@student.hcmus.edu.vn |
| 24127337 | Nguyễn Tiến Cường | 24127337@student.hcmus.edu.vn |
| 24127252 | Nguyễn Khánh Toàn | 24127252@student.hcmus.edu.vn |
| 24127226 | Phạm Trần Anh Quân | 24127226@student.hcmus.edu.vn |

### 👨‍🏫 **GIẢNG VIÊN HƯỚNG DẪN**

- **PhD. Nguyễn Tiến Huy**
- **PhD. Lê Thanh Tùng**
- **Mr. Trần Hoàng Quân**

---

<img width="350px" src="https://github.com/user-attachments/assets/28be354f-a66b-4eb0-8b68-f338139982f1">


</div>

---

## 📖 **Giới Thiệu**

**Travel Together** là ứng dụng di động thông minh giúp kết nối những người đam mê du lịch, hỗ trợ lập kế hoạch hành trình nhóm và chia sẻ trải nghiệm. Với sự kết hợp giữa công nghệ AI tiên tiến và giao diện thân thiện, Travel Together mang đến trải nghiệm du lịch hoàn hảo cho mọi người.

### 🎯 **Mục Tiêu Dự Án**
- **Kết nối cộng đồng:** Tìm kiếm và kết nối với những người có cùng sở thích du lịch
- **Lập kế hoạch thông minh:** Công cụ lập lịch trình, tối ưu hoá lộ trình và định vị GPS
- **Giao tiếp realtime:** Chat nhóm, thông báo đẩy và chia sẻ hình ảnh ngay lập tức
- **Trợ lý AI:** Chatbot thông minh hỗ trợ gợi ý địa điểm, lên kế hoạch 
- **An toàn bảo mật:** Tăng cường bảo vệ người dùng và tài khoản với cơ chế mã PIN kép (Dual PIN)
- 
---

## ✨ **Tính Năng Chính**

### 🔐 **Xác Thực & Bảo Mật**
- Đăng ký/Đăng nhập với Email + Password
- JWT Token Authentication với Firebase Admin SDK
- Quản lý phiên đăng nhập an toàn
- Cơ chế mã PIN kép: Nếu không nhập mã PIN sau 36 giờ, hệ thống tự động gửi định vị khẩn cấp đến email của người thân

### 👥 **Quản Lý Nhóm Du Lịch**
- Tạo và tham gia nhóm du lịch
- Khám phá nhóm theo địa điểm, thời gian
- Phân quyền Host/Member với các chức năng riêng biệt
- Lịch trình nhóm với Table Calendar
- Quản lý chi phí chung
- Deep Semantic Matching AI: Sử dụng AI để so sánh lịch trình cá nhân của người dùng với các nhóm hiện có dựa trên "ngữ nghĩa" (ví dụ: hiểu rằng "Bờ Hồ" và "Hồ Hoàn Kiếm" là một) để đưa ra gợi ý gia nhập nhóm chính xác nhất
- Cơ chế Phê duyệt Thành viên: Quản lý danh sách yêu cầu gia nhập, cho phép Host duyệt hoặc từ chối thành viên mới
- Reputation & Review System: Hệ thống đánh giá thành viên sau mỗi chuyến đi, tính toán điểm uy tín (Average Rating) dựa trên phản hồi của các thành viên khác trong nhóm

### 💬 **Chat Realtime**
- WebSocket chat realtime trong nhóm
- Gửi/nhận hình ảnh với Supabase Storage
- Trạng thái đã xem tin nhắn (Read receipts)
- Thông báo đẩy với Firebase Cloud Messaging
- Lưu trữ lịch sử chat không giới hạn

### 🤖 **AI Chatbot Du Lịch và thuật toán AI**
- Tích hợp Google Gemini AI
- Gợi ý địa điểm, nhà hàng, khách sạn
- Lập kế hoạch hành trình tự động
- Phân tích hình ảnh và đề xuất địa điểm tương tự
- Lưu session chat cho mỗi người dùng
- AI Destination Ranking: AI chấm điểm (0-100) các địa điểm dựa trên sự phù hợp trực tiếp về sở thích, độ tuổi, giới tính của người dùng

### 🗺️ **Bản Đồ & Định Vị**
- Tích hợp Flutter Map với OpenStreetMap
- Vẽ tuyến đường với Polyline Points
- Đánh dấu địa điểm quan trọng
- Geocoding & Reverse Geocoding
- Tích hợp lớp Layer tùy chỉnh hiển thị đầy đủ quần đảo Hoàng Sa và Trường Sa của Việt Nam

### 🎨 **Giao Diện Người Dùng**
- Material Design 3
- Animations với Flutter Animate
- Chuyển đổi ngôn ngữ tiếng việt <-> tiếng anh với Easy Localization

---

## 🛠️ **Công Nghệ Sử Dụng**

### **Frontend - Flutter/Dart**

| Công nghệ | Phiên bản | Mục đích |
|-----------|-----------|----------|
| **Flutter SDK** | 3.0+ | Framework chính |
| **Dart** | 3.0+ | Ngôn ngữ lập trình |
| **Supabase Flutter** | 2.10.3 | Realtime database & Storage |
| **Firebase Core** | 3.6.0 | Firebase services |
| **Firebase Messaging** | 15.1.3 | Push notifications |
| **HTTP** | 1.2.0 | REST API calls |
| **WebSocket Channel** | 3.0.3 | Realtime chat |
| **Flutter Map** | 7.0.2 | Map rendering |
| **Geolocator** | 10.1.0 | GPS location |
| **Image Picker** | 1.0.7 | Camera/Gallery access |
| **Shared Preferences** | 2.3.3 | Local storage |
| **Hive Flutter** | 1.1.0 | NoSQL database |
| **Easy Localization** | 3.0.8 | Internationalization |
| **Flutter Animate** | 4.5.2 | UI animations |
| **Confetti** | 0.7.0 | Celebration effects |

### **Backend - Python/FastAPI**

| Công nghệ | Mục đích |
|-----------|----------|
| **FastAPI** | REST API framework |
| **Uvicorn** | ASGI server |
| **SQLModel** | ORM (SQL databases) |
| **Supabase Python** | Database client |
| **Google Generative AI** | AI Chatbot (Gemini) |
| **Firebase Admin SDK** | Authentication & FCM |
| **Pydantic** | Data validation |
| **FastAPI Mail** | Email service |
| **APScheduler** | Background tasks |
| **Psycopg2** | PostgreSQL adapter |

### **Database & Cloud Services**

- **🗄️ Supabase (PostgreSQL):** Database chính, Authentication, Storage
- **🔥 Firebase:** Push notifications, Analytics
- **🤖 Google Gemini AI:** AI Chatbot service

### **DevOps & Tools**

- **Git & GitHub:** Version control
- **Android Studio / VS Code:** Development IDE
- **Postman:** API testing
- **PowerShell Scripts:** Automation

---

## 📥 **Hướng Dẫn Cài Đặt**

### **Yêu Cầu Hệ Thống**

#### **Backend Requirements:**
- Python 3.8 trở lên
- pip (Python package manager)
- Virtual environment (khuyến nghị)
- PostgreSQL database (hoặc Supabase account)

#### **Frontend Requirements:**
- Flutter SDK 3.0+
- Dart SDK 3.0+
- Android Studio hoặc VS Code
- Android Emulator hoặc thiết bị Android thật
- Xcode (cho iOS - optional)

#### **Network Requirements:**
- Máy tính và điện thoại phải cùng WiFi (khi chạy local)
- Port 8000 không bị firewall chặn

---

### **BƯỚC 1: Clone Repository**

```bash
git clone https://github.com/yourusername/TravelTogether.git
cd TravelTogether
```

---

### **BƯỚC 2: Thiết Lập Backend**

#### 2.1. Tạo Virtual Environment

```bash
cd backend
python -m venv venv

# Windows
venv\Scripts\activate

# macOS/Linux
source venv/bin/activate
```

#### 2.2. Cài Đặt Dependencies

```bash
pip install -r requirements.txt
```

#### 2.3. Cấu Hình Environment Variables

Tạo file `.env` trong thư mục `backend/`:

```env
# Database
SUPABASE_URL=your_supabase_url
SUPABASE_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

# JWT
JWT_SECRET_KEY=your_jwt_secret_key_here
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30


# Email Service
MAIL_USERNAME=your_email@gmail.com
MAIL_PASSWORD=your_app_password
MAIL_FROM=your_email@gmail.com
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587

# Firebase
FIREBASE_CREDENTIALS_PATH=./firebase-admin-sdk.json
```

> ⚠️ **Lưu ý:** File `.env` liên lạc với cn20378@gmail.com để lấy!

#### 2.4. Thêm Firebase Service Account

Tải file `firebase-admin-sdk.json` từ Firebase Console và đặt vào thư mục `backend/`

#### 2.5. Khởi Động Server

**Cách 1: Sử dụng script (Windows)**
```bash
.\run_server.bat
```

**Cách 2: Chạy thủ công**
```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

**Kiểm tra server đang chạy:**
Mở browser và truy cập: `http://localhost:8000/docs` để xem API documentation (Swagger UI)

---

### **BƯỚC 3: Thiết Lập Frontend**

#### 3.1. Cài Đặt Flutter Dependencies

```bash
cd frontend
flutter pub get
```

#### 3.2. Cấu Hình API Endpoint

Mở file `lib/config/api_config.dart` và cập nhật IP của máy chạy backend:

```dart
class ApiConfig {
  // Thay <YOUR_IP> bằng IP máy tính của bạn
  static const String baseUrl = 'http://<YOUR_IP>:8000';
  static const String chatWebSocket = 'ws://<YOUR_IP>:8000/ws/chat';
  
  // Hoặc dùng localhost nếu chạy trên emulator
  // static const String baseUrl = 'http://10.0.2.2:8000'; // Android Emulator
}
```

**Tìm IP máy tính:**
```bash
# Windows
ipconfig

# macOS/Linux
ifconfig
```

#### 3.3. Cấu Hình Firebase

Thêm file `google-services.json` (Android) và `GoogleService-Info.plist` (iOS) vào thư mục tương ứng:
- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

#### 3.4. Tạo File .env

Tạo file `.env` trong thư mục `frontend/`:

```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

#### 3.5. Chạy Ứng Dụng

**Kiểm tra thiết bị:**
```bash
flutter devices
```

**Chạy app:**
```bash
# Chạy trên thiết bị đầu tiên
flutter run

# Chạy trên thiết bị cụ thể
flutter run -d <device-id>

# Chạy ở chế độ release
flutter run --release
```

**Hot reload trong khi chạy:**
- Nhấn `r` để reload
- Nhấn `R` để restart hoàn toàn
- Nhấn `q` để thoát

---

### **BƯỚC 4: Mở Firewall (Windows Only)**

Mở **PowerShell với quyền Administrator** và chạy:

```powershell
New-NetFirewallRule -DisplayName "Travel Backend API" -Direction Inbound -LocalPort 8000 -Protocol TCP -Action Allow
```

**Kiểm tra rule đã tạo:**
```powershell
Get-NetFirewallRule -DisplayName "Travel Backend API"
```

---

### **BƯỚC 5: Kiểm Tra Kết Nối**

#### Từ máy tính:
```bash
curl http://localhost:8000/docs
```

#### Từ điện thoại:
Mở browser trên điện thoại, truy cập:
```
http://<IP_MÁY_TÍNH>:8000/docs
```

Nếu thấy giao diện Swagger UI → Thành công! 🎉

---

## **Hướng Dẫn Sử Dụng**

### **1️⃣ Đăng Ký Tài Khoản**
1. Mở app Travel Together
2. Chọn "Đăng ký" → Nhập email, mật khẩu
3. Hoàn thiện hồ sơ (tên, avatar, sở thích)

### **2️⃣ Tạo Nhóm Du Lịch**
1. Vào tab "Khám phá" → Nhấn nút "+"
2. Điền thông tin: Tên nhóm, địa điểm, thời gian
3. Thiết lập quyền riêng tư (Public/Private)
4. Chia sẻ link hoặc mã nhóm cho bạn bè

### **3️⃣ Chat Với Nhóm**
1. Vào nhóm → Tab "Chat"
2. Gửi tin nhắn, ảnh, location
3. @mention thành viên để thông báo
4. Pin tin nhắn quan trọng

### **4️⃣ Sử Dụng AI Chatbot**
1. Nhấn biểu tượng robot 🤖 ở góc phải
2. Hỏi: "Gợi ý 3 địa điểm du lịch ở Đà Nẵng"
3. Upload ảnh để AI phân tích và gợi ý
4. Lưu lại các gợi ý vào lịch trình

### **5️⃣ Lập Kế Hoạch**
1. Tab "Lịch trình" → Chọn ngày
2. Thêm địa điểm, giờ, ghi chú
3. Xem bản đồ tuyến đường
4. Phân công nhiệm vụ cho thành viên

---

## 📄 **Giấy Phép**
Dự án này được phát hành dưới giấy phép **MIT License**.

Xem file [LICENSE](LICENSE) để biết thêm chi tiết.

---
## 📞 **Liên Hệ & Hỗ Trợ**

- **Email:** cn20378@gmail.com
- **Facebook:** https://www.facebook.com/nguyenntc352
- **Github:** https://github.com/24127337tuduytinhtoan

> ⚠️ **Lưu ý:** Nếu gặp sự cố hãy liên lạc với cn20378@gmail.com để hỏi đáp!

---

## 📚 **Tài Liệu Tham Khảo**

### **Official Documentation:**
- [Flutter Documentation](https://docs.flutter.dev/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Supabase Documentation](https://supabase.com/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Google AI Documentation](https://ai.google.dev/docs)

### **Tutorials & Guides:**
- [Flutter WebSocket Tutorial](https://flutter.dev/docs/cookbook/networking/web-sockets)
- [FastAPI WebSocket Guide](https://fastapi.tiangolo.com/advanced/websockets/)
- [Firebase Cloud Messaging Setup](https://firebase.google.com/docs/cloud-messaging/flutter/client)

---

<div align="center">

## ⭐ **Star Project Nếu Bạn Thích!**

Nếu dự án này hữu ích với bạn, hãy cho chúng tôi một ⭐ trên GitHub!

[🌟 Star](https://github.com/24127137/TravelTogether) | [🐛 Report Bug](https://github.com/24127337tuduytinhtoan) | [💡 Request Feature](https://github.com/24127337tuduytinhtoan)

---

![Thanks](https://readme-typing-svg.demolab.com?font=Fira+Code&weight=500&duration=4000&pause=1000&color=45A1FF&center=true&vCenter=true&width=600&lines=C%E1%BA%A3m+%C6%A1n+b%E1%BA%A1n+%C4%91%C3%A3+gh%C3%A9+th%C4%83m+project+nh%C3%B3m+ch%C3%BAng+t%C3%B4i!;C%C3%B9ng+kh%C3%A1m+ph%C3%A1+v%C3%A0+tr%E1%BA%A3i+nghi%E1%BB%87m+du+l%E1%BB%8Bch+th%C3%B4ng+minh.+%F0%9F%9A%80)
</div>
