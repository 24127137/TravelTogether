# ✅ Testing Checklist - Chat Features

## 📋 Kiểm Tra Tính Năng Mới

### 1. Camera & Gallery Button ✅

**Chatbox Screen:**
- [ ] Thấy nút ảnh (📷) màu vàng nâu bên trái thanh input
- [ ] Bấm vào nút ảnh → Bottom sheet hiện ra
- [ ] Bottom sheet có 2 tùy chọn:
  - [ ] "📷 Chụp ảnh" 
  - [ ] "🖼️ Chọn từ thư viện"

**Test Camera:**
- [ ] Chọn "Chụp ảnh" → Camera mở ra
- [ ] Chụp ảnh → Ảnh upload lên Supabase
- [ ] Tin nhắn ảnh xuất hiện trong chat
- [ ] Loading indicator hiện khi đang upload

**Test Gallery:**
- [ ] Chọn "Chọn từ thư viện" → Gallery mở ra
- [ ] Chọn ảnh → Ảnh upload lên Supabase
- [ ] Tin nhắn ảnh xuất hiện trong chat
- [ ] Loading indicator hiện khi đang upload

---

### 2. Messages Screen Preview ✅

**Test Tin Nhắn Ảnh:**
- [ ] Gửi ảnh trong chatbox
- [ ] Quay lại Messages Screen
- [ ] Thấy preview: "Bạn đã gửi một ảnh"
- [ ] Người khác gửi ảnh → Thấy "Đã gửi một ảnh"

**Test Tin Nhắn Text:**
- [ ] Gửi text: "Hello world"
- [ ] Quay lại Messages Screen  
- [ ] Thấy preview: "Bạn: Hello world"
- [ ] Người khác gửi text → Thấy text trực tiếp (không có "Bạn:")

**Test Thời Gian:**
- [ ] Tin nhắn hôm nay → Hiển thị giờ (VD: "14:30")
- [ ] Tin nhắn ngày khác → Hiển thị ngày (VD: "20 thg 11")

---

### 3. Avatar Display (Messenger Style) ✅

**Chatbox Screen:**

**Tin nhắn của người khác (bên trái):**
- [ ] Avatar hiển thị bên trái bubble
- [ ] Avatar tròn, màu nền vàng nâu nhạt
- [ ] Nếu có avatar_url → Hiện ảnh từ network
- [ ] Nếu không có → Hiện icon person mặc định

**Tin nhắn của mình (bên phải):**
- [ ] KHÔNG có avatar
- [ ] Chỉ có bubble tin nhắn
- [ ] Căn phải màn hình

---

## 🐛 Debug Points

### Nếu Camera không hoạt động:
1. Kiểm tra permissions trong `AndroidManifest.xml` / `Info.plist`
2. Test trên thiết bị thật (không phải emulator)
3. Xem console log để check lỗi

### Nếu Avatar không hiển thị:
1. Check API `/users/me` có trả về `avatar_url` không
2. Xem console log: "✅ My avatar loaded: ..."
3. Kiểm tra network connectivity

### Nếu Preview tin nhắn sai:
1. Check `user_id` trong SharedPreferences
2. Check `sender_id` trong response từ API
3. Xem console debug trong messages_screen

---

## 🎯 Expected Behavior

### Scenario 1: Gửi ảnh bằng Camera
```
1. Bấm nút ảnh trong chatbox
2. Chọn "Chụp ảnh"
3. Camera mở → Chụp ảnh
4. Loading indicator hiện
5. Ảnh upload lên Supabase
6. Tin nhắn ảnh xuất hiện
7. Quay về Messages Screen → "Bạn đã gửi một ảnh | 14:30"
```

### Scenario 2: Nhận tin nhắn từ người khác
```
1. Người khác gửi: "Chào bạn!"
2. Messages Screen hiển thị: "Chào bạn! | 14:32"
3. Vào Chatbox Screen
4. Thấy bubble bên trái với avatar của người gửi
5. Tin nhắn: "Chào bạn!" với thời gian "14:32"
```

### Scenario 3: Tin nhắn ngày khác
```
1. Tin nhắn từ ngày 20/11
2. Messages Screen hiển thị: "Bạn: Xin chào | 20 thg 11"
3. Không hiển thị giờ, chỉ hiển thị ngày
```

---

## 📱 Platform Notes

### Android
- Camera permission: `android.permission.CAMERA`
- Storage permission: `android.permission.READ_EXTERNAL_STORAGE`
- Write permission: `android.permission.WRITE_EXTERNAL_STORAGE`

### iOS
- Camera: `NSCameraUsageDescription`
- Photo Library: `NSPhotoLibraryUsageDescription`

---

## ✅ All Features Implemented!

🎉 Tất cả 3 tính năng đã được implement thành công:
1. ✅ Camera + Gallery button với bottom sheet
2. ✅ Messages screen preview thông minh (image/text, time format)
3. ✅ Avatar hiển thị giống Messenger (chỉ cho người khác)

**Status**: Ready for testing! 🚀

