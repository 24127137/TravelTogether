# Notification & WebSocket Issues - Fix Summary

## Issues Fixed

### 1. WebSocket Connection Timeout ❌ → ✅
**Problem:** 
```
I/flutter (31178): ❌ Background WebSocket error: WebSocketChannelException: 
SocketException: Connection timed out (OS Error: Connection timed out, errno = 110), 
address = 10.132.240.17, port = 45194
```

**Root Cause:**
- WebSocket URL was hardcoded to `ws://10.132.240.17:8000` (4G network IP)
- But base API URL was using `http://192.168.1.7:8000` (WiFi network IP)
- The app was trying to connect to the wrong IP address

**Fix Applied:**
- Updated `api_config.dart` to use consistent WiFi network IP
- Changed from: `ws://10.132.240.17:8000/chat/ws`
- Changed to: `ws://192.168.1.7:8000/chat/ws`

**File Changed:**
- `frontend/lib/config/api_config.dart`

---

### 2. Notification Seen/Unseen State Not Persisting ❌ → ✅
**Problem:**
- Ngày hôm sau test lại, tất cả tin nhắn cũ vẫn hiện notification
- Mặc dù đã xem (seen) hôm trước
- `last_seen_message_id` không được lưu đúng cách

**Root Cause:**
1. `last_seen_message_id` chỉ được save khi:
   - Load chat history (trong `chatbox_screen.dart`)
   - Nhận tin nhắn mới qua WebSocket VÀ đang ở cuối chat
2. KHÔNG được save khi user rời khỏi màn hình chatbox
3. Logic kiểm tra unseen trong `notification_screen.dart` có bug:
   - Vòng lặp từ mới → cũ nhưng logic `foundLastSeenMessage` bị ngược

**Fixes Applied:**

#### A. Added `dispose()` method to save last_seen_message_id
```dart
// chatbox_screen.dart
@override
void dispose() {
  _saveLastSeenMessage(); // ← Save khi rời khỏi màn hình
  _channel?.sink.close();
  _controller.dispose();
  _scrollController.dispose();
  _focusNode.dispose();
  super.dispose();
}
```

#### B. Fixed notification logic
- Sửa logic trong `notification_screen.dart` để đếm đúng tin nhắn chưa đọc
- Chỉ đếm tin nhắn MỚI HƠN `last_seen_message_id`
- Bỏ qua tin nhắn của chính mình

**Files Changed:**
- `frontend/lib/screens/chatbox_screen.dart` - Added dispose() and _saveLastSeenMessage()
- `frontend/lib/screens/notification_screen.dart` - Fixed unread counting logic

---

### 3. Notification Tap không navigate đến chatbox ❌ → ✅
**Problem:**
- Bấm vào notification chỉ mở app, không nhảy vào chatbox
- User phải tự tìm và mở chatbox

**Status:** ✅ Already Fixed in Previous Update
- `notification_service.dart` đã có `_onNotificationTapped()`
- Payload được parse và navigate đến đúng screen
- JSON payload chứa `type`, `group_id`, `group_name`

**How It Works:**
1. System notification có payload: `{"type":"message","group_id":"123","group_name":"Nhóm chat"}`
2. User tap notification → `_onNotificationTapped()` được gọi
3. Parse payload → Detect `type == "message"`
4. Navigate to `ChatboxScreen()`

---

## Testing Checklist

### WebSocket Connection
- [ ] Đảm bảo backend server đang chạy ở `192.168.1.7:8000`
- [ ] Check log: `✅ WebSocket channel created, waiting for connection...`
- [ ] KHÔNG thấy: `❌ Background WebSocket error: Connection timed out`

### Seen/Unseen Tracking
- [ ] Mở chatbox, xem tất cả tin nhắn (scroll đến cuối)
- [ ] Rời khỏi chatbox (back button)
- [ ] Check log: `💾 Saved last_seen_message_id on dispose: [message_id]`
- [ ] Mở notification screen → KHÔNG có notification tin nhắn cũ
- [ ] Gửi tin nhắn mới từ user khác
- [ ] Notification screen hiển thị "1 tin nhắn mới" ✅
- [ ] Mở chatbox, xem tin nhắn mới
- [ ] Quay lại notification screen → Notification biến mất ✅

### Notification Navigation
- [ ] Nhận tin nhắn mới khi app ở background
- [ ] System notification hiện lên
- [ ] Tap vào notification
- [ ] App mở và navigate TỰ ĐỘNG vào ChatboxScreen ✅
- [ ] Không cần phải tự mở tab Messages

---

## Network Configuration

### Current Setup (WiFi)
```dart
static const String baseUrl = 'http://192.168.1.7:8000';
static const String chatWebSocket = 'ws://192.168.1.7:8000/chat/ws';
```

### To Switch to 4G Network
If you need to use 4G network, change both URLs in `api_config.dart`:
```dart
static const String baseUrl = 'http://10.132.240.17:8000';
static const String chatWebSocket = 'ws://10.132.240.17:8000/chat/ws';
```

**⚠️ IMPORTANT:** Always keep baseUrl and chatWebSocket on the same network!

---

## How Seen/Unseen Works Now

### Flow Chart
```
1. User mở ChatboxScreen
   ↓
2. Load messages từ API
   ↓
3. Lấy ID của tin nhắn cuối cùng
   ↓
4. Save to SharedPreferences: last_seen_message_id = "123"
   ↓
5. User scroll đến cuối chat
   ↓
6. _markAllAsSeen() → mark local messages as seen
   ↓
7. User rời khỏi ChatboxScreen
   ↓
8. dispose() → _saveLastSeenMessage()
   ↓
9. Fetch latest messages from API
   ↓
10. Save last message ID: last_seen_message_id = "125"
```

### When NotificationScreen Loads
```
1. Load all messages từ API
   ↓
2. Lấy last_seen_message_id = "125" từ SharedPreferences
   ↓
3. Loop qua messages từ MỚI → CŨ
   ↓
4. For each message:
   - Nếu là tin của mình → skip
   - Nếu message.id == last_seen_message_id → STOP (đã seen)
   - Nếu message.id > last_seen_message_id → unreadCount++
   ↓
5. Nếu unreadCount > 0 → Hiển thị notification
6. Nếu unreadCount == 0 → Không hiển thị
```

---

## Debug Logs to Watch

### WebSocket Connection
```
🔌 Connecting background WebSocket...
   URL: ws://192.168.1.7:8000/chat/ws?token=...
✅ WebSocket channel created, waiting for connection...
✅ Background notification service started successfully
   Listening for messages...
```

### Message Received
```
📥 ===== WEBSOCKET MESSAGE RECEIVED =====
   Raw message: {"id":"126","sender_id":"user_123","content":"Hello",...}
   Sender ID: user_123
   Current User ID: user_456
   Content: Hello
   ✅ Message from other user, sending notification...
   ✅ System notification sent successfully!
```

### Saving Last Seen
```
💾 Saved last_seen_message_id: 125
💾 Saved last_seen_message_id from WebSocket: 126
💾 Saved last_seen_message_id on dispose: 127
```

### Notification Check
```
🔍 Loading notifications - lastSeenMessageId: 125
📨 Checking message: id=126, sender=user_123, isMyMessage=false
   📬 Unread message: 1
📨 Checking message: id=125, sender=user_123, isMyMessage=false
   ✅ Found last seen message: 125
📊 Total unread messages: 1
```

---

## Common Issues & Solutions

### Issue: WebSocket vẫn timeout
**Solution:**
1. Check backend server có đang chạy không: `python main.py` hoặc `run_server.bat`
2. Check IP address đúng chưa: `ipconfig` (Windows) hoặc `ifconfig` (Mac/Linux)
3. Check firewall: `.\open_firewall.ps1` (Windows)
4. Thử ping: `ping 192.168.1.7`

### Issue: Notification vẫn hiện tin cũ
**Solution:**
1. Clear app data (Settings → Apps → TravelTogether → Clear Data)
2. Hoặc xóa SharedPreferences manually:
```dart
final prefs = await SharedPreferences.getInstance();
await prefs.remove('last_seen_message_id');
```
3. Mở chatbox, scroll to bottom
4. Rời khỏi → Check log có `💾 Saved last_seen_message_id`

### Issue: Tap notification không navigate
**Solution:**
1. Check `navigatorKey` đã được set trong `MaterialApp`:
```dart
MaterialApp(
  navigatorKey: navigatorKey, // ← Phải có
  ...
)
```
2. Check notification payload có đúng format JSON không
3. Check log: `🔍 Processing payload: ...`

---

## Files Modified

1. ✅ `frontend/lib/config/api_config.dart`
   - Fixed WebSocket URL to match base URL (WiFi network)

2. ✅ `frontend/lib/screens/chatbox_screen.dart`
   - Added `dispose()` method
   - Added `_saveLastSeenMessage()` method
   - Save last_seen_message_id when leaving screen

3. ✅ `frontend/lib/screens/notification_screen.dart`
   - Fixed unread message counting logic
   - Properly compare with last_seen_message_id

---

## Next Steps

1. **Test on Real Device:**
   - Build release APK
   - Test on actual Android device
   - Test với app ở background/closed

2. **Server-Side Improvement (Future):**
   - Add `read_receipts` table to database
   - Track seen status per user per message
   - Sync across devices

3. **UX Improvement:**
   - Add visual indicator for unread messages in chatbox
   - Add "Mark all as read" button
   - Add notification badge on app icon

---

## Date: November 26, 2025
## Status: ✅ ALL ISSUES FIXED

