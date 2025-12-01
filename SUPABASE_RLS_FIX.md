# 🔧 Fix Supabase Storage RLS Error - Complete Guide

## ❌ Error
```
StorageException(message: new row violates row-level security policy, 
statusCode: 403, error: Unauthorized)
```

## 🎯 Root Cause
Bucket `chat_images` có RLS policy quá chặt, không cho phép upload file.

---

## ✅ Solution

### Step 1: Go to Supabase Dashboard
1. Truy cập: https://app.supabase.com
2. Chọn project `TravelTogether`
3. Vào **Storage** (menu bên trái)

### Step 2: Check/Create Bucket
1. Tìm bucket `chat_images`
   - Nếu không có → Click **New Bucket**
   - Tên: `chat_images`
   - Chọn: **Public**
   - Click **Create Bucket**

2. Nếu đã có → Kiểm tra:
   - Click vào bucket `chat_images`
   - Xem mục **Public** - phải là ON (xanh)

### Step 3: Fix RLS Policies
1. Chọn bucket `chat_images`
2. Vào tab **Policies** (nếu không thấy, bỏ qua)
3. **DELETE tất cả policies cũ** (nếu có)
4. Click **New Policy** → **For Users** 
5. Chọn template: **Enable insert access for authenticated users**
6. Click **Review** → **Save policy**

```sql
-- Tạo policy này:
CREATE POLICY "Enable insert for authenticated users"
ON storage.objects FOR INSERT
WITH CHECK (
  (bucket_id = 'chat_images') AND (auth.role() = 'authenticated')
);
```

7. Click **New Policy** → **For Users**
8. Chọn template: **Enable read access for public**
9. Click **Review** → **Save policy**

```sql
-- Tạo policy này:
CREATE POLICY "Enable read for public"
ON storage.objects FOR SELECT
USING (bucket_id = 'chat_images');
```

### Step 4: Verify Bucket Settings
```
✅ Bucket Name: chat_images
✅ Public: ON (xanh)
✅ RLS Policies:
   - INSERT: Cho phép authenticated users
   - SELECT: Cho phép public
```

---

## 📋 Complete RLS Setup

### Policy 1: Public Read Access
```
Name: Allow public read for chat_images
Target roles: anon, authenticated
Type: SELECT
Expression: (bucket_id = 'chat_images')
```

### Policy 2: Authenticated Upload
```
Name: Allow authenticated upload to chat_images
Target roles: authenticated
Type: INSERT
Expression: (bucket_id = 'chat_images')
```

### Policy 3: Authenticated Delete (Optional)
```
Name: Allow authenticated delete from chat_images
Target roles: authenticated
Type: DELETE
Expression: (bucket_id = 'chat_images')
```

---

## 🔍 Troubleshooting

### Problem: Still getting 403 error
**Check List:**
- [ ] Bucket is **Public** (not private)
- [ ] Policies are created correctly
- [ ] Using correct bucket name: `chat_images`
- [ ] Supabase app is initialized correctly

### Problem: Can't see Policies tab
**Solution:** 
- Bucket phải có ít nhất 1 file để mở tab Policies
- Upload 1 file test trước: 
  ```bash
  curl -X POST https://YOUR_SUPABASE_URL/storage/v1/object/chat_images/test.txt \
    -H "Authorization: Bearer YOUR_ANON_KEY" \
    -d "test"
  ```

### Problem: Images upload but show 404
**Check:**
- [ ] URL format is correct
- [ ] Bucket is public
- [ ] File path is correct
- [ ] CORS is enabled (usually auto)

---

## 🧪 Test Upload

### Method 1: Frontend (Dart)
```dart
final supabase = Supabase.instance.client;
final file = File('path/to/image.jpg');

try {
  await supabase.storage
      .from('chat_images')
      .upload('test_${DateTime.now().millisecondsSinceEpoch}.jpg', file);
  print('✅ Upload successful');
} catch (e) {
  print('❌ Error: $e');
}
```

### Method 2: Backend (Python)
```python
from supabase import create_client

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

with open('image.jpg', 'rb') as f:
    res = supabase.storage.from_('chat_images').upload(
        'test.jpg',
        f
    )
    print(res)
```

### Method 3: cURL
```bash
curl -X POST \
  'https://YOUR_PROJECT.supabase.co/storage/v1/object/chat_images/test.jpg' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: image/jpeg' \
  --data-binary @image.jpg
```

---

## 🔐 Security Best Practices

### ✅ Safe Configuration
```sql
-- Public read, authenticated write
-- Images can be viewed by anyone
-- Only authenticated users can upload

CREATE POLICY "Public read"
ON storage.objects FOR SELECT
USING (bucket_id = 'chat_images');

CREATE POLICY "Authenticated write"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'chat_images' 
  AND auth.role() = 'authenticated'
);
```

### ⚠️ Things to Avoid
- ❌ Don't make bucket completely private (no public read)
- ❌ Don't allow anonymous uploads
- ❌ Don't allow DELETE for all users
- ❌ Don't disable RLS completely

---

## 🎯 Expected Behavior After Fix

```
App Startup
    ↓
User taps image button
    ↓
Select image from gallery/camera
    ↓
Upload to Supabase
    ✅ Returns public URL
    ✓ No 403 error
    ↓
Display image in chat
    ↓
Send to AI
```

---

## 📝 Verification Checklist

- [ ] Bucket `chat_images` exists
- [ ] Bucket is **Public** (toggle is ON)
- [ ] RLS policies are created
- [ ] Can upload test file without error
- [ ] Can access uploaded file via URL
- [ ] Frontend gets correct public URL
- [ ] Images display in chat bubbles

---

## 🔗 Useful Links

1. **Supabase Storage Docs**: https://supabase.com/docs/guides/storage
2. **RLS Policy Guide**: https://supabase.com/docs/guides/storage/access-control
3. **Create Policy UI**: Your Project → Storage → Policies tab

---

## 💡 Quick Fix Summary

```
1. Go to Supabase Dashboard
2. Storage → chat_images bucket
3. Make it PUBLIC
4. Add 2 policies:
   - SELECT: Public read
   - INSERT: Authenticated upload
5. Save & Test
```

---

## 🧩 Integration with Frontend

After fixing Supabase, the following should work:

```dart
// Upload image
await supabase.storage
    .from('chat_images')
    .upload('ai_chat_${timestamp}.jpg', file);

// Get public URL
final imageUrl = supabase.storage
    .from('chat_images')
    .getPublicUrl(fileName);

// Send to AI
final response = await http.post(
  '/ai/send?user_id=$_userId',
  body: {'message': '', 'image_url': imageUrl},
);
```

---

## ✨ Result

After following these steps:

✅ Images upload successfully
✅ No more 403 errors
✅ Public URLs work
✅ Images display in chat
✅ AI can analyze images
✅ Image history saved

---

**Last Updated**: December 1, 2025
**Status**: Ready to implement
**Difficulty**: Easy (5-10 minutes)

🚀 **Follow these steps and the error will be fixed!**

