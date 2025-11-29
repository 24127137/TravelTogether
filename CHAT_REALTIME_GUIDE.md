# Hướng dẫn tích hợp Chat Realtime

## Tổng quan
Chat realtime đã được tích hợp vào ứng dụng Travel Together, sử dụng API backend để gửi và nhận tin nhắn theo nhóm.

## Cách hoạt động

### 1. Lấy Access Token
- Khi người dùng đăng nhập/đăng ký thành công, access_token được lưu vào SharedPreferences
- Token này được sử dụng để xác thực các request API

### 2. API Endpoints đã tích hợp

#### GET /chat/history
- **Mục đích**: Lấy lịch sử chat (30 tin nhắn mới nhất)
- **Authentication**: Bearer Token (tự động từ SharedPreferences)
- **Response**: Danh sách tin nhắn với các trường:
  - `id`: ID tin nhắn
  - `group_id`: ID nhóm
  - `sender_id`: UUID người gửi
  - `message_type`: Loại tin nhắn (text/image)
  - `content`: Nội dung tin nhắn
  - `image_url`: URL hình ảnh (nếu có)
  - `created_at`: Thời gian tạo

#### POST /chat/send
- **Mục đích**: Gửi tin nhắn mới
- **Authentication**: Bearer Token
- **Request Body**:
  ```json
  {
    "content": "Chào mọi người!",
    "message_type": "text"
  }
  ```
- **Response**: Thông tin tin nhắn vừa gửi

### 3. Tính năng Real-time

#### Auto-refresh
- Chat tự động làm mới mỗi 3 giây để lấy tin nhắn mới
- Sử dụng `Timer.periodic` để thực hiện polling
- Refresh được thực hiện ở chế độ silent (không hiển thị loading)

#### Scroll tự động
- Khi load tin nhắn mới, tự động scroll xuống dưới cùng
- Khi focus vào input, tự động scroll để hiển thị keyboard

### 4. Cấu trúc Code

#### File đã chỉnh sửa:

1. **lib/config/api_config.dart**
   - Thêm 2 endpoints mới: `chatHistory` và `chatSend`

2. **lib/screens/chatbox_screen.dart**
   - Thay thế mock data bằng real API
   - Thêm authentication với access_token
   - Thêm auto-refresh mechanism
   - Thêm error handling

3. **assets/translations/en.json** & **vi.json**
   - Thêm các key translation cho chat:
     - `chat_title`: Tiêu đề chat
     - `chat_error_no_token`: Lỗi chưa đăng nhập
     - `chat_error_load`: Lỗi load chat
     - `chat_error_send`: Lỗi gửi tin nhắn
     - `chat_no_group`: Chưa tham gia nhóm

## Cách sử dụng

### Khởi chạy Backend
```powershell
cd backend
.\run_server.bat
```

### Cấu hình IP Server
Trong file `lib/config/api_config.dart`, cập nhật IP của máy chạy backend:
```dart
static const String baseUrl = 'http://10.132.240.17:8000'; // Thay đổi IP này
```

### Test trên thiết bị Android
1. Đảm bảo thiết bị và máy tính cùng mạng WiFi
2. Lấy IP của máy tính: `ipconfig` (Windows) hoặc `ifconfig` (Linux/Mac)
3. Cập nhật IP trong `api_config.dart`
4. Run app trên thiết bị

## Xử lý lỗi phổ biến

### Lỗi "Connection refused"
- **Nguyên nhân**: Không kết nối được đến server
- **Giải pháp**:
  1. Kiểm tra backend đã chạy chưa
  2. Kiểm tra IP trong `api_config.dart` có đúng không
  3. Kiểm tra firewall có chặn port 8000 không
  4. Kiểm tra thiết bị và máy tính cùng mạng WiFi

### Lỗi "Not logged in"
- **Nguyên nhân**: Không có access_token
- **Giải pháp**: Đăng xuất và đăng nhập lại

### Lỗi "You haven't joined any group yet"
- **Nguyên nhân**: User chưa tham gia nhóm nào
- **Giải pháp**: Tạo hoặc tham gia một nhóm trước khi chat

## Luồng hoạt động

```
1. User đăng nhập
   ↓
2. Access token được lưu vào SharedPreferences
   ↓
3. Vào màn hình chat
   ↓
4. Load access token từ SharedPreferences
   ↓
5. Gọi API GET /chat/history với Bearer token
   ↓
6. Hiển thị danh sách tin nhắn
   ↓
7. Bắt đầu auto-refresh mỗi 3 giây
   ↓
8. User gửi tin nhắn
   ↓
9. Gọi API POST /chat/send
   ↓
10. Reload chat history để hiển thị tin nhắn mới
```

## Tính năng trong tương lai

- [ ] WebSocket cho real-time messaging thực sự
- [ ] Gửi hình ảnh
- [ ] Thông báo push khi có tin nhắn mới
- [ ] Typing indicator
- [ ] Message read receipts
- [ ] Emoji reactions
- [ ] Reply to message
- [ ] Delete/Edit message

## Backend Logic

### Cách backend xác định Group ID
Backend tự động tìm group_id từ access_token thông qua:
1. Lấy `auth_uuid` từ token
2. Tìm profile với `auth_user_id = auth_uuid`
3. Kiểm tra `joined_groups` hoặc `owned_groups` của profile
4. Trả về group_id đầu tiên tìm thấy

### Cách backend xác định Sender ID
- Sender ID chính là `auth_uuid` (UUID của user trong Supabase Auth)
- Được tự động lấy từ access token

## Lưu ý quan trọng

1. **Access Token**: Token có thời hạn, cần implement refresh token nếu hết hạn
2. **Group ID**: User chỉ có thể chat trong nhóm mà họ đã tham gia
3. **Auto-refresh**: Tần suất 3 giây có thể tùy chỉnh tùy nhu cầu
4. **Performance**: Với nhiều user, nên chuyển sang WebSocket thay vì polling
5. **Security**: Luôn sử dụng HTTPS trong production

## Cập nhật gần đây

- ✅ Tích hợp API chat/history
- ✅ Tích hợp API chat/send
- ✅ Thêm auto-refresh mechanism
- ✅ Thêm loading states
- ✅ Thêm error handling
- ✅ Thêm translations (EN/VI)
- ✅ Scroll tự động
- ✅ Authentication với Bearer token

