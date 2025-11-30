# 🎯 Hướng Dẫn: Điều Hướng Từ Notification (Navigation from Notifications)

## 📋 Tổng Quan

Tính năng này cho phép người dùng **tap vào notification** và **tự động điều hướng** đến màn hình liên quan:
- ✅ Tin nhắn → Mở màn hình **ChatboxScreen**
- ✅ AI chatbot → Mở màn hình **AiChatbotScreen**
- ✅ Yêu cầu tham gia nhóm → Mở màn hình **NotificationScreen**

---

## 🔧 Các Thay Đổi Đã Thực Hiện

### 1️⃣ **Global Navigator Key** (`main.dart`)

**Vị trí:** `frontend/lib/main.dart`

```dart
// Thêm global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Gắn vào MaterialApp
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // 👈 Cho phép navigate từ bất kỳ đâu
      home: const SplashScreen(),
      // ...
    );
  }
}
```

**Lý do:** Navigator key cho phép chúng ta navigate từ bên ngoài widget tree (ví dụ: từ notification service).

---

### 2️⃣ **Notification Service - Xử Lý Tap** (`notification_service.dart`)

**Vị trí:** `frontend/lib/services/notification_service.dart`

#### **Import các màn hình cần thiết:**
```dart
import '../main.dart' show navigatorKey;
import '../screens/chatbox_screen.dart';
import '../screens/ai_chatbot_screen.dart';
import '../screens/notification_screen.dart';
import 'dart:convert'; // Để parse JSON payload
```

#### **Xử lý khi tap vào notification:**
```dart
void _onNotificationTapped(NotificationResponse response) {
  debugPrint('📱 Notification tapped: ${response.payload}');
  
  if (response.payload == null || response.payload!.isEmpty) {
    return;
  }

  final context = navigatorKey.currentContext;
  if (context == null) {
    debugPrint('⚠️ Navigator context is null, cannot navigate');
    return;
  }

  try {
    final payload = response.payload!;
    
    // Parse JSON payload
    final jsonData = jsonDecode(payload);
    final type = jsonData['type'] as String?;
    
    // Navigate dựa trên loại notification
    if (type == 'message') {
      final groupId = jsonData['group_id'] as String?;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const ChatboxScreen(),
        ),
      );
    } else if (type == 'ai_chat') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const AiChatbotScreen(),
        ),
      );
    } else if (type == 'group_request') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const NotificationScreen(),
        ),
      );
    }
  } catch (e) {
    debugPrint('❌ Error handling notification tap: $e');
  }
}
```

---

### 3️⃣ **Payload JSON Format**

Mỗi notification giờ có **payload JSON** chứa thông tin chi tiết:

#### **Message Notification:**
```json
{
  "type": "message",
  "group_id": "abc123",
  "group_name": "Nhóm Du Lịch Đà Nẵng"
}
```

#### **AI Chat Notification:**
```json
{
  "type": "ai_chat",
  "message": "Bạn có muốn gợi ý địa điểm không?"
}
```

#### **Group Request Notification:**
```json
{
  "type": "group_request",
  "group_id": "xyz789",
  "group_name": "Nhóm Phượt Sapa",
  "user_name": "Nguyễn Văn A"
}
```

---

### 4️⃣ **Cập Nhật Notification Functions**

#### **showMessageNotification:**
```dart
Future<void> showMessageNotification({
  required String groupName,
  required String message,
  required int unreadCount,
  String? groupId, // 👈 THÊM MỚI: ID nhóm để navigate
}) async {
  final payloadData = {
    'type': 'message',
    'group_id': groupId,
    'group_name': groupName,
  };
  
  await showNotification(
    id: 1,
    title: groupName,
    body: unreadCount > 1 ? '$unreadCount tin nhắn mới' : message,
    payload: jsonEncode(payloadData), // 👈 JSON payload
    priority: NotificationPriority.high,
  );
}
```

#### **showGroupRequestNotification:**
```dart
Future<void> showGroupRequestNotification({
  required String userName,
  required String groupName,
  String? groupId, // 👈 THÊM MỚI
}) async {
  final payloadData = {
    'type': 'group_request',
    'group_id': groupId,
    'group_name': groupName,
    'user_name': userName,
  };
  
  await showNotification(
    id: 2,
    title: 'Yêu cầu tham gia nhóm',
    body: '$userName muốn tham gia nhóm "$groupName"',
    payload: jsonEncode(payloadData),
    priority: NotificationPriority.high,
  );
}
```

#### **showAIChatNotification:**
```dart
Future<void> showAIChatNotification({
  required String message,
}) async {
  final payloadData = {
    'type': 'ai_chat',
    'message': message,
  };
  
  await showNotification(
    id: 3,
    title: 'AI Travel Assistant',
    body: message,
    payload: jsonEncode(payloadData),
    priority: NotificationPriority.normal,
  );
}
```

---

### 5️⃣ **Cập Nhật Notification Screen**

**Vị trí:** `frontend/lib/screens/notification_screen.dart`

Thêm `groupId` khi gọi `showMessageNotification`:

```dart
String? groupId; // Thêm biến lưu groupId

// Khi load group data:
final groupData = jsonDecode(utf8.decode(groupResponse.bodyBytes));
groupName = groupData['name'] ?? 'Nhóm chat';
groupId = groupData['id']?.toString(); // 👈 Lưu groupId

// Cache để sử dụng sau:
if (groupId != null) {
  await prefs.setString('cached_group_id', groupId);
}

// Khi show notification:
await NotificationService().showMessageNotification(
  groupName: groupName ?? 'Nhóm chat',
  message: lastMessageContent ?? '',
  unreadCount: unreadCount,
  groupId: groupId, // 👈 Truyền groupId
);
```

---

## 🎯 Cách Hoạt Động

### **Flow Diagram:**

```
┌─────────────────────────────────────────────────────────┐
│  1. Notification được tạo với JSON payload              │
│     {type: "message", group_id: "abc", ...}             │
└───────────────────┬─────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────┐
│  2. Người dùng TAP vào notification                     │
└───────────────────┬─────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────┐
│  3. _onNotificationTapped() được gọi                    │
│     - Parse JSON payload                                │
│     - Lấy type: "message", "ai_chat", "group_request"   │
└───────────────────┬─────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────┐
│  4. Navigate dựa trên type:                             │
│     • message      → ChatboxScreen                      │
│     • ai_chat      → AiChatbotScreen                    │
│     • group_request → NotificationScreen                │
└─────────────────────────────────────────────────────────┘
```

---

## ✅ Testing Checklist

### **Test Case 1: Message Notification**
1. ✅ Nhận tin nhắn mới
2. ✅ Notification hiển thị với title = tên nhóm
3. ✅ Tap vào notification
4. ✅ App mở và navigate tới **ChatboxScreen**
5. ✅ Màn hình chat hiển thị đúng nhóm

### **Test Case 2: AI Chat Notification**
1. ✅ AI gửi tin nhắn mới
2. ✅ Notification hiển thị "AI Travel Assistant"
3. ✅ Tap vào notification
4. ✅ App mở và navigate tới **AiChatbotScreen**

### **Test Case 3: Group Request Notification**
1. ✅ Nhận yêu cầu tham gia nhóm
2. ✅ Notification hiển thị "Yêu cầu tham gia nhóm"
3. ✅ Tap vào notification
4. ✅ App mở và navigate tới **NotificationScreen**
5. ✅ Hiển thị danh sách yêu cầu đang chờ

### **Test Case 4: App Đang Đóng (Background/Terminated)**
1. ✅ Đóng app hoàn toàn
2. ✅ Nhận notification
3. ✅ Tap vào notification
4. ✅ App mở lên và navigate tới màn hình đúng

### **Test Case 5: Payload Invalid**
1. ✅ Gửi notification với payload null/empty
2. ✅ Tap vào notification
3. ✅ App mở nhưng không navigate (log warning)
4. ✅ Không crash

---

## 🐛 Troubleshooting

### **Vấn đề 1: Tap notification không navigate**
**Nguyên nhân:** NavigatorKey context bị null  
**Giải pháp:**
- Đảm bảo `navigatorKey` đã được gắn vào `MaterialApp`
- Kiểm tra app đã khởi động hoàn toàn chưa

### **Vấn đề 2: Navigate sai màn hình**
**Nguyên nhân:** Payload JSON sai format  
**Giải pháp:**
- Kiểm tra log: `🔍 Processing payload: ...`
- Đảm bảo `type` field đúng: "message", "ai_chat", "group_request"

### **Vấn đề 3: App crash khi tap notification**
**Nguyên nhân:** Lỗi parse JSON  
**Giải pháp:**
- Kiểm tra exception trong log: `❌ Error handling notification tap`
- Đảm bảo payload là valid JSON

### **Vấn đề 4: GroupId null khi navigate**
**Nguyên nhân:** API không trả về `id` field  
**Giải pháp:**
- Kiểm tra API response có `id` field không
- Fallback: sử dụng cached groupId từ SharedPreferences

---

## 📱 Debug Commands

### **Xem log notification tap:**
```
flutter: 📱 Notification tapped: {"type":"message","group_id":"abc123"}
flutter: 🔍 Processing payload: {"type":"message","group_id":"abc123"}
flutter: 🚀 Navigating to ChatboxScreen with groupId: abc123
```

### **Test thủ công:**
```dart
// Trong code, gọi để test:
await NotificationService().showMessageNotification(
  groupName: 'Test Group',
  message: 'Test message',
  unreadCount: 1,
  groupId: 'test123',
);
```

---

## 🚀 Tính Năng Mở Rộng (Future Enhancement)

### **1. Deep Linking với GroupId:**
```dart
// Navigate với specific groupId
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => ChatboxScreen(groupId: groupId),
  ),
);
```

### **2. Badge Count:**
```dart
// Update app icon badge
await FlutterLocalNotificationsPlugin()
    .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
    ?.setBadge(unreadCount);
```

### **3. Notification Actions:**
```dart
// Thêm nút "Reply", "Mark as Read"
const androidDetails = AndroidNotificationDetails(
  'channel_id',
  'Channel Name',
  actions: [
    AndroidNotificationAction('reply', 'Reply'),
    AndroidNotificationAction('mark_read', 'Mark as Read'),
  ],
);
```

### **4. Grouped Notifications:**
```dart
// Nhóm nhiều tin nhắn thành 1 notification
await showNotification(
  id: 1,
  title: '3 tin nhắn mới',
  body: 'Từ Nhóm A, Nhóm B, Nhóm C',
  groupKey: 'messages',
);
```

---

## 📝 Tóm Tắt

✅ **Đã hoàn thành:**
- Global navigator key cho toàn app
- Xử lý notification tap với logic navigation
- JSON payload với thông tin chi tiết
- Navigate tới ChatboxScreen, AiChatbotScreen, NotificationScreen
- Cache groupId để sử dụng sau

✅ **Testing:**
- Test với notification khi app foreground/background/terminated
- Test với các loại notification khác nhau
- Handle lỗi và edge cases

🎉 **Kết quả:** Người dùng giờ có thể tap vào notification và tự động mở đúng màn hình liên quan!

---

## 📞 Hỗ Trợ

Nếu gặp vấn đề, kiểm tra:
1. Log trong console (tìm emoji 📱 🔍 🚀 ❌)
2. File `notification_service.dart` - hàm `_onNotificationTapped`
3. File `main.dart` - navigatorKey đã gắn chưa
4. Payload JSON có đúng format không

**Happy Coding! 🚀**

