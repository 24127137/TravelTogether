# 🔍 DEBUG AVATAR - Hướng Dẫn Chi Tiết

## Vấn Đề
Avatar của người nhắn tới (người gửi ≠ mình) KHÔNG hiển thị trong chatbox.

## Cách Debug

### Bước 1: Chạy App và Vào Chatbox
1. Đăng nhập vào app (đã làm ✓)
2. Vào màn hình Chatbox (chat nhóm)
3. **MỞ CONSOLE/RUN OUTPUT** trong IDE

### Bước 2: Tìm Các Dòng Log Quan Trọng

Khi vào chatbox, console sẽ in ra nhiều dòng debug. Tìm và **COPY** những dòng sau:

#### A. SharedPreferences Debug:
```
🔍 ===== SHARED PREFERENCES DEBUG =====
🔍 All keys: ...
🔍 Access Token exists: ...
🔍 User ID (from prefs): "???"  <-- CÁI NÀY QUAN TRỌNG
🔍 ====================================
```

#### B. Token Decode:
```
✅ Current user id extracted from token: "???"  <-- CÁI NÀY QUAN TRỌNG
```

#### C. Message Debug (cho TỪNG tin nhắn):
```
🔍 ===== MESSAGE DEBUG =====
🔍 Current User ID (token): "???"      <-- So sánh cái này
🔍 Current User ID (pref): "???"       <-- với cái này
🔍 Sender ID: "???"                    <-- và cái này
🔍 isSenderMe? true/false              <-- KẾT QUẢ SO SÁNH
🔍 Result isUser: true/false           <-- TIN NHẮN CỦA AI?
🔍 Will display on: LEFT/RIGHT
```

#### D. MessageBubble Debug:
```
🖼️ MessageBubble - isUser: true/false, sender: ???, avatarUrl: ???, currentUserId: ???
🖼️ Should show avatar: true/false     <-- CÁI NÀY QUYẾT ĐỊNH HIỂN THỊ
```

---

## Điều Kiện Để Avatar Hiển Thị

### ✅ Avatar SẼ HIỂN THỊ khi:
```
🖼️ Should show avatar: true
```

Điều này xảy ra khi `isUser = false`, nghĩa là:
- `senderId` KHÁC với `currentUserId` (từ token)
- VÀ `senderId` KHÁC với `prefUserId` (từ SharedPreferences)

### ❌ Avatar KHÔNG HIỂN THỊ khi:
```
🖼️ Should show avatar: false
```

Điều này xảy ra khi `isUser = true`, nghĩa là:
- `senderId` = `currentUserId` (tin nhắn của mình)

---

## Kịch Bản Test

### Test Case 1: Chỉ có tin nhắn CỦA MÌNH
**Tình huống**: Bạn đăng nhập, vào chatbox, chỉ thấy tin nhắn mình đã gửi trước đó.

**Kết quả mong đợi**:
```
🔍 isSenderMe? true
🔍 Result isUser: true
🖼️ Should show avatar: false
```
→ Tất cả bubble BÊN PHẢI, KHÔNG CÓ AVATAR ✓

### Test Case 2: Có tin nhắn TỪ NGƯỜI KHÁC
**Tình huống**: Bạn đăng nhập bằng account A, người khác (account B) đã gửi tin nhắn.

**Kết quả mong đợi**:
```
// Tin nhắn từ account B:
🔍 Current User ID (token): "uuid-account-A"
🔍 Sender ID: "uuid-account-B"
🔍 isSenderMe? false               <-- KHÁC NHAU
🔍 Result isUser: false
🖼️ Should show avatar: true        <-- PHẢI HIỆN AVATAR!
```
→ Bubble BÊN TRÁI, CÓ AVATAR (icon person) ✓

---

## Phân Tích Nguyên Nhân

### Nếu avatar KHÔNG HIỂN THỊ dù `Should show avatar: true`
→ **Lỗi render UI** (rất hiếm, code trông đúng)

### Nếu `Should show avatar: false` cho TẤT CẢ tin nhắn
→ **Logic so sánh sai**: 
- `currentUserId` và `senderId` đang GIỐNG NHAU cho tất cả tin nhắn
- Hoặc `currentUserId` = null

---

## Giải Pháp Nhanh

### Nếu bạn CHẮC CHẮN có tin nhắn từ người khác:

1. **Kiểm tra console log** - Tìm dòng:
   ```
   🔍 Sender ID: "???"
   ```
   
2. **So sánh với**:
   ```
   🔍 Current User ID (token): "???"
   ```

3. **Nếu GIỐNG NHAU** mặc dù tin nhắn từ người khác:
   → Vấn đề: Login đang lưu sai `user_id` vào SharedPreferences
   → Cần sửa `login.dart`

4. **Nếu KHÁC NHAU** nhưng vẫn `isSenderMe? true`:
   → Vấn đề: Helper `_isSenderMe()` có bug
   → Kiểm tra format của chuỗi (có dấu space, ký tự đặc biệt?)

---

## Action Tiếp Theo

### Làm ngay bây giờ:
Chạy app, vào chatbox, và **GỬI CHO TÔI** những dòng log sau (copy/paste):

```
🔍 ===== SHARED PREFERENCES DEBUG =====
🔍 User ID (from prefs): "..."
🔍 ====================================

✅ Current user id extracted from token: "..."

🔍 ===== MESSAGE DEBUG ===== (cho 1 tin nhắn)
🔍 Current User ID (token): "..."
🔍 Sender ID: "..."
🔍 isSenderMe? ...
🔍 Result isUser: ...

🖼️ MessageBubble - isUser: ..., sender: ..., currentUserId: ...
🖼️ Should show avatar: ...
```

Khi tôi có logs này, tôi sẽ biết chính xác vấn đề và sửa luôn!

---

## Nếu Muốn Test Nhanh

Thử điều này: **Tạm thời FORCE hiển thị avatar cho TẤT CẢ tin nhắn** để xem có vấn đề render không:

Sửa dòng trong `_MessageBubble`:
```dart
// Thay vì:
final showAvatar = !isUser;

// Thành:
final showAvatar = true; // TEST: LUÔN HIỆN AVATAR
```

Nếu sau khi sửa này mà avatar HIỆN RA → Vấn đề ở logic `isUser`.  
Nếu vẫn KHÔNG HIỆN → Vấn đề ở render UI (nhưng không thể, code rất rõ ràng).

**Bạn muốn tôi làm gì tiếp theo?**
- A) Gửi console logs cho tôi phân tích
- B) Tôi sửa code để FORCE hiển thị avatar (test)
- C) Tôi xem lại login.dart để check `user_id` lưu thế nào

