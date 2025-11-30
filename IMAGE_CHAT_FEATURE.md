# 📸 HƯỚNG DẪN CHỨC NĂNG GỬI ẢNH TRONG CHAT (GIỐNG MESSENGER)

## ✅ ĐÃ HOÀN THÀNH

### 🔧 Các thay đổi Frontend:

#### 1. **File `message.dart`** - Model
- ✅ Thêm field `imageUrl` (nullable String)
- ✅ Thêm field `messageType` ('text' hoặc 'image')
- ✅ Cập nhật `fromMap()` để parse `image_url` và `message_type` từ API

#### 2. **File `chatbox_screen.dart`** - UI & Logic
- ✅ Thêm `ImagePicker` để chọn ảnh từ gallery
- ✅ Thêm state `_isUploading` để hiển thị loading khi upload
- ✅ Thêm hàm `_uploadImageToSupabase()` - Upload ảnh lên Supabase Storage bucket `chat_images`
- ✅ Thêm hàm `_pickAndSendImage()` - Chọn ảnh → Upload → Gửi tin nhắn
- ✅ Thêm **nút chọn ảnh** (icon image) bên trái input bar
- ✅ Hiển thị **loading spinner** khi đang upload
- ✅ Cập nhật `_MessageBubble` để hiển thị ảnh với:
  - Loading progress indicator
  - Error fallback (broken image icon)
  - Responsive width (60% màn hình)
  - Border radius đẹp

---

## ⚙️ CẤU HÌNH SUPABASE STORAGE (QUAN TRỌNG!)

### Bước 1: Tạo Bucket `chat_images`
1. Truy cập: https://supabase.com/dashboard
2. Chọn project: **meuqntvawakdzntewscp**
3. Vào **Storage** (menu bên trái)
4. Nhấn **"New bucket"**
5. Cấu hình:
   - **Name:** `chat_images`
   - **Public bucket:** ✅ **BẬT** (để ảnh có thể xem được công khai)
   - **File size limit:** 5MB (hoặc tùy chọn)
   - **Allowed MIME types:** `image/*` (cho phép tất cả ảnh)
6. Nhấn **"Create bucket"**

### Bước 2: Thiết lập Storage Policies
Vào bucket `chat_images` → **Policies** → Add policy:

#### Policy 1: Upload (INSERT)
```sql
-- Cho phép user đã đăng nhập upload ảnh
CREATE POLICY "Authenticated users can upload chat images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'chat_images');
```

#### Policy 2: View (SELECT)
```sql
-- Cho phép mọi người xem ảnh (vì bucket public)
CREATE POLICY "Public can view chat images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'chat_images');
```

#### Policy 3: Delete (DELETE) - Optional
```sql
-- Cho phép user xóa ảnh của chính mình
CREATE POLICY "Users can delete their own chat images"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'chat_images');
```

---

## 🎯 CÁCH SỬ DỤNG

### Từ phía User (App):
1. Mở chatbox
2. Nhấn **nút icon ảnh** (bên trái input box)
3. Chọn ảnh từ gallery
4. Đợi upload (hiển thị loading spinner)
5. Ảnh tự động gửi vào chat sau khi upload xong

### Hiển thị:
- **Tin nhắn text:** Hiển thị text như bình thường
- **Tin nhắn ảnh:** 
  - Hiển thị ảnh với width = 60% màn hình
  - Có loading progress khi load ảnh
  - Có error fallback nếu ảnh lỗi
  - Có thể kèm caption (nếu `content` không rỗng)

---

## 🔄 QUY TRÌNH HOẠT ĐỘNG

```
User chọn ảnh
    ↓
Upload lên Supabase Storage (bucket: chat_images)
    ↓
Nhận lại publicUrl (https://...supabase.co/storage/v1/object/public/chat_images/...)
    ↓
Gửi POST /chat/send với:
    {
      "message_type": "image",
      "image_url": "https://..."
    }
    ↓
Backend lưu vào DB (bảng group_messages)
    ↓
Frontend reload chat history và hiển thị ảnh
```

---

## 🎨 TÍNH NĂNG GIỐNG MESSENGER

✅ **Đã có:**
- ✅ Nút chọn ảnh (icon image)
- ✅ Upload ảnh tự động
- ✅ Hiển thị loading khi upload
- ✅ Hiển thị ảnh trong bubble chat
- ✅ Responsive layout
- ✅ Error handling (ảnh lỗi, upload thất bại)

🔜 **Có thể mở rộng thêm:**
- Chụp ảnh trực tiếp (camera)
- Preview ảnh trước khi gửi
- Thêm caption cho ảnh
- Zoom ảnh khi tap
- Gửi nhiều ảnh cùng lúc
- Hiển thị thumbnail nhỏ

---

## 🐛 TROUBLESHOOTING

### Lỗi: "Upload ảnh thất bại"
**Nguyên nhân:** Chưa tạo bucket hoặc chưa set policies

**Giải pháp:**
1. Kiểm tra bucket `chat_images` đã tồn tại chưa
2. Kiểm tra bucket có **public** không
3. Kiểm tra storage policies

### Lỗi: "Broken image" (ảnh hiển thị lỗi)
**Nguyên nhân:** URL ảnh không truy cập được

**Giải pháp:**
1. Mở URL ảnh trên browser để test
2. Kiểm tra bucket policy cho SELECT
3. Kiểm tra internet connection

### Lỗi: 403 Permission Denied
**Nguyên nhân:** Access token hết hạn hoặc không có quyền

**Giải pháp:**
1. Logout và login lại để refresh token
2. Kiểm tra storage policies
3. Kiểm tra `supabaseAnonKey` trong `api_config.dart`

---

## 📱 TEST TRÊN THIẾT BỊ

### Android:
1. Cần permission trong `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

### iOS:
1. Cần permission trong `Info.plist`:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Cần truy cập thư viện ảnh để gửi ảnh trong chat</string>
```

---

## 💡 LƯU Ý QUAN TRỌNG

1. **Backend không cần thay đổi gì** - Đã hỗ trợ sẵn `image_url` và `message_type`
2. **Upload trực tiếp lên Supabase Storage** - Không qua backend (tiết kiệm bandwidth)
3. **Public URL** - Ảnh có thể truy cập mà không cần auth (vì bucket public)
4. **Tự động resize** - ImagePicker đã giới hạn maxWidth/maxHeight = 1920px
5. **Nén ảnh** - imageQuality = 85 (cân bằng chất lượng và dung lượng)

---

## 🚀 CHẠY THỬ

```powershell
# Chạy Flutter app
cd D:\TDTT TRAVEL PROJECT\my_travel_app\TravelTogether\frontend
flutter run
```

**Hoặc chạy từ IDE:**
- F5 (Debug mode)
- Ctrl+F5 (Release mode)

Sau khi app chạy:
1. Vào chatbox
2. Nhấn nút **icon ảnh** (màu nâu, bên trái)
3. Chọn ảnh từ gallery
4. Chờ upload (sẽ thấy loading spinner)
5. Ảnh tự động xuất hiện trong chat! 📸

---

## 📊 KIẾN TRÚC

```
┌─────────────────┐
│  Flutter App    │
│  (Frontend)     │
└────────┬────────┘
         │
         │ 1. User chọn ảnh
         ↓
┌─────────────────┐
│ ImagePicker     │ → Chọn ảnh từ gallery
└────────┬────────┘
         │
         │ 2. File object
         ↓
┌─────────────────────────┐
│ _uploadImageToSupabase()│
└────────┬────────────────┘
         │
         │ 3. HTTP POST with file bytes
         ↓
┌─────────────────────┐
│ Supabase Storage    │
│ Bucket: chat_images │ → Lưu ảnh
└────────┬────────────┘
         │
         │ 4. Return public URL
         ↓
┌─────────────────┐
│ _pickAndSendImage()│
└────────┬────────┘
         │
         │ 5. POST /chat/send
         │    {message_type: "image", image_url: "..."}
         ↓
┌─────────────────┐
│ Backend API     │
│ /chat/send      │ → Lưu vào DB
└────────┬────────┘
         │
         │ 6. Save to group_messages table
         ↓
┌─────────────────┐
│ PostgreSQL DB   │
└─────────────────┘
```

---

Chúc bạn thành công! 🎉

