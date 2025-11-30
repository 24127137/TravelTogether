# 🗂️ CẤU HÌNH SUPABASE STORAGE - BUCKET CHAT_IMAGES

## ⚠️ QUAN TRỌNG - PHẢI LÀM TRƯỚC KHI TEST

Backend đã sẵn sàng, nhưng bạn cần tạo **Storage Bucket** trên Supabase để lưu ảnh chat.

---

## 📋 BƯỚC 1: TẠO BUCKET `chat_images`

### 1.1. Truy cập Supabase Dashboard
- URL: https://supabase.com/dashboard/project/meuqntvawakdzntewscp
- Đăng nhập với tài khoản của bạn

### 1.2. Tạo Bucket mới
1. Click vào **"Storage"** ở menu bên trái
2. Click **"New bucket"**
3. Điền thông tin:
   ```
   Name: chat_images
   Public bucket: ✅ BẬT (CHECKED)
   File size limit: 5 MB
   Allowed MIME types: image/*
   ```
4. Click **"Create bucket"**

### 1.3. Xác nhận
Sau khi tạo, bạn sẽ thấy bucket `chat_images` trong danh sách.

---

## 🔐 BƯỚC 2: THIẾT LẬP STORAGE POLICIES

### Tại sao cần Policies?
Supabase Storage sử dụng **Row Level Security (RLS)** để bảo vệ files. Bạn cần tạo policies để:
- Cho phép user upload ảnh
- Cho phép mọi người xem ảnh (vì chat là public trong group)

### 2.1. Vào Storage Policies
1. Click vào bucket **`chat_images`**
2. Click tab **"Policies"**
3. Click **"New Policy"**

### 2.2. Tạo Policy #1: Upload (INSERT)

**Cách 1: Dùng UI (Đơn giản)**
- Policy name: `Allow authenticated users to upload`
- Allowed operation: **INSERT**
- Target roles: `authenticated`
- USING expression: 
  ```sql
  bucket_id = 'chat_images'
  ```
- Click **"Save policy"**

**Cách 2: Dùng SQL Editor**
```sql
CREATE POLICY "Authenticated users can upload chat images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'chat_images');
```

### 2.3. Tạo Policy #2: View (SELECT)

**Cách 1: Dùng UI**
- Policy name: `Allow public to view images`
- Allowed operation: **SELECT**
- Target roles: `public` hoặc `anon`
- USING expression:
  ```sql
  bucket_id = 'chat_images'
  ```
- Click **"Save policy"**

**Cách 2: Dùng SQL Editor**
```sql
CREATE POLICY "Public can view chat images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'chat_images');
```

### 2.4. Tạo Policy #3: Delete (Optional)

**Chỉ nếu bạn muốn user có thể xóa ảnh:**
```sql
CREATE POLICY "Users can delete their own chat images"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'chat_images');
```

---

## ✅ BƯỚC 3: VERIFY SETUP

### 3.1. Kiểm tra Bucket Settings
Vào bucket `chat_images` → Settings:
- ✅ Public: **Enabled**
- ✅ File size limit: **5 MB** (hoặc tùy chọn)
- ✅ Allowed MIME types: `image/*`

### 3.2. Kiểm tra Policies
Vào bucket `chat_images` → Policies:
- ✅ **INSERT policy**: Cho authenticated users
- ✅ **SELECT policy**: Cho public/anon users
- ✅ (Optional) **DELETE policy**: Cho authenticated users

### 3.3. Test Manual Upload (Optional)
1. Click vào bucket `chat_images`
2. Click **"Upload file"**
3. Chọn 1 ảnh bất kỳ
4. Upload thành công → Copy URL
5. Paste URL vào browser → Nếu thấy ảnh → ✅ OK!

---

## 🎯 CÁCH HOẠT ĐỘNG

### Flow Upload:
```
Flutter App
    ↓ (User chọn ảnh)
ImagePicker
    ↓ (File object)
_uploadImageToSupabase()
    ↓ (HTTP POST với file bytes)
Supabase Storage API
    ↓ (Lưu vào bucket 'chat_images')
    ↓ (Return public URL)
Backend API /chat/send
    ↓ (Lưu URL vào DB)
PostgreSQL (group_messages table)
```

### URL Format:
```
https://meuqntvawakdzntewscp.supabase.co/storage/v1/object/public/chat_images/1234567890_image.jpg
```

---

## 🐛 TROUBLESHOOTING

### Lỗi 1: "Upload ảnh thất bại" (400/403)
**Nguyên nhân:**
- Bucket chưa tồn tại
- Bucket không public
- Thiếu INSERT policy

**Giải pháp:**
1. Kiểm tra bucket `chat_images` đã tạo chưa
2. Kiểm tra "Public bucket" đã bật chưa
3. Kiểm tra INSERT policy đã tạo chưa

### Lỗi 2: "Broken image" khi hiển thị
**Nguyên nhân:**
- Thiếu SELECT policy
- URL sai format

**Giải pháp:**
1. Tạo SELECT policy cho `public` role
2. Test URL trên browser
3. Kiểm tra bucket có public không

### Lỗi 3: "401 Unauthorized"
**Nguyên nhân:**
- Access token hết hạn
- `supabaseAnonKey` sai

**Giải pháp:**
1. Logout và login lại
2. Kiểm tra `api_config.dart` → `supabaseAnonKey`
3. Lấy key mới từ: Supabase Dashboard → Settings → API → anon/public key

---

## 📊 STORAGE STRUCTURE

```
Supabase Storage
└── chat_images/ (bucket - PUBLIC)
    ├── 1737849600000_photo1.jpg
    ├── 1737849700000_photo2.png
    ├── 1737849800000_photo3.jpeg
    └── ...
```

**Naming Convention:**
- Format: `{timestamp}_{original_filename}`
- Ví dụ: `1737849600000_my_photo.jpg`
- Timestamp đảm bảo tên file unique

---

## 💾 DATABASE STRUCTURE

Bảng `group_messages` đã hỗ trợ sẵn:
```sql
id            | integer (PK)
group_id      | integer (FK)
sender_id     | uuid (FK)
message_type  | text ('text' hoặc 'image')
content       | text (caption cho ảnh, hoặc text message)
image_url     | text (URL của ảnh trên Supabase Storage)
created_at    | timestamp
```

---

## 🎨 UI/UX FEATURES

### Input Bar:
```
[📷] [________________Input box________________] [📤]
 ^                                                  ^
Nút ảnh                                        Nút gửi
(màu nâu)                                     (màu nâu)
```

### Message Bubble với ảnh:
```
┌─────────────────────────┐
│  [      Ảnh 60%      ]  │ ← Ảnh responsive
│                         │
│  Caption text (nếu có)  │ ← Text content
│                         │
│                  10:30  │ ← Timestamp
└─────────────────────────┘
```

### Loading States:
- **Khi chọn ảnh:** Input bar disable
- **Khi upload:** Nút ảnh → Loading spinner
- **Khi load ảnh:** Placeholder grey với progress indicator
- **Khi lỗi:** Broken image icon

---

## 🚀 SẴN SÀNG TEST!

Sau khi hoàn thành setup Supabase:

```powershell
cd D:\TDTT TRAVEL PROJECT\my_travel_app\TravelTogether\frontend
flutter run
```

**Test scenario:**
1. Mở app → Vào chatbox
2. Nhấn nút **📷** (icon ảnh màu nâu)
3. Chọn ảnh từ gallery
4. Đợi upload (thấy loading spinner)
5. Ảnh xuất hiện trong chat bubble
6. Scroll smooth, tap ảnh để zoom (nếu implement thêm)

---

**🎉 CHÚC MỪNG! Bạn đã có chat với ảnh giống Messenger rồi!**

