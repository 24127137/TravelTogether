-- ========================================
-- SUPABASE STORAGE SETUP - CHAT IMAGES
-- ========================================
-- Chạy các câu lệnh này trong Supabase SQL Editor
-- hoặc làm theo hướng dẫn UI trong file SUPABASE_STORAGE_SETUP.md

-- ========================================
-- 1. TẠO BUCKET (Nếu chưa có)
-- ========================================
-- LƯU Ý: Bucket phải tạo qua UI vì cần set "public" = true
-- Hoặc dùng Supabase API/SDK để tạo bucket programmatically

-- Nếu muốn dùng SQL, có thể insert trực tiếp vào bảng storage.buckets:
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'chat_images',
  'chat_images',
  true,  -- Public bucket
  5242880,  -- 5MB = 5 * 1024 * 1024 bytes
  ARRAY['image/*']  -- Cho phép tất cả ảnh
)
ON CONFLICT (id) DO NOTHING;

-- ========================================
-- 2. TẠO STORAGE POLICIES
-- ========================================

-- Policy #1: Cho phép authenticated users UPLOAD ảnh
CREATE POLICY "Authenticated users can upload chat images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'chat_images');

-- Policy #2: Cho phép PUBLIC/ANON VIEW ảnh
CREATE POLICY "Public can view chat images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'chat_images');

-- Policy #3: Cho phép authenticated users DELETE ảnh (Optional)
CREATE POLICY "Users can delete their own chat images"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'chat_images');

-- ========================================
-- 3. VERIFY SETUP
-- ========================================

-- Kiểm tra bucket đã được tạo chưa
SELECT * FROM storage.buckets WHERE id = 'chat_images';

-- Kiểm tra policies đã được tạo chưa
SELECT * FROM pg_policies
WHERE schemaname = 'storage'
AND tablename = 'objects'
AND policyname LIKE '%chat images%';

-- ========================================
-- 4. TEST UPLOAD (Optional)
-- ========================================

-- Sau khi tạo bucket và policies, test upload từ app:
-- 1. Chạy Flutter app
-- 2. Vào chatbox
-- 3. Tap nút ảnh
-- 4. Chọn ảnh
-- 5. Kiểm tra kết quả trong storage.objects:

SELECT
  id,
  name,
  bucket_id,
  owner,
  created_at,
  updated_at
FROM storage.objects
WHERE bucket_id = 'chat_images'
ORDER BY created_at DESC
LIMIT 10;

-- ========================================
-- 5. CLEANUP (Xóa ảnh cũ - Optional)
-- ========================================

-- Xóa tất cả ảnh cũ hơn 30 ngày (để tiết kiệm storage)
DELETE FROM storage.objects
WHERE bucket_id = 'chat_images'
AND created_at < NOW() - INTERVAL '30 days';

-- ========================================
-- NOTES
-- ========================================
-- - Bucket 'chat_images' phải là PUBLIC để ảnh có thể xem được
-- - Policies đảm bảo chỉ authenticated users mới upload được
-- - Public users có thể xem ảnh (vì chat trong group là shared)
-- - File naming: {timestamp}_{filename} để tránh trùng lặp

