# 🧪 TESTING CHECKLIST - Notification Navigation

## 📱 Chuẩn Bị Test

- [ ] Build app mới nhất: `flutter run`
- [ ] Bật quyền notification trên điện thoại
- [ ] Đảm bảo có backend đang chạy
- [ ] Login vào app

---

## ✅ Test Case 1: Message Notification (Foreground)

**Mục tiêu:** Test tap notification tin nhắn khi app đang mở

### Bước thực hiện:
1. [ ] Mở app, login thành công
2. [ ] Vào màn hình Messages
3. [ ] Để 1 người khác gửi tin nhắn vào nhóm (hoặc tự gửi từ thiết bị khác)
4. [ ] Notification xuất hiện
5. [ ] **TAP vào notification**

### Kết quả mong đợi:
- [ ] App navigate tới **ChatboxScreen**
- [ ] Hiển thị đúng nhóm chat
- [ ] Console log: `🚀 Navigating to ChatboxScreen with groupId: ...`

---

## ✅ Test Case 2: Message Notification (Background)

**Mục tiêu:** Test tap notification khi app đang chạy nền

### Bước thực hiện:
1. [ ] Mở app, login
2. [ ] Nhấn Home button (app vào background)
3. [ ] Gửi tin nhắn vào nhóm (từ thiết bị khác)
4. [ ] Notification xuất hiện trên notification tray
5. [ ] **TAP vào notification**

### Kết quả mong đợi:
- [ ] App quay lại foreground
- [ ] Navigate tới **ChatboxScreen**
- [ ] Hiển thị đúng nhóm chat

---

## ✅ Test Case 3: Message Notification (App Terminated)

**Mục tiêu:** Test tap notification khi app đã đóng hoàn toàn

### Bước thực hiện:
1. [ ] Login vào app
2. [ ] **ĐÓNG APP** hoàn toàn (swipe kill từ recent apps)
3. [ ] Gửi tin nhắn vào nhóm (từ thiết bị khác)
4. [ ] Notification xuất hiện
5. [ ] **TAP vào notification**

### Kết quả mong đợi:
- [ ] App khởi động lại
- [ ] Sau khi login (nếu cần), navigate tới **ChatboxScreen**
- [ ] Hiển thị đúng nhóm chat

---

## ✅ Test Case 4: AI Chat Notification

**Mục tiêu:** Test tap notification AI chatbot

### Bước thực hiện:
1. [ ] Mở app
2. [ ] Trigger AI notification (gửi message tới AI)
3. [ ] Notification "AI Travel Assistant" xuất hiện
4. [ ] **TAP vào notification**

### Kết quả mong đợi:
- [ ] Navigate tới **AiChatbotScreen**
- [ ] Màn hình AI chat hiển thị đúng
- [ ] Console log: `🚀 Navigating to AiChatbotScreen`

---

## ✅ Test Case 5: Group Request Notification

**Mục tiêu:** Test tap notification yêu cầu tham gia nhóm

### Bước thực hiện:
1. [ ] Có người gửi yêu cầu tham gia nhóm
2. [ ] Notification "Yêu cầu tham gia nhóm" xuất hiện
3. [ ] **TAP vào notification**

### Kết quả mong đợi:
- [ ] Navigate tới **NotificationScreen**
- [ ] Hiển thị danh sách notifications
- [ ] Console log: `🚀 Navigating to NotificationScreen`

---

## ✅ Test Case 6: Payload Empty/Invalid

**Mục tiêu:** Test xử lý lỗi khi payload không hợp lệ

### Bước thực hiện:
1. [ ] Manually trigger notification với payload null/empty (test code)
2. [ ] **TAP vào notification**

### Kết quả mong đợi:
- [ ] App mở nhưng KHÔNG navigate (giữ nguyên màn hình hiện tại)
- [ ] Console log: `⚠️ No payload found in notification`
- [ ] App **KHÔNG crash**

---

## ✅ Test Case 7: Multiple Notifications

**Mục tiêu:** Test tap vào notification khi có nhiều notification

### Bước thực hiện:
1. [ ] Nhận 3 notifications (message, AI, group request)
2. [ ] **TAP vào notification thứ 2** (AI chat)

### Kết quả mong đợi:
- [ ] Navigate tới **AiChatbotScreen** (đúng notification đã tap)
- [ ] Các notification khác vẫn còn trong notification tray

---

## 🐛 Error Testing

### Test 1: Navigator Context Null
- [ ] Log `⚠️ Navigator context is null` xuất hiện khi cần
- [ ] App không crash

### Test 2: JSON Parse Error
- [ ] Gửi notification với payload không phải JSON
- [ ] Log `⚠️ Failed to parse JSON payload` xuất hiện
- [ ] App không crash

### Test 3: Unknown Payload Type
- [ ] Gửi notification với type không tồn tại
- [ ] Log `⚠️ Unknown payload type` xuất hiện
- [ ] App không crash

---

## 📊 Performance Testing

- [ ] Thời gian navigate < 500ms
- [ ] Không lag khi tap notification
- [ ] Memory không leak sau nhiều lần tap

---

## 📱 Device Testing

### Android:
- [ ] Android 10
- [ ] Android 11
- [ ] Android 12
- [ ] Android 13+ (notification permission)

### iOS:
- [ ] iOS 14
- [ ] iOS 15
- [ ] iOS 16+

---

## 📝 Debug Commands

### Xem logs realtime:
```bash
flutter logs | grep -E "📱|🔍|🚀|❌|⚠️"
```

### Test thủ công trong code:
```dart
// Trong dev mode, thêm vào onPressed của button:
await NotificationService().showMessageNotification(
  groupName: 'Test Group',
  message: 'Test message',
  unreadCount: 1,
  groupId: 'test123',
);
```

### Clear tất cả notifications:
```dart
await NotificationService().cancelAllNotifications();
```

---

## ✅ Final Checklist

Tính năng được coi là **PASS** khi:

- [ ] ✅ Tất cả test cases PASS
- [ ] ✅ Không có crash trong mọi trường hợp
- [ ] ✅ Navigate đúng màn hình 100% thời gian
- [ ] ✅ Logs hiển thị đầy đủ thông tin debug
- [ ] ✅ Performance tốt (không lag)
- [ ] ✅ Hoạt động trên cả Android và iOS

---

## 📞 Nếu Test FAIL

1. **Check logs:** Tìm emoji 📱 🔍 🚀 ❌ ⚠️
2. **Verify payload:** In ra `response.payload` trong console
3. **Check navigatorKey:** Đảm bảo đã gắn vào MaterialApp
4. **Check imports:** Tất cả screens đã import đúng
5. **Rebuild app:** `flutter clean && flutter run`

---

## 🎉 Success Criteria

**PASS nếu:**
- User tap notification → Đúng màn hình hiển thị
- Không crash trong mọi trường hợp
- Logs đầy đủ và dễ debug

**Status:** [ ] PASS / [ ] FAIL

**Tested By:** _________________  
**Date:** _________________  
**Notes:** _________________

---

**Good Luck! 🚀**

