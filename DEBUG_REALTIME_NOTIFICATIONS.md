# 🐛 Debug Real-time Notifications - Hướng Dẫn Chi Tiết

## ⚠️ Vấn Đề

**Triệu chứng:** Đã gửi tin nhắn từ device khác nhưng không nhận được notification real-time.

## 🔍 Cách Kiểm Tra & Debug

### **Bước 1: Kiểm Tra Log Console**

Khi chạy app, hãy xem **Console** (Debug Console trong IDE) để tìm các log sau:

#### **1.1. Khi app khởi động:**
```
🚀 ===== STARTING BACKGROUND NOTIFICATION SERVICE =====
📋 Token: eyJhbGciOiJIUzI1NiIs...
👤 User ID: 550e8400-e29b-41d4-a716-446655440000
🔌 Connecting background WebSocket...
   URL: ws://10.132.240.17:8000/chat/ws?token=...
✅ WebSocket channel created, waiting for connection...
✅ Background notification service started successfully
   Listening for messages...
```

**✅ Nếu thấy logs này:** Service đã start thành công, WebSocket đang chạy.

**❌ Nếu KHÔNG thấy logs này:** 
- Service chưa start → Kiểm tra `main_app_screen.dart` có gọi `_startBackgroundNotificationService()` không
- Token hoặc User ID null → Kiểm tra SharedPreferences

#### **1.2. Khi có tin nhắn mới:**
```
📥 ===== WEBSOCKET MESSAGE RECEIVED =====
   Raw message: {"sender_id":"abc-123","content":"Hello","message_type":"text",...}
📬 Processing WebSocket message...
   Decoded JSON: {sender_id: abc-123, content: Hello, ...}
   Sender ID: abc-123
   Current User ID: xyz-456
   Content: Hello
   Message Type: text
   ✅ Message from other user, sending notification...
   Group name: Nhóm Du Lịch
   Sending notification:
   - Title: Nhóm Du Lịch
   - Body: Hello
   ✅ System notification sent successfully!
```

**✅ Nếu thấy logs này:** Notification đã được gửi thành công!

**❌ Nếu KHÔNG thấy logs này:**
- WebSocket không nhận được message → Kiểm tra backend
- Message bị filter (tin nhắn của chính mình) → Check sender_id

---

### **Bước 2: Kiểm Tra Permission**

#### **Android:**
```
Settings → Apps → Travel Together → Notifications
```
✅ Phải bật ON

#### **iOS:**
```
Settings → Travel Together → Notifications
```
✅ Phải Allow Notifications

---

### **Bước 3: Test Từng Phần**

#### **Test 1: Background Service Start**

**File:** `lib/screens/main_app_screen.dart`

**Code:**
```dart
Future<void> _startBackgroundNotificationService() async {
  try {
    await BackgroundNotificationService().start();
    debugPrint('✅ Background notification service started successfully');
  } catch (e) {
    debugPrint('❌ Error starting background notification service: $e');
  }
}
```

**Expected Log:**
```
✅ Background notification service started successfully
```

**Nếu không thấy:** Service không được gọi → Check `initState()` có gọi `_startBackgroundNotificationService()` không.

---

#### **Test 2: WebSocket Connection**

**Kiểm tra log:**
```
🔌 Connecting background WebSocket...
   URL: ws://10.132.240.17:8000/chat/ws?token=...
✅ WebSocket channel created, waiting for connection...
```

**Nếu thấy lỗi:**
```
❌ Background WebSocket error: ...
```

**Nguyên nhân có thể:**
1. **Token expired** → Login lại
2. **Network issue** → Check WiFi/Mobile data
3. **Backend down** → Check backend server đang chạy chưa
4. **URL sai** → Check `ApiConfig.chatWebSocket`

**Fix:**
```dart
// Trong api_config.dart
static const String chatWebSocket = 'ws://10.132.240.17:8000/chat/ws';
```

---

#### **Test 3: Message Reception**

**Gửi tin nhắn test:**
1. Mở app trên Device A (login User A)
2. Mở app trên Device B (login User B)
3. User A gửi tin nhắn "Test 123"

**Expected log trên Device B:**
```
📥 ===== WEBSOCKET MESSAGE RECEIVED =====
   Raw message: {"sender_id":"user_a_id","content":"Test 123",...}
📬 Processing WebSocket message...
   Sender ID: user_a_id
   Current User ID: user_b_id
   Content: Test 123
   ✅ Message from other user, sending notification...
```

**Nếu KHÔNG thấy log này:**

**Nguyên nhân 1: WebSocket không nhận message**
- Check backend có broadcast message qua WebSocket không
- Check backend logs

**Nguyên nhân 2: Message bị filter (sender = current user)**
```
   ⏩ Skipping: Message from self or empty sender
```
- Đang test với cùng 1 user trên 2 device
- Fix: Dùng 2 user khác nhau

---

#### **Test 4: Notification Gửi Đi**

**Expected log:**
```
   Sending notification:
   - Title: Nhóm Du Lịch
   - Body: Test 123
   ✅ System notification sent successfully!
```

**Nếu thấy log này NHƯNG không có notification xuất hiện:**

**Nguyên nhân 1: Permission chưa granted**
```dart
final granted = await NotificationService().checkPermission();
debugPrint('Permission granted: $granted');
```

**Fix:** Vào Settings → bật notification

**Nguyên nhân 2: NotificationService chưa initialize**
```dart
await NotificationService().initialize();
```

**Fix:** Check `main.dart` có khởi tạo NotificationService chưa

**Nguyên nhân 3: Channel ID sai (Android)**
- Check `notification_service.dart` có tạo channel đúng không
- Channel ID: `travel_together_channel`

---

### **Bước 4: Debug WebSocket Connection**

#### **Thêm log vào chatbox_screen.dart:**

Để so sánh, xem WebSocket của chatbox có nhận message không:

```dart
// Trong chatbox_screen.dart
void _handleWebSocketMessage(dynamic message) {
  debugPrint('🟦 CHATBOX WebSocket message: $message');
  // ...existing code...
}
```

**So sánh:**
- ✅ Chatbox nhận được message → Backend OK
- ✅ Background service CŨNG nhận được message → Everything OK
- ❌ Background service KHÔNG nhận → Background WebSocket có vấn đề

---

### **Bước 5: Test Manual Notification**

**Thêm button test trong UI:**

```dart
// Trong main_app_screen.dart hoặc settings
ElevatedButton(
  onPressed: () async {
    await NotificationService().showNotification(
      id: 999,
      title: 'Test Notification',
      body: 'This is a manual test',
      payload: 'test',
    );
  },
  child: Text('Test Notification'),
)
```

**Bấm button:**
- ✅ Notification xuất hiện → NotificationService hoạt động tốt
- ❌ Không xuất hiện → Permission hoặc NotificationService có vấn đề

---

## 🔧 Các Lỗi Thường Gặp & Giải Pháp

### **Lỗi 1: Service không start**

**Log:**
```
(Không có log gì cả)
```

**Nguyên nhân:**
- `_startBackgroundNotificationService()` không được gọi trong `initState()`

**Fix:**
```dart
@override
void initState() {
  super.initState();
  _selectedIndex = widget.initialIndex;
  _startBackgroundNotificationService(); // ← Phải có dòng này
  _requestNotificationPermission();
}
```

---

### **Lỗi 2: Token null**

**Log:**
```
❌ Cannot start notification service: No token or user ID
   Token exists: false
   User ID exists: true
```

**Nguyên nhân:**
- Chưa login hoặc token expired

**Fix:**
1. Login lại
2. Check SharedPreferences có lưu `access_token` không

---

### **Lỗi 3: WebSocket timeout/error**

**Log:**
```
❌ Background WebSocket error: WebSocketChannelException: ...
```

**Nguyên nhân:**
- Backend không chạy
- Network issue
- Firewall block

**Fix:**
1. Check backend server: `http://10.132.240.17:8000/` có accessible không
2. Check WiFi/Mobile data
3. Try reconnect (tự động sau 5s)

---

### **Lỗi 4: Message không trigger notification**

**Log:**
```
📥 ===== WEBSOCKET MESSAGE RECEIVED =====
   ...
   ⏩ Skipping: Message from self or empty sender
```

**Nguyên nhân:**
- `sender_id` == `current_user_id` (đang test với cùng 1 user)

**Fix:**
- Dùng 2 user khác nhau để test
- User A gửi → User B nhận notification

---

### **Lỗi 5: Notification không xuất hiện dù log OK**

**Log:**
```
   ✅ System notification sent successfully!
```

**NHƯNG:** Notification không xuất hiện ở notification bar

**Nguyên nhân:**
1. **Permission chưa granted**
2. **Do Not Disturb mode** (Android)
3. **Focus mode** (iOS)
4. **Battery Saver** đã kill app notification

**Fix:**
1. Settings → Notifications → Bật ON
2. Tắt Do Not Disturb
3. Tắt Battery Saver
4. Restart app

---

## 📱 Test Checklist

- [ ] **1. Backend đang chạy** (`http://10.132.240.17:8000/`)
- [ ] **2. App đã login thành công**
- [ ] **3. Permission notification đã granted**
- [ ] **4. Log service start thấy:** `✅ Background notification service started`
- [ ] **5. Log WebSocket connect:** `✅ WebSocket channel created`
- [ ] **6. Dùng 2 user khác nhau để test**
- [ ] **7. User A gửi tin nhắn**
- [ ] **8. Log trên Device B:** `📥 WEBSOCKET MESSAGE RECEIVED`
- [ ] **9. Log notification sent:** `✅ System notification sent successfully!`
- [ ] **10. Notification xuất hiện ở notification bar**

---

## 🎯 Quick Fix Steps

Nếu notification vẫn không hoạt động sau khi check hết, làm theo thứ tự:

### **Step 1: Clean & Rebuild**
```bash
cd frontend
flutter clean
flutter pub get
flutter run
```

### **Step 2: Uninstall & Reinstall**
```bash
# Uninstall app cũ trên device
# Rồi chạy lại
flutter run
```

### **Step 3: Check Backend**
```bash
# Trên backend, check logs khi User A gửi tin nhắn
# Phải thấy WebSocket broadcast message
```

### **Step 4: Test Manual Notification**
```dart
// Thêm button test vào UI
await NotificationService().showNotification(
  id: 999,
  title: 'Test',
  body: 'Manual test',
);
```

### **Step 5: Enable All Logs**
```dart
// Mở tất cả debug logs
debugPrint('...');
```

Chạy app và xem **Console** để debug.

---

## 📞 Contact & Support

Nếu vẫn không hoạt động sau khi thử tất cả:

1. **Copy toàn bộ logs** từ Console
2. **Screenshot** notification settings
3. **Note** steps đã làm
4. Liên hệ support với thông tin trên

---

**Happy Debugging!** 🐛🔧

