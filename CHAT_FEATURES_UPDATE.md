# Chat Features Update - Tổng Hợp Các Tính Năng Mới

## 📸 Tính Năng 1: Camera & Gallery trong Chatbox

### Thay Đổi trong `chatbox_screen.dart`

#### ✅ Thêm Bottom Sheet để chọn nguồn ảnh
- Người dùng bấm vào nút ảnh sẽ hiện bottom sheet với 2 lựa chọn:
  - **📷 Chụp ảnh** (Camera)
  - **🖼️ Chọn từ thư viện** (Gallery)

#### ✅ Cập nhật hàm `_pickAndSendImage`
- Nhận parameter `source` (ImageSource.camera hoặc ImageSource.gallery)
- Xử lý cả 2 trường hợp chụp ảnh và chọn từ thư viện

#### ✅ UI Input Bar
- Thay 2 nút riêng biệt bằng 1 nút duy nhất với icon `add_photo_alternate`
- Khi bấm vào nút này → hiện bottom sheet để chọn camera hoặc gallery

---

## 💬 Tính Năng 2: Hiển thị Tin Nhắn Gần Nhất trong Messages Screen

### Thay Đổi trong `messages_screen.dart`

#### ✅ Format thời gian hiển thị
- **Hôm nay**: Hiển thị giờ (VD: "14:30")
- **Ngày khác**: Hiển thị ngày tháng (VD: "20 thg 11")

```dart
final timeStr = isToday 
    ? DateFormat('HH:mm').format(createdAtLocal)
    : DateFormat('d \'thg\' M').format(createdAtLocal);
```

#### ✅ Preview tin nhắn
- **Tin nhắn ảnh của mình**: "Bạn đã gửi một ảnh"
- **Tin nhắn ảnh của người khác**: "Đã gửi một ảnh"
- **Tin nhắn text của mình**: "Bạn: <nội dung tin nhắn>"
- **Tin nhắn text của người khác**: "<nội dung tin nhắn>"

```dart
String messagePreview;
if (messageType == 'image') {
  messagePreview = isMyMessage ? 'Bạn đã gửi một ảnh' : 'Đã gửi một ảnh';
} else {
  final content = lastMsg['content'] ?? '';
  messagePreview = isMyMessage ? 'Bạn: $content' : content;
}
```

---

## 👤 Tính Năng 3: Hiển thị Avatar trong Chatbox (Giống Messenger)

### Thay Đổi trong `chatbox_screen.dart`

#### ✅ Avatar chỉ hiển thị cho tin nhắn từ người khác
- **Tin nhắn của người khác**: Hiển thị avatar bên trái
- **Tin nhắn của mình**: KHÔNG hiển thị avatar (giống Messenger)

#### ✅ Load avatar từ API `/users/me`
- Thêm hàm `_loadMyProfile()` để lấy avatar của mình
- Thêm biến `_myAvatarUrl` để cache avatar
- Thêm `Map<String, String?> _userAvatars` để cache avatar của users khác

#### ✅ Cập nhật Message Model
**File: `models/message.dart`**
- Thêm field `senderAvatarUrl` vào Message model
- Avatar được truyền vào `_MessageBubble` widget

#### ✅ UI Message Bubble
```dart
if (!isUser) ...[
  Padding(
    padding: const EdgeInsets.only(right: 8.0),
    child: CircleAvatar(
      radius: 20,
      backgroundColor: const Color(0xFFD9CBB3),
      backgroundImage: senderAvatarUrl != null && senderAvatarUrl!.isNotEmpty
          ? NetworkImage(senderAvatarUrl!)
          : null,
      child: senderAvatarUrl == null || senderAvatarUrl!.isEmpty
          ? const Icon(Icons.person, size: 24, color: Colors.white)
          : null,
    ),
  )
],
```

---

## 📝 Chi Tiết Thay Đổi

### Files đã chỉnh sửa:

1. **`frontend/lib/screens/chatbox_screen.dart`**
   - Thêm biến state: `_userAvatars`, `_myAvatarUrl`
   - Thêm method: `_loadMyProfile()`, `_fetchUserAvatar()`, `_showImageSourceSelection()`
   - Sửa method: `_pickAndSendImage()` nhận parameter `source`
   - Cập nhật UI: Input bar với 1 nút ảnh, message bubble với avatar động
   - Cập nhật `_MessageBubble` widget: nhận `senderAvatarUrl`, chỉ hiện avatar cho tin nhắn của người khác

2. **`frontend/lib/screens/messages_screen.dart`**
   - Cập nhật logic format thời gian (hôm nay vs ngày khác)
   - Cập nhật logic preview tin nhắn (ảnh vs text, mình vs người khác)

3. **`frontend/lib/models/message.dart`**
   - Thêm field: `senderAvatarUrl`
   - Cập nhật constructor và `fromMap` factory

---

## 🎯 Kết Quả

### Messages Screen (Danh sách cuộc trò chuyện)
✅ Hiển thị "Bạn đã gửi một ảnh" khi tin nhắn gần nhất là ảnh của mình  
✅ Hiển thị "Bạn: <tin nhắn>" khi tin nhắn gần nhất là text của mình  
✅ Hiển thị giờ (14:30) nếu là hôm nay  
✅ Hiển thị ngày (20 thg 11) nếu là ngày khác  

### Chatbox Screen (Màn hình chat)
✅ Nút chọn ảnh hiện bottom sheet với 2 tùy chọn: Camera và Gallery  
✅ Avatar chỉ hiển thị bên trái cho tin nhắn từ người khác  
✅ Tin nhắn của mình KHÔNG có avatar (giống Messenger)  
✅ Avatar lấy từ API `/users/me` (sẵn sàng để lấy từ profile của user khác khi có API)  

---

## 📌 Lưu Ý

- **API cho avatar của user khác**: Hiện tại chưa có API để lấy profile của user khác theo ID. Khi backend cung cấp endpoint này (VD: `GET /users/{user_id}`), có thể cập nhật hàm `_fetchUserAvatar()` để fetch avatar thật.

- **Cache avatars**: Đã implement caching để tránh load avatar nhiều lần cho cùng một user.

- **Image upload**: Sử dụng Supabase Storage như đã implement từ trước (bucket `chat_images`).

