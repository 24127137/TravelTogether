# 🔧 FIX SUPABASE STORAGE RLS - Hướng Dẫn Chi Tiết

## ❌ Lỗi Hiện Tại
```
Error: Lỗi quyền truy cập bucket. Vui lòng liên hệ admin.
StorageException(message: new row violates row-level security policy, statusCode: 403)
```

## 🎯 Nguyên Nhân
Bucket `chat_images` trong Supabase Storage có **RLS (Row Level Security)** quá chặt, không cho phép upload file.

---

## ✅ GIẢI PHÁP - Làm Theo Các Bước Sau

### Bước 1: Đăng Nhập Supabase Dashboard
1. Truy cập: **https://app.supabase.com**
2. Đăng nhập với account của bạn
3. Chọn project: **TravelTogether** (hoặc tên project của bạn)

### Bước 2: Vào Storage
1. Menu bên trái → Click **Storage**
2. Tìm bucket tên: **`chat_images`**
   - Nếu KHÔNG CÓ → Làm theo **Phương án A**
   - Nếu ĐÃ CÓ → Làm theo **Phương án B**

---

## 📋 PHƯƠNG ÁN A: Tạo Bucket Mới

### Nếu chưa có bucket `chat_images`:

1. Click nút **"New Bucket"** (góc trên bên phải)
2. Điền thông tin:
   ```
   Name: chat_images
   Public bucket: ☑️ BẬT (ON)
   File size limit: 50MB
   Allowed MIME types: image/*
   ```
3. Click **"Create Bucket"**

### Tạo RLS Policies:

Sau khi tạo bucket, vào tab **Policies**:

#### Policy 1: Cho phép Public đọc file
```sql
-- Click "New Policy"
-- Chọn template: "Enable read access for public"

CREATE POLICY "Public read access"
ON storage.objects FOR SELECT
USING (bucket_id = 'chat_images');
```

#### Policy 2: Cho phép Authenticated users upload
```sql
-- Click "New Policy" 
-- Chọn template: "Enable insert for authenticated users"

CREATE POLICY "Authenticated users can upload"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'chat_images' 
  AND auth.role() = 'authenticated'
);
```

#### Policy 3: Cho phép users xóa file của mình (Optional)
```sql
-- Click "New Policy"
-- Custom policy

CREATE POLICY "Users can delete own files"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'chat_images'
  AND auth.role() = 'authenticated'
);
```

---

## 📋 PHƯƠNG ÁN B: Fix Bucket Hiện Tại

### Nếu đã có bucket `chat_images`:

### 1. Kiểm tra bucket là PUBLIC
1. Click vào bucket **`chat_images`**
2. Click nút **"..." (3 chấm)** → **"Edit bucket"**
3. Đảm bảo:
   ```
   ☑️ Public bucket: BẬT (toggle màu xanh)
   ```
4. Click **"Save"**

### 2. Xóa Policies cũ (nếu có lỗi)
1. Vào tab **"Policies"**
2. **XÓA TẤT CẢ** policies cũ (nếu có)
   - Click icon **🗑️** bên cạnh mỗi policy

### 3. Tạo lại Policies mới
Làm theo các SQL ở **Phương án A** (Policy 1, 2, 3)

---

## 🧪 KIỂM TRA SAU KHI FIX

### Test 1: Upload từ App
1. Mở app Flutter
2. Vào AI Chatbot
3. Click nút camera 📷
4. Chọn ảnh
5. **Kết quả mong đợi:**
   ```
   📤 Uploading image to Supabase...
   ✅ Image uploaded: ai_chat_xxxxx.jpg
   🖼️ Image URL: https://...
   ```

### Test 2: Upload bằng cURL
```bash
# Thay YOUR_PROJECT_URL và YOUR_ANON_KEY
curl -X POST \
  'https://YOUR_PROJECT.supabase.co/storage/v1/object/chat_images/test.jpg' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: image/jpeg' \
  --data-binary @test.jpg
```

**Kết quả mong đợi:** Status 200 OK

---

## 🔍 TROUBLESHOOTING

### Vẫn bị lỗi 403?

#### ✅ Checklist:
- [ ] Bucket name ĐÚNG là `chat_images` (không phải `chat_image` hay tên khác)
- [ ] Bucket đã bật **Public** (toggle màu xanh)
- [ ] Đã tạo **2 policies** (SELECT và INSERT)
- [ ] Policy target đúng bucket: `bucket_id = 'chat_images'`
- [ ] Supabase URL và ANON_KEY trong `api_config.dart` là ĐÚNG

### Kiểm tra Supabase Keys:

Vào file: `frontend/lib/config/api_config.dart`

```dart
static const String supabaseUrl = 'https://meuqntvawakdzntewscp.supabase.co';
static const String supabaseAnonKey = 'eyJhbGci...'; // Key dài
```

**Lấy keys đúng:**
1. Supabase Dashboard → Settings → API
2. Copy:
   - **Project URL** → `supabaseUrl`
   - **anon public** key → `supabaseAnonKey`

---

## 📸 HÌNH ẢNH MINH HỌA

### 1. Bucket Settings
```
┌─────────────────────────────────────┐
│ Bucket: chat_images                 │
├─────────────────────────────────────┤
│ ☑️ Public bucket       [ON] ←QUAN TRỌNG
│ File size limit: 50MB               │
│ Allowed MIME: image/*               │
└─────────────────────────────────────┘
```

### 2. Policies Tab
```
┌─────────────────────────────────────┐
│ Policies (2)                        │
├─────────────────────────────────────┤
│ ✅ Public read access               │
│    Operation: SELECT                │
│    Target: anon, authenticated      │
│                                     │
│ ✅ Authenticated users can upload   │
│    Operation: INSERT                │
│    Target: authenticated            │
└─────────────────────────────────────┘
```

---

## ⚡ GIẢI PHÁP TẠM THỜI (Nếu không thể fix ngay)

Nếu không thể fix Supabase ngay, bạn có thể:

### Option 1: Disable RLS (KHÔNG KHUYẾN KHÍCH)
```sql
-- Trong SQL Editor của Supabase
ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;
```
⚠️ **Chú ý:** Cách này BỎ HẾT bảo mật, chỉ dùng cho test!

### Option 2: Tạo bucket mới tên khác
Thay đổi code:
```dart
// Trong ai_chatbot_screen.dart
await supabase.storage
    .from('public_images')  // Tên bucket mới
    .upload(fileName, file);
```

Rồi tạo bucket `public_images` với Public ON và không cần RLS.

---

## ✅ KẾT QUẢ SAU KHI FIX

### Logs thành công:
```
📤 Uploading image to Supabase...
  Bucket: chat_images
  File: ai_chat_1701234567890.jpg
✅ Image uploaded: ai_chat_1701234567890.jpg
🖼️ Image URL: https://meuqntvawakdzntewscp.supabase.co/storage/v1/object/public/chat_images/ai_chat_1701234567890.jpg
🚀 Sending AI image message...
```

### UI thành công:
- ✅ Chọn ảnh → Upload thành công
- ✅ Ảnh hiển thị trong chat bubble
- ✅ AI phân tích ảnh và trả lời

---

## 📞 HỖ TRỢ

### Nếu vẫn gặp lỗi:

1. **Copy full error message:**
   ```
   I/flutter (16519): ❌ Upload error: [PASTE ERROR HERE]
   ```

2. **Check Supabase Dashboard:**
   - Storage → chat_images → Policies
   - Screenshot và gửi cho admin

3. **Verify API Keys:**
   - Dashboard → Settings → API
   - Copy lại Project URL và anon key

---

## 🎯 TÓM TẮT NHANH

```
1. Vào Supabase Dashboard
2. Storage → chat_images
3. Bật Public bucket
4. Tạo 2 policies:
   - SELECT: public read
   - INSERT: authenticated upload
5. Save và test lại app
```

⏱️ **Thời gian:** 5-10 phút
🔧 **Độ khó:** Dễ (chỉ click và paste SQL)

---

**Last Updated:** December 1, 2025
**Status:** Ready to fix
**Expected Result:** Upload ảnh thành công ✅

