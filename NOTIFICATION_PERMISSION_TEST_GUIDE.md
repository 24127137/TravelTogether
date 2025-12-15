# Hướng dẫn Test Permission Thông báo (Notification Permission)

## Vấn đề đã fix
- ✅ Thêm `POST_NOTIFICATIONS` permission vào AndroidManifest.xml (bắt buộc Android 13+)
- ✅ App có giao diện custom "Travel Together muốn gửi thông báo đến bạn để..." trước khi request permission hệ thống
- ✅ NotificationService kiểm tra permission thực tế thay vì chỉ dựa vào flag
- ✅ Script revoke_and_run.bat giúp test lại permission dễ dàng

## Flow Permission (Giao diện 2 bước)

Khi user vào app lần đầu hoặc sau khi revoke permission:

### Bước 1: Dialog Custom của App (Giải thích)
```
┌──────────────────────────────────────┐
│  🔔  Cho phép thông báo             │
├──────────────────────────────────────┤
│ Travel Together muốn gửi thông báo   │
│ đến bạn để:                          │
│                                      │
│ 💬 Nhận tin nhắn mới từ nhóm         │
│ 👥 Thông báo yêu cầu tham gia nhóm   │
│ ⏰ Nhắc nhở về kế hoạch du lịch      │
│ 🤖 Phản hồi từ AI Travel Assistant   │
│                                      │
│ Bạn có thể thay đổi cài đặt này...   │
├──────────────────────────────────────┤
│           [Không]    [Cho phép]      │
└──────────────────────────────────────┘
```
- User bấm **"Cho phép"** → Chuyển sang Bước 2
- User bấm **"Không"** → Không request permission hệ thống

### Bước 2: Dialog Hệ thống Android (Quyền thực tế)
```
┌──────────────────────────────────────┐
│ Travel Together muốn gửi thông báo   │
│ đến bạn                               │
├──────────────────────────────────────┤
│          [Cho phép]    [Không]        │
└──────────────────────────────────────┘
```
- Đây là dialog THẬT của Android 13+ (hệ thống)
- User phải cho phép ở đây thì app mới được gửi notification

## Cách sử dụng Script Test Permission

### Phương pháp 1: Double-click file .bat (Đơn giản nhất)

1. **Mở folder:** `frontend\scripts\`
2. **Double-click:** `revoke_and_run.bat`
3. Script sẽ:
   - Tự động tìm package name từ `android/app/build.gradle`
   - Thu hồi (revoke) quyền POST_NOTIFICATIONS
   - Chạy lại app bằng `flutter run`
   - App sẽ tự động hiện dialog "Cho phép thông báo" khi khởi động

### Phương pháp 2: Test như cài app mới (Uninstall + Reinstall)

Nếu bạn muốn test như lần đầu cài app (xóa hết data):

**Cách 1: Chạy từ Command Prompt/PowerShell**
```cmd
cd frontend\scripts
revoke_and_run.bat uninstall
```

**Cách 2: Tạo shortcut**
- Chuột phải vào `revoke_and_run.bat` → Create Shortcut
- Chuột phải vào Shortcut → Properties
- Trong Target, thêm ` uninstall` vào cuối (có space trước uninstall)
- Ví dụ: `"D:\...\revoke_and_run.bat" uninstall`
- Click shortcut để chạy

### Phương pháp 3: Chạy PowerShell script trực tiếp (Advanced)

Nếu muốn tùy chỉnh thêm options:

```powershell
cd frontend\scripts

# Chỉ revoke permission
.\revoke_and_run.ps1 -Package com.example.frontend

# Revoke + clear app data
.\revoke_and_run.ps1 -Package com.example.frontend -ClearData

# Revoke + uninstall + reinstall
.\revoke_and_run.ps1 -Package com.example.frontend -Uninstall

# Revoke rồi grant lại (test grant flow)
.\revoke_and_run.ps1 -Package com.example.frontend -Grant

# Revoke nhưng không chạy flutter
.\revoke_and_run.ps1 -Package com.example.frontend -RunFlutter:$false
```

## Kiểm tra Permission bằng ADB (Manual)

Nếu bạn muốn check permission thủ công:

```powershell
# Kiểm tra thiết bị
adb devices

# Kiểm tra trạng thái permission
adb shell pm check-permission com.example.frontend android.permission.POST_NOTIFICATIONS

# Thu hồi permission
adb shell pm revoke com.example.frontend android.permission.POST_NOTIFICATIONS

# Cấp permission (test)
adb shell pm grant com.example.frontend android.permission.POST_NOTIFICATIONS

# Mở settings notification của app
adb shell am start -a android.settings.APP_NOTIFICATION_SETTINGS --es android.provider.extra.APP_PACKAGE com.example.frontend
```

## Lưu ý quan trọng

1. **Android 13+ (API 33+)**: Dialog "Cho phép thông báo" chỉ hiện trên Android 13 trở lên. Trên Android < 13, user phải vào Settings để bật/tắt.

2. **Don't ask again**: Nếu user chọn "Don't ask again" (deny permanently), app sẽ không hiện dialog nữa. Lúc này:
   - Dùng script với option `uninstall` để reset hoàn toàn
   - Hoặc hướng user vào Settings để bật thủ công

3. **iOS**: Trên iOS, permission dialog luôn hiện lần đầu. Nếu muốn test lại:
   - Xóa app rồi cài lại
   - Hoặc Settings → General → Reset → Reset Location & Privacy

## Các thay đổi trong code

### 1. AndroidManifest.xml
```xml
<!-- Thêm permission này để dialog hệ thống có thể hiện (Android 13+) -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### 2. notification_permission_dialog.dart (Widget Custom)
```dart
// Giao diện đẹp giải thích TẠI SAO cần permission
// Hiển thị TRƯỚC khi gọi permission hệ thống
class NotificationPermissionDialog {
  static Future<bool> show(BuildContext context) async {
    // Hiển thị dialog custom
    final shouldAsk = await showDialog<bool>(...);
    
    if (shouldAsk == true) {
      // User bấm "Cho phép" → request permission thật
      final granted = await NotificationService().requestPermission();
      return granted;
    }
    return false;
  }
}
```

### 3. main_app_screen.dart (Gọi dialog)
```dart
Future<void> _requestNotificationPermission() async {
  // Kiểm tra permission thực tế (không chỉ dựa vào flag)
  final hasPermission = await NotificationService().checkPermission();
  
  if (!hasPermission) {
    // Chưa có quyền → hiển thị dialog CUSTOM trước
    await NotificationPermissionDialog.show(context);
  }
}

@override
void initState() {
  super.initState();
  // Gọi sau 1 giây để UI load xong
  _requestNotificationPermission();
}
```

### 4. notification_service.dart
```dart
Future<void> initialize() async {
  // KHÔNG tự động request permission ở đây
  // Để app tự quyết định KHI NÀO hiện dialog custom
  await _notifications.initialize(...);
}

Future<bool> requestPermission() async {
  // Chỉ gọi khi user đã bấm "Cho phép" trên dialog custom
  if (defaultTargetPlatform == TargetPlatform.android) {
    final granted = await androidImplementation?.requestNotificationsPermission();
    return granted ?? false;
  }
  // iOS...
}
```

## Tại sao cần 2 bước?

**Best Practice UX:**
1. **Dialog Custom (App)**: Giải thích TẠI SAO cần permission → tăng tỷ lệ user chấp nhận
2. **Dialog Hệ thống (Android/iOS)**: Quyền thật sự → user phải đồng ý mới gửi được notification

Nếu bạn chỉ hiện dialog hệ thống mà không giải thích → user dễ từ chối → khó xin lại permission.

## Troubleshooting

**Q: Chạy script nhưng không thấy dialog?**
- Kiểm tra thiết bị Android có phải >= Android 13 không
- Chạy lại với option `uninstall`: `revoke_and_run.bat uninstall`
- Check log trong console Flutter để xem có lỗi không

**Q: Script báo lỗi "adb not found"?**
- Cài Android SDK Platform Tools
- Thêm vào PATH: `C:\Users\<YourUser>\AppData\Local\Android\Sdk\platform-tools`

**Q: Muốn tự động detect package name?**
- Script đã tự động detect từ `android/app/build.gradle`
- Nếu không detect được, script sẽ hỏi bạn nhập package name

**Q: Chạy nhiều thiết bị/emulator cùng lúc?**
- Script sẽ hiện menu để bạn chọn device
- Hoặc dùng `-DeviceId emulator-5554` trong PowerShell

## Workflow Test Notification Permission (Khuyến nghị)

1. **Lần đầu test permission:**
   ```
   revoke_and_run.bat uninstall
   ```
   → Dialog sẽ hiện lần đầu app mở

2. **Test revoke và request lại:**
   ```
   revoke_and_run.bat
   ```
   → App sẽ tự động request lại permission

3. **Test user deny permission:**
   - Chạy script
   - Khi dialog hiện → chọn "Deny"
   - Check xem app có handle gracefully không
   - Xem có hướng dẫn user vào Settings không

4. **Test grant lại sau khi deny:**
   - Vào Settings → Apps → Travel Together → Notifications → Bật
   - Hoặc dùng ADB: `adb shell pm grant com.example.frontend android.permission.POST_NOTIFICATIONS`

---

**Tóm tắt:** Giờ bạn chỉ cần double-click `revoke_and_run.bat` là script sẽ tự động revoke permission và chạy lại app. Dialog "Cho phép thông báo" sẽ hiện ra khi app khởi động!

