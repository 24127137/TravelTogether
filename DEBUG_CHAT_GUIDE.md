# 🐛 Hướng dẫn Debug - Tin nhắn không phân biệt người gửi

## Vấn đề
- Tin nhắn tất cả hiển thị bên trái hoặc bên phải (không phân biệt)
- Messages screen không update tin nhắn mới nhất khi quay lại

## ✅ Đã sửa

### 1. Thêm debug logs trong chatbox_screen.dart
```dart
// DEBUG: In ra để kiểm tra
print('DEBUG: Current User ID = $_currentUserId');
print('DEBUG: Sender ID = $senderId');
print('DEBUG: Are they equal? ${senderId == _currentUserId}');
```

### 2. Auto-reload messages_screen khi quay lại
```dart
// Trong _MessageTile.onTap:
await Navigator.push(...);
// Reload khi quay lại
if (context.mounted) {
  final state = context.findAncestorStateOfType<_MessagesScreenState>();
  state?._loadConversations();
}
```

## 🔍 Cách Debug

### Bước 1: Kiểm tra Debug Logs

1. **Run app trong debug mode**:
   ```bash
   flutter run
   ```

2. **Đăng xuất và đăng nhập lại** (quan trọng!)
   - Để đảm bảo `user_id` được lưu vào SharedPreferences

3. **Gửi tin nhắn** và xem logs trong terminal:
   ```
   DEBUG: Current User ID = abc123-xyz...
   DEBUG: Sender ID = abc123-xyz...
   DEBUG: Are they equal? true   <- Phải là true!
   ```

4. **Kiểm tra kết quả**:
   - ✅ Nếu `Are they equal? true` → Tin nhắn phải hiển thị **bên phải**
   - ❌ Nếu `Are they equal? false` → Có vấn đề với user_id

### Bước 2: Kiểm tra SharedPreferences

Nếu debug log không khớp, hãy kiểm tra xem `user_id` có được lưu không:

```dart
// Thêm vào _loadAccessToken() trong chatbox_screen.dart
final prefs = await SharedPreferences.getInstance();
_accessToken = prefs.getString('access_token');
_currentUserId = prefs.getString('user_id');

// THÊM DEBUG
print('🔍 All SharedPreferences keys:');
print(prefs.getKeys());
print('🔍 Access Token: ${_accessToken?.substring(0, 20)}...');
print('🔍 User ID: $_currentUserId');
```

### Bước 3: Kiểm tra Backend Response

Nếu vẫn không đúng, kiểm tra response từ backend:

```dart
// Trong _loadChatHistory(), thêm:
if (response.statusCode == 200) {
  final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
  
  // DEBUG: In toàn bộ response
  print('🔍 Backend Response:');
  print(jsonEncode(data));
  
  // ...existing code...
}
```

## 🔧 Các trường hợp lỗi phổ biến

### Lỗi 1: user_id = null
**Triệu chứng**: 
```
DEBUG: Current User ID = null
DEBUG: Are they equal? false
```

**Nguyên nhân**: Chưa đăng nhập lại sau khi code được update

**Giải pháp**:
1. Đăng xuất khỏi app
2. Đăng nhập lại (hoặc đăng ký mới)
3. Code sẽ tự động lưu `user_id`

### Lỗi 2: sender_id và user_id không khớp format
**Triệu chứng**:
```
DEBUG: Current User ID = abc-123
DEBUG: Sender ID = abc123
DEBUG: Are they equal? false
```

**Nguyên nhân**: Format không giống nhau (có dấu - hoặc không)

**Giải pháp**: Chuẩn hóa cả 2 trước khi so sánh:

```dart
// Trong chatbox_screen.dart, sửa:
final senderId = (msg['sender_id'] ?? '').toString().trim();
final currentId = (_currentUserId ?? '').trim();

final isUser = currentId.isNotEmpty && senderId == currentId;
```

### Lỗi 3: Tất cả tin nhắn đều bên trái
**Triệu chứng**: `isUser` luôn = false

**Giải pháp**: 
1. Check log để xem `user_id` có null không
2. Đăng nhập lại
3. Clear app data:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

### Lỗi 4: Messages screen không update
**Triệu chứng**: Gửi tin nhắn xong quay lại vẫn hiện tin cũ

**Giải pháp**: Đã fix bằng cách reload khi quay lại. Nếu vẫn lỗi:

```dart
// Trong messages_screen.dart, thử dùng didChangeDependencies thay vì didUpdateWidget:

@override
void didChangeDependencies() {
  super.didChangeDependencies();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadConversations();
  });
}
```

## 📋 Checklist Debug

Hãy làm theo thứ tự:

- [ ] 1. Run app trong debug mode (`flutter run`)
- [ ] 2. Đăng xuất
- [ ] 3. Đăng nhập lại (QUAN TRỌNG!)
- [ ] 4. Vào ChatboxScreen
- [ ] 5. Gửi tin nhắn
- [ ] 6. Xem log trong terminal
- [ ] 7. Kiểm tra:
  - [ ] `Current User ID` không null
  - [ ] `Sender ID` không null
  - [ ] `Are they equal?` = true cho tin nhắn của mình
- [ ] 8. Kiểm tra giao diện:
  - [ ] Tin của mình ở bên phải (màu #8A724C)
  - [ ] Tin của người khác ở bên trái (màu #B99668)
- [ ] 9. Quay lại Messages screen
- [ ] 10. Kiểm tra tin nhắn mới nhất đã update chưa

## 🔍 Expected Debug Output

### Khi gửi tin nhắn (phải hiện bên phải):
```
DEBUG: Current User ID = 8c9f234a-1234-5678-9abc-def012345678
DEBUG: Sender ID = 8c9f234a-1234-5678-9abc-def012345678
DEBUG: Are they equal? true  ✅
```

### Khi nhận tin nhắn từ người khác (phải hiện bên trái):
```
DEBUG: Current User ID = 8c9f234a-1234-5678-9abc-def012345678
DEBUG: Sender ID = 7b8e123b-4321-8765-cba9-fed098765432
DEBUG: Are they equal? false  ✅
```

## 🚀 Test Case

### Test 1: Tin nhắn của mình
```
1. Đăng nhập tài khoản A
2. Vào chat
3. Gửi tin: "Hello from A"
4. Kiểm tra log:
   - Current User ID = [UUID của A]
   - Sender ID = [UUID của A]  
   - Are they equal? true ✅
5. Kiểm tra UI:
   - Tin hiện bên PHẢI ✅
   - Màu nâu đậm (#8A724C) ✅
```

### Test 2: Tin nhắn của người khác
```
1. Đăng nhập tài khoản B (thiết bị khác)
2. Gửi tin: "Hello from B"
3. Quay lại tài khoản A
4. Kiểm tra log:
   - Current User ID = [UUID của A]
   - Sender ID = [UUID của B]
   - Are they equal? false ✅
5. Kiểm tra UI:
   - Tin hiện bên TRÁI ✅
   - Màu nâu nhạt (#B99668) ✅
```

### Test 3: Messages screen auto-reload
```
1. Ở Messages screen
2. Vào ChatboxScreen
3. Gửi tin nhắn: "Test reload"
4. Bấm Back về Messages screen
5. Kiểm tra:
   - Tin nhắn mới nhất hiển thị: "Test reload" ✅
   - Thời gian update đúng ✅
```

## 💡 Tips

### Tip 1: Xem toàn bộ SharedPreferences
```dart
final prefs = await SharedPreferences.getInstance();
final keys = prefs.getKeys();
print('All keys in SharedPreferences:');
for (var key in keys) {
  print('  $key: ${prefs.get(key)}');
}
```

### Tip 2: Clear SharedPreferences (nếu cần reset)
```dart
final prefs = await SharedPreferences.getInstance();
await prefs.clear();
// Hoặc xóa riêng:
await prefs.remove('user_id');
```

### Tip 3: Test với Postman
1. Gọi `POST /auth/signin` với email/password
2. Copy `user.id` từ response
3. So sánh với `sender_id` trong tin nhắn

## 📞 Nếu vẫn lỗi

Gửi cho tôi:
1. Debug logs đầy đủ (copy từ terminal)
2. Screenshot UI (tin nhắn hiển thị sai)
3. Response từ API `/auth/signin`
4. Response từ API `/chat/history`

---

**Created**: 24/11/2025
**Updated**: 24/11/2025

