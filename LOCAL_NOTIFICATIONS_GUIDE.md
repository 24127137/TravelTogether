# 🔔 Hướng Dẫn Local Notifications - Travel Together App

## 📋 Tổng Quan

Đã tích hợp hoàn chỉnh hệ thống Local Notifications cho app Travel Together, hỗ trợ:
- ✅ **Android** (bao gồm Android 13+ với runtime permission)
- ✅ **iOS** (với đầy đủ permissions)
- ✅ **Thông báo tin nhắn mới từ group chat**
- ✅ **Thông báo yêu cầu tham gia nhóm**
- ✅ **Thông báo từ AI chatbot**
- ✅ **Scheduled notifications** (thông báo hẹn giờ)
- ✅ **Dialog xin quyền đẹp mắt với giải thích rõ ràng**

---

## 🎯 Tính Năng Chính

### 1. **NotificationService** (Singleton Pattern)
```dart
// Khởi tạo (đã tự động trong main.dart)
await NotificationService().initialize();

// Xin quyền thông báo
final granted = await NotificationService().requestPermission();

// Gửi thông báo ngay lập tức
await NotificationService().showNotification(
  id: 1,
  title: 'Tiêu đề',
  body: 'Nội dung',
  payload: 'data',
  priority: NotificationPriority.high,
);

// Gửi thông báo tin nhắn
await NotificationService().showMessageNotification(
  groupName: 'Nhóm Du Lịch',
  message: 'Có tin nhắn mới',
  unreadCount: 3,
);

// Hủy thông báo
await NotificationService().cancelNotification(1);
await NotificationService().cancelAllNotifications();
```

### 2. **NotificationPermissionDialog**
- Dialog đẹp với UI theme app
- Giải thích rõ ràng tại sao cần quyền
- Liệt kê tất cả tính năng cần thông báo
- Gửi notification test sau khi cấp quyền

```dart
// Hiển thị dialog xin quyền
final granted = await NotificationPermissionDialog.show(context);
```

### 3. **Tích hợp vào App Flow**

#### **main.dart:**
- Tự động khởi tạo `NotificationService` khi app start
- Khởi tạo timezone database

#### **main_app_screen.dart:**
- Hiển thị dialog xin quyền **1 lần duy nhất** sau khi vào app
- Lưu trạng thái đã hỏi vào SharedPreferences (`notification_permission_asked`)
- Delay 1 giây để UI load xong trước khi hiện dialog

#### **notification_screen.dart:**
- Tự động gửi **system notification** khi có tin nhắn chưa đọc
- Notification sẽ xuất hiện ở **notification bar** của điện thoại
- User tap vào notification → mở app (tính năng navigation sẽ thêm sau)

---

## 🛠️ Cấu Hình

### **Android Configuration**

#### 1. **build.gradle.kts** (App level) ✅ QUAN TRỌNG
```kotlin
android {
    // ...existing code...
    
    compileOptions {
        // Enable Core Library Desugaring (REQUIRED!)
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
}

dependencies {
    // Add desugar library
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
```

**⚠️ QUAN TRỌNG:** Nếu không thêm config này, build sẽ lỗi:
```
Dependency ':flutter_local_notifications' requires core library desugaring
```

#### 2. **AndroidManifest.xml** (Đã cấu hình)
```xml
<!-- Permissions -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>

<!-- Receivers -->
<receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        ...
    </intent-filter>
</receiver>
```

#### 3. **Channel Configuration**
- Channel ID: `travel_together_channel`
- Channel Name: `Travel Together Notifications`
- Importance: `MAX` (hiển thị heads-up notification)
- Sound: ✅ Enabled
- Vibration: ✅ Enabled

### **iOS Configuration**

#### 1. **Info.plist** (Cần thêm nếu chưa có)
```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

#### 2. **Permissions**
- Alert: ✅ Yes
- Badge: ✅ Yes
- Sound: ✅ Yes

---

## 📱 Các Loại Notification

### 1. **Message Notification**
```dart
await NotificationService().showMessageNotification(
  groupName: 'Nhóm Du Lịch Sài Gòn',
  message: 'Chào mọi người!',
  unreadCount: 5,
);
```
- **ID cố định**: `1`
- **Title**: Tên nhóm
- **Body**: 
  - 1 tin nhắn: Hiển thị nội dung
  - Nhiều tin: "X tin nhắn mới"
- **Payload**: `'message'`

### 2. **Group Request Notification**
```dart
await NotificationService().showGroupRequestNotification(
  userName: 'Nguyễn Văn A',
  groupName: 'Nhóm Du Lịch',
);
```
- **ID cố định**: `2`
- **Title**: "Yêu cầu tham gia nhóm"
- **Body**: "Nguyễn Văn A muốn tham gia nhóm..."
- **Payload**: `'group_request'`

### 3. **AI Chat Notification**
```dart
await NotificationService().showAIChatNotification(
  message: 'Tôi đã tìm thấy 5 địa điểm phù hợp...',
);
```
- **ID cố định**: `3`
- **Title**: "AI Travel Assistant"
- **Payload**: `'ai_chat'`

### 4. **Scheduled Notification** (Thông báo hẹn giờ)
```dart
await NotificationService().scheduleNotification(
  id: 100,
  title: 'Nhắc nhở chuyến đi',
  body: 'Chuyến đi của bạn sẽ bắt đầu vào ngày mai!',
  scheduledDate: DateTime.now().add(Duration(days: 1)),
  payload: 'trip_reminder',
);
```

---

## 🎨 UI/UX Features

### **Dialog Xin Quyền**

**Thiết kế:**
- Background màu `#EDE2CC` (theme app)
- Icon notification lớn với background gradient
- Tiêu đề: "Cho phép thông báo"
- Danh sách 4 tính năng với icon:
  - 💬 Nhận tin nhắn mới từ nhóm
  - 👥 Thông báo yêu cầu tham gia nhóm
  - 📅 Nhắc nhở về kế hoạch du lịch
  - 🤖 Phản hồi từ AI Travel Assistant
- Note nhỏ: "Có thể thay đổi trong Cài đặt"
- 2 nút: "Không" và "Cho phép"

**Flow:**
1. User vào app lần đầu (sau khi login)
2. Delay 1s để UI load
3. Hiển thị dialog
4. User tap "Cho phép" → System permission dialog
5. Nếu granted → Gửi notification test + Snackbar success
6. Đánh dấu `notification_permission_asked = true`
7. Không hỏi lại nữa

---

## 🔧 Debug & Testing

### **Debug Logs**
```
✅ NotificationService initialized successfully
📬 Notification sent: Nhóm chat - 3 tin nhắn mới
⏰ Notification scheduled: Reminder at 2025-01-20 10:00:00
👁️ Notification permission already granted
```

### **Test Cases**

#### **Test 1: First Launch Permission**
1. Xóa app data (hoặc `notification_permission_asked` trong SharedPreferences)
2. Mở app
3. ✅ Dialog xin quyền xuất hiện sau 1s
4. Tap "Cho phép"
5. ✅ System dialog xuất hiện
6. Accept
7. ✅ Notification test xuất hiện
8. ✅ Snackbar "Đã bật thông báo thành công"

#### **Test 2: Message Notification**
1. User A gửi tin nhắn trong group
2. User B chưa xem
3. Vào Notification screen
4. ✅ System notification xuất hiện ở notification bar
5. Swipe down notification bar
6. ✅ Thấy "Nhóm chat - X tin nhắn mới"

#### **Test 3: Notification Tap (Future)**
1. Tap vào notification
2. App mở
3. TODO: Navigate to chatbox_screen

#### **Test 4: Permission Denied**
1. Deny permission trong system dialog
2. ✅ Snackbar error xuất hiện
3. Vào Settings → Notifications
4. Bật permission thủ công
5. ✅ Notifications hoạt động

---

## 📂 Files Đã Tạo/Sửa

### **Created:**
1. `lib/services/notification_service.dart` - Service chính quản lý notifications
2. `lib/widgets/notification_permission_dialog.dart` - Dialog xin quyền đẹp

### **Modified:**
1. `lib/main.dart` - Khởi tạo NotificationService
2. `lib/screens/main_app_screen.dart` - Xin quyền lần đầu
3. `lib/screens/notification_screen.dart` - Gửi system notification
4. `android/app/src/main/AndroidManifest.xml` - Android config
5. `pubspec.yaml` - Dependencies (đã có sẵn)

---

## 🚀 Tính Năng Tương Lai (TODO)

### 1. **Navigation khi tap notification**
```dart
void _onNotificationTapped(NotificationResponse response) {
  final payload = response.payload;
  if (payload == 'message') {
    // Navigate to ChatboxScreen
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ChatboxScreen(),
    ));
  } else if (payload == 'group_request') {
    // Navigate to Group Management
  }
}
```

### 2. **Push Notifications (Firebase)**
- Nhận notification khi app đóng hoàn toàn
- Backend trigger notification khi có event
- Tích hợp với Firebase Cloud Messaging (FCM)

### 3. **Notification Settings**
- Thêm toggle On/Off cho từng loại notification
- Lưu preferences trong Settings screen
- Cho phép user chọn sound/vibration

### 4. **Rich Notifications**
- Hiển thị avatar người gửi
- Action buttons (Reply, Mark as Read)
- Inbox style cho nhiều tin nhắn

### 5. **Badge Count**
- Hiển thị số thông báo chưa đọc trên app icon
- Update badge khi có notification mới
- Clear badge khi đã đọc

---

## 🐛 Troubleshooting

### **Lỗi Build Android: "requires core library desugaring"**

**Lỗi:**
```
Dependency ':flutter_local_notifications' requires core library desugaring
```

**Giải pháp:**
1. Mở `android/app/build.gradle.kts`
2. Thêm vào `android.compileOptions`:
   ```kotlin
   isCoreLibraryDesugaringEnabled = true
   ```
3. Thêm dependency:
   ```kotlin
   dependencies {
       coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
   }
   ```
4. Chạy:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

### **Notification không xuất hiện trên Android 13+**

**Nguyên nhân:** Chưa xin quyền `POST_NOTIFICATIONS`

**Giải pháp:**
- App sẽ tự động hỏi quyền khi vào lần đầu
- Hoặc vào Settings → Apps → Travel Together → Notifications → Enable

### **iOS: Notification không hiển thị**

**Nguyên nhân:** Chưa request permission

**Giải pháp:**
- App sẽ tự động hỏi quyền khi vào lần đầu
- Hoặc vào Settings → Travel Together → Notifications → Allow

### **Notification test không gửi**

**Kiểm tra:**
1. `NotificationService` đã initialize chưa? → Check log: `✅ NotificationService initialized`
2. Permission đã granted? → Check log: `👁️ Notification permission already granted`
3. Debug log có lỗi? → Check console

---

## ⚠️ Lưu Ý Quan Trọng

### **Android 13+ (API 33+)**
- **PHẢI** xin quyền `POST_NOTIFICATIONS` runtime
- Không xin quyền = không có notification
- Dialog permission đã handle việc này

### **iOS**
- **PHẢI** request permission trước khi gửi notification
- Permission chỉ hỏi 1 lần duy nhất
- User deny → Phải vào Settings để bật lại

### **Scheduled Notifications**
- Cần permission `SCHEDULE_EXACT_ALARM` (Android 12+)
- iOS không cần permission đặc biệt
- Timezone phải khởi tạo đúng (đã làm trong main.dart)

### **Notification IDs**
- **1**: Message notifications (overwrite nếu gửi nhiều lần)
- **2**: Group request notifications
- **3**: AI chat notifications
- **100+**: Custom/scheduled notifications
- Sử dụng ID khác nhau để notifications không ghi đè nhau

---

## 📚 Documentation References

- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
- [Android Notification Channels](https://developer.android.com/develop/ui/views/notifications/channels)
- [iOS User Notifications](https://developer.apple.com/documentation/usernotifications)

---

**Version:** 1.0  
**Last Updated:** January 2025  
**Status:** ✅ Hoàn thành & Ready to Test

**Tested on:**
- ✅ Android 13 (API 33)
- ⏳ iOS (Cần test thực tế)

---

## 🎉 Kết Luận

Hệ thống Local Notifications đã được tích hợp hoàn chỉnh với:
- Dialog xin quyền đẹp, UX tốt
- Hỗ trợ đầy đủ Android & iOS
- Tự động gửi notification khi có tin nhắn mới
- Cấu hình đúng cho cả production & development
- Debug logs rõ ràng
- Dễ mở rộng cho future features

**Hãy test ngay trên thiết bị thật để trải nghiệm!** 📱✨

