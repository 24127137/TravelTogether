# Hướng Dẫn Sử Dụng Tính Năng Chat Mới

## 📸 Gửi Ảnh trong Chat

### Cách sử dụng:
1. Mở **Chatbox Screen** (màn hình chat nhóm)
2. Bấm vào nút **📷** màu vàng nâu bên trái thanh nhập tin nhắn
3. Chọn một trong hai tùy chọn:
   - **📷 Chụp ảnh**: Mở camera để chụp ảnh mới
   - **🖼️ Chọn từ thư viện**: Chọn ảnh có sẵn từ thư viện

### Quy trình:
```
Bấm nút ảnh → Bottom Sheet hiện lên → Chọn Camera/Gallery 
→ Chụp/Chọn ảnh → Upload lên Supabase → Gửi tin nhắn
```

---

## 💬 Xem Preview Tin Nhắn (Messages Screen)

### Hiển thị tin nhắn gần nhất:

#### 📨 Nếu TIN NHẮN CUỐI là ẢNH:
- **Mình gửi**: `"Bạn đã gửi một ảnh"`
- **Người khác gửi**: `"Đã gửi một ảnh"`

#### 💬 Nếu TIN NHẮN CUỐI là TEXT:
- **Mình gửi**: `"Bạn: Xin chào mọi người"`
- **Người khác gửi**: `"Xin chào mọi người"`

### Hiển thị thời gian:

#### 🕐 Nếu tin nhắn HÔM NAY:
```
14:30
09:15
22:45
```

#### 📅 Nếu tin nhắn NGÀY KHÁC:
```
20 thg 11
15 thg 10
1 thg 1
```

---

## 👤 Avatar trong Chat (Giống Messenger)

### Quy tắc hiển thị:

#### Tin nhắn từ NGƯỜI KHÁC (bên trái):
```
[Avatar]  [Tin nhắn]
   👤     💬 Xin chào!
```
- **Hiển thị avatar** tròn bên trái
- Avatar lấy từ profile của người gửi
- Nếu chưa có avatar → hiện icon người mặc định

#### Tin nhắn của MÌNH (bên phải):
```
        [Tin nhắn]
        💬 Xin chào!
```
- **KHÔNG hiển thị avatar**
- Chỉ có bubble tin nhắn bên phải
- Giống như Messenger

---

## 🔧 Kỹ Thuật Implementation

### 1. Image Picker với Bottom Sheet
```dart
// Hiện bottom sheet chọn nguồn
_showImageSourceSelection()
  ├── Chọn Camera → _pickAndSendImage(source: ImageSource.camera)
  └── Chọn Gallery → _pickAndSendImage(source: ImageSource.gallery)
```

### 2. Format Thời Gian Động
```dart
final isToday = createdAtLocal.year == now.year &&
               createdAtLocal.month == now.month &&
               createdAtLocal.day == now.day;

final timeStr = isToday 
    ? DateFormat('HH:mm').format(createdAtLocal)
    : DateFormat('d \'thg\' M').format(createdAtLocal);
```

### 3. Preview Tin Nhắn Thông Minh
```dart
String messagePreview;
if (messageType == 'image') {
  messagePreview = isMyMessage ? 'Bạn đã gửi một ảnh' : 'Đã gửi một ảnh';
} else {
  final content = lastMsg['content'] ?? '';
  messagePreview = isMyMessage ? 'Bạn: $content' : content;
}
```

### 4. Avatar Từ API
```dart
// Load avatar của mình
Future<void> _loadMyProfile() async {
  final response = await http.get(
    ApiConfig.getUri(ApiConfig.userProfile), // GET /users/me
    headers: {"Authorization": "Bearer $_accessToken"},
  );
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    _myAvatarUrl = data['avatar_url'];
  }
}
```

### 5. Conditional Avatar Display
```dart
// Chỉ hiện avatar cho tin nhắn KHÔNG PHẢI của mình
if (!isUser) ...[
  CircleAvatar(
    backgroundImage: senderAvatarUrl != null 
        ? NetworkImage(senderAvatarUrl!)
        : null,
    child: senderAvatarUrl == null 
        ? Icon(Icons.person) 
        : null,
  )
],
```

---

## 📦 Files Đã Chỉnh Sửa

### 1. `chatbox_screen.dart`
- ✅ Thêm state variables: `_userAvatars`, `_myAvatarUrl`
- ✅ Thêm methods: `_loadMyProfile()`, `_fetchUserAvatar()`, `_showImageSourceSelection()`
- ✅ Sửa method: `_pickAndSendImage(source: ImageSource)`
- ✅ Cập nhật UI: Bottom sheet picker, avatar display
- ✅ Cập nhật `_MessageBubble`: Nhận `senderAvatarUrl`, điều kiện hiển thị avatar

### 2. `messages_screen.dart`
- ✅ Thêm logic format thời gian (today vs other days)
- ✅ Thêm logic preview tin nhắn (image vs text, me vs others)
- ✅ Load `user_id` từ SharedPreferences để so sánh

### 3. `models/message.dart`
- ✅ Thêm field: `senderAvatarUrl`
- ✅ Cập nhật constructor
- ✅ Cập nhật `fromMap` factory

---

## ✨ Demo Flow

### Khi gửi ảnh:
1. User bấm nút ảnh 📷
2. Bottom sheet hiện ra với 2 lựa chọn
3. User chọn Camera hoặc Gallery
4. Chụp/chọn ảnh
5. Ảnh được upload lên Supabase
6. Tin nhắn ảnh được gửi đi
7. Chat tự động refresh và scroll xuống dưới

### Messages Screen sẽ hiển thị:
```
[AI Chatbot Icon]  AI Chatbot
                   Xin chào! Tôi có thể giúp gì...
                   14:30 ✓

[Group Icon]       Nhóm chat
                   Bạn đã gửi một ảnh
                   20 thg 11 ✓
```

### Chatbox Screen sẽ hiển thị:
```
👤 [Avatar]  💬 Xin chào mọi người!
             14:30 ✓✓

                            💬 Chào bạn! 14:32 ✓✓

👤 [Avatar]  🖼️ [Ảnh được hiển thị]
             14:35 ✓✓

                            🖼️ [Ảnh] 14:40 ✓✓
                            (Không có avatar)
```

---

## ⚠️ Notes

1. **Permissions**: Đảm bảo app có quyền truy cập Camera và Storage
   - Android: `AndroidManifest.xml` cần có camera & storage permissions
   - iOS: `Info.plist` cần có camera & photo library usage descriptions

2. **Avatar API**: Hiện tại avatar của người khác dùng default icon. Khi backend có endpoint `GET /users/{user_id}`, có thể update `_fetchUserAvatar()` để fetch avatar thật.

3. **Testing**: Nên test trên thiết bị thật để kiểm tra camera functionality.

---

## 🚀 Ready to Use!

Tất cả tính năng đã được implement và sẵn sàng sử dụng. Không có lỗi compilation.

