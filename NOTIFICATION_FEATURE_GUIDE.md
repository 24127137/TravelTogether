# 🔔 Hướng Dẫn Tính Năng Thông Báo (Notification)

## 📋 Tổng Quan

Đã tích hợp thông báo tin nhắn mới từ group chat vào màn hình Notification. Hệ thống sẽ:
- Tự động đếm số tin nhắn chưa đọc
- Hiển thị tên nhóm và thời gian tin nhắn cuối
- Hiển thị badge đỏ với số lượng tin nhắn chưa đọc

## ✅ Những Gì Đã Làm

### 1. **Chuyển NotificationScreen sang StatefulWidget**
- Thêm logic load dữ liệu từ API
- Tích hợp với SharedPreferences ��ể tracking tin nhắn đã seen

### 2. **Load Thông Báo Tin Nhắn Mới**

#### **API Endpoints sử dụng:**
- `GET /chat/history` - Lấy lịch sử chat
- `GET /groups/my-group` - Lấy tên nhóm

#### **Logic đếm tin nhắn chưa đọc:**
```dart
// Lặp qua messages từ cuối về đầu
for (var msg in messages.reversed) {
  final senderId = msg['sender_id'];
  final messageId = msg['id'];
  final isMyMessage = (senderId == currentUserId);
  
  // Nếu không phải tin nhắn của mình và chưa seen
  if (!isMyMessage) {
    if (lastSeenMessageId == null || messageId != lastSeenMessageId) {
      unreadCount++;
    } else {
      // Đã gặp tin nhắn đã seen, dừng đếm
      break;
    }
  }
}
```

### 3. **Hiển Thị Thông Báo**

#### **Khi có tin nhắn chưa đọc:**
- Icon: Message icon với background màu `#E0CEC0`
- Badge đỏ: Hiển thị số lượng (tối đa "99+")
- Title: Tên nhóm (lấy từ API `/groups/my-group`)
- Subtitle: 
  - "1 tin nhắn mới" (nếu 1 tin)
  - "X tin nhắn mới" (nếu nhiều tin)
- Time: Format thời gian thân thiện
  - "Vừa xong" (< 1 phút)
  - "X phút trước" (< 1 giờ)
  - "X giờ trước" (< 24 giờ)
  - "X ngày trước" (< 7 ngày)
  - "dd/MM/yyyy" (> 7 ngày)

#### **Khi không có tin nhắn chưa đọc:**
- Hiển thị icon và text "Không có thông báo mới"

### 4. **Mock Data**
- Đã comment lại mock data cũ
- Mock data vẫn giữ trong code để test sau này nếu cần
- Bỏ comment dòng 120-135 để hiện mock data

## 🎨 UI Components

### **NotificationData Model:**
```dart
class NotificationData {
  final String icon;
  final String title;
  final String? subtitle;
  final NotificationType type;
  final String? time;           // ✨ MỚI: Thời gian
  final int? unreadCount;       // ✨ MỚI: Số tin chưa đọc
}
```

### **NotificationItem Widget:**
- Container với background `#B99668`
- Border radius: 40
- Padding: 20 horizontal, 16 vertical
- Stack với badge đỏ hiển thị số tin nhắn chưa đọc
- Column hiển thị title, subtitle và time

## 🔄 Flow Hoạt Động

### **1. User nhận tin nhắn mới từ người khác:**
```
messages_screen.dart
  ↓
lastSeenMessageId được lưu khi vào chatbox_screen
  ↓
notification_screen.dart load chat history
  ↓
So sánh message IDs với lastSeenMessageId
  ↓
Đếm số tin nhắn chưa seen
  ↓
Hiển thị badge + thông báo
```

### **2. User vào chatbox_screen:**
```
chatbox_screen.dart
  ↓
_loadChatHistory() được gọi
  ↓
lastSeenMessageId được update (tin nhắn cuối)
  ↓
SharedPreferences.setString('last_seen_message_id', ...)
  ↓
Quay lại notification_screen
  ↓
Reload → Không còn thông báo (đã seen)
```

## 📊 Test Cases

### **Test 1: Tin nhắn mới từ người khác**
1. User A gửi tin nhắn
2. User B chưa vào chat
3. Vào Notification screen
4. ✅ Phải hiển thị: "Nhóm chat - 1 tin nhắn mới" + badge "1"

### **Test 2: Nhiều tin nhắn chưa đọc**
1. User A gửi 5 tin nhắn
2. User B chưa vào chat
3. Vào Notification screen
4. ✅ Phải hiển thị: "Nhóm chat - 5 tin nhắn mới" + badge "5"

### **Test 3: Đã seen rồi**
1. User B vào chatbox_screen
2. Quay lại notification_screen
3. ✅ Không còn thông báo

### **Test 4: Tin nhắn của chính mình**
1. User B gửi tin nhắn
2. Vào notification_screen
3. ✅ Không có thông báo (vì là tin nhắn của mình)

## 🐛 Debug

### **Kiểm tra SharedPreferences:**
```dart
// Trong chatbox_screen.dart
print('💾 Saved last_seen_message_id: $lastMessageId');

// Trong notification_screen.dart
print('📬 Group chat - lastMessageId: ${lastMsg['id']}, lastSeenId: $lastSeenMessageId, hasUnseen: $hasUnseen');
```

### **Log kết quả:**
- `✅ Group members loaded: X members` - Load group thành công
- `📬 Group chat - ...` - Kiểm tra trạng thái seen/unseen
- `Error loading chat notifications: ...` - Lỗi khi load

## 🎯 Tính Năng Tương Lai (Optional)

1. **Click vào thông báo → Mở chatbox_screen**
2. **Mark as read button** - Đánh dấu đã đọc không cần vào chat
3. **Push Notification** - Thông báo real-time khi có tin nhắn mới
4. **Notification cho Group Join/Leave**
5. **Notification cho AI Chatbot response**

## 📝 Notes

- Mock data đã được comment, có thể bỏ comment dòng 120-135 để test UI
- Notification screen tự động reload khi có thay đổi
- Tích hợp hoàn toàn với tính năng seen/unseen trong messages_screen
- Badge màu đỏ nổi bật, hiển thị tối đa "99+"

---

**Version:** 1.0  
**Last Updated:** 2025-01-XX  
**Status:** ✅ Hoàn thành

