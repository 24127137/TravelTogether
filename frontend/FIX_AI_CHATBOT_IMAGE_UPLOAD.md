# ✅ CHECKLIST FIX LỖI UPLOAD ẢNH AI CHATBOT

## 🐛 Lỗi gặp phải
```
Lỗi upload ảnh: StorageException(message: Bucket not found, statusCode: 404, error: Bucket not found)
```

## 🔍 Nguyên nhân
1. ~~Bucket name sai: code dùng `chat-images` (gạch ngang) nhưng bucket thực tế là `chat_images` (gạch dưới)~~ ✅ **ĐÃ SỬA**
2. Bucket `chat_images` có thể chưa được tạo trên Supabase

---

## ✅ ĐÃ SỬA
File: `frontend/lib/screens/ai_chatbot_screen.dart`
- Dòng ~308: Đổi `.from('chat-images')` → `.from('chat_images')`
- Dòng ~314: Đổi `.from('chat-images')` → `.from('chat_images')`

---

## 🔧 BƯỚC TIẾP THEO - KIỂM TRA SUPABASE

### Bước 1: Kiểm tra bucket có tồn tại không
1. Mở Supabase Dashboard: https://supabase.com/dashboard/project/meuqntvawakdzntewscp
2. Click **Storage** ở menu trái
3. Tìm bucket tên **`chat_images`**

**Nếu KHÔNG thấy bucket:**
- Làm theo hướng dẫn trong file `SUPABASE_STORAGE_SETUP.md` để tạo bucket
- Hoặc xem phần **"TẠO BUCKET"** bên dưới

**Nếu ĐÃ thấy bucket:**
- Tiếp tục kiểm tra Bước 2

---

### Bước 2: Kiểm tra bucket settings
Click vào bucket **`chat_images`** → Kiểm tra:

✅ **Public bucket:** PHẢI BẬT (enabled)
- Nếu tắt → Click "Settings" → Bật "Public bucket"

✅ **File size limit:** Nên để 5MB hoặc cao hơn

✅ **Allowed MIME types:** `image/*` (cho phép mọi loại ảnh)

---

### Bước 3: Kiểm tra Storage Policies
Click vào bucket **`chat_images`** → Tab **"Policies"**

Cần có ít nhất 2 policies:

#### Policy 1: INSERT (Upload)
```
Operation: INSERT
Target role: authenticated
Using/With Check: bucket_id = 'chat_images'
```

#### Policy 2: SELECT (View)
```
Operation: SELECT
Target role: public hoặc anon
Using: bucket_id = 'chat_images'
```

**Nếu thiếu policies:**
- Click "New Policy"
- Hoặc chạy SQL (xem phần SQL bên dưới)

---

## 🆕 TẠO BUCKET (nếu chưa có)

### Cách 1: Qua UI
1. Vào Storage → Click **"New bucket"**
2. Điền:
   - Name: `chat_images`
   - Public bucket: ✅ **BẬT**
   - File size limit: `5 MB`
   - Allowed MIME types: `image/*`
3. Click "Create bucket"

### Cách 2: Qua SQL Editor
```sql
-- Tạo bucket (nếu cần)
INSERT INTO storage.buckets (id, name, public)
VALUES ('chat_images', 'chat_images', true);

-- Policy 1: Cho phép authenticated users upload
CREATE POLICY "Authenticated users can upload chat images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'chat_images');

-- Policy 2: Cho phép public xem ảnh
CREATE POLICY "Public can view chat images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'chat_images');
```

---

## 🧪 TEST SAU KHI FIX

### Test 1: Upload thủ công trên Supabase
1. Vào Storage → `chat_images`
2. Click "Upload file"
3. Chọn 1 ảnh → Upload
4. Nếu thành công → Copy URL → Paste vào browser
5. Nếu thấy ảnh hiển thị → ✅ Bucket OK!

### Test 2: Upload qua app
1. Hot restart app (Ctrl + Shift + F5 trên VS Code hoặc `r` trong terminal)
2. Vào màn hình AI Chatbot
3. Click nút ảnh → Chọn ảnh từ gallery hoặc camera
4. Kiểm tra console/logcat:
   - ✅ "📤 Uploading image to Supabase..."
   - ✅ "✅ Image uploaded: ai_chat_..."
   - ✅ "🖼️ Image URL: https://..."
5. Ảnh hiển thị trong chat → ✅ Thành công!

---

## 🚨 NẾU VẪN LỖI

### Lỗi 401 Unauthorized
**Nguyên nhân:** Token hết hạn hoặc sai anon key

**Giải pháp:**
1. Logout và login lại app
2. Kiểm tra `api_config.dart` → `supabaseAnonKey`
3. Lấy key mới từ: Supabase → Settings → API → anon public key

### Lỗi 403 Forbidden
**Nguyên nhân:** Thiếu policies

**Giải pháp:**
- Tạo INSERT policy cho authenticated role
- Tạo SELECT policy cho public role

### Lỗi "Object not found" khi xem ảnh
**Nguyên nhân:** Thiếu SELECT policy hoặc bucket không public

**Giải pháp:**
- Bật "Public bucket" trong settings
- Tạo SELECT policy cho public

---

## 📝 SUMMARY
1. ✅ Đã sửa code: `chat-images` → `chat_images`
2. ⚠️ Cần kiểm tra: Bucket `chat_images` có tồn tại không
3. ⚠️ Cần kiểm tra: Bucket settings (public, policies)
4. 🧪 Test lại sau khi fix

---

**Tài liệu tham khảo:**
- `SUPABASE_STORAGE_SETUP.md` - Hướng dẫn chi tiết setup
- `Chatbot_Summary.md` - Tổng quan kỹ thuật chat

**Liên hệ nếu cần hỗ trợ thêm!** 🚀

