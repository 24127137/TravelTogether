# 🔧 Fix Backend Lỗi 500 - API /groups/plan

## 🐛 Vấn Đề

**Lỗi:**
```
INFO: 192.168.1.9:46424 - "GET /groups/plan HTTP/1.1" 500 Internal Server Error
ERROR: Exception in ASGI application
```

**Frontend Error:**
```
I/flutter (24370): ❌ Lỗi khi lấy group plan: Exception: Lỗi khi lấy kế hoạch nhóm: 500
```

---

## 🔍 Nguyên Nhân

Trong file `backend/group_services/utils.py`, hàm `get_user_group_info()` có lỗi SQL query:

**Code Lỗi:**
```python
profile = session.exec(
    select(Profiles.joined_groups, Profiles.owned_groups)  # ❌ SAI
    .where(Profiles.auth_user_id == auth_uuid)
).first()
```

**Vấn đề:**
- Query chỉ select 2 cột (`joined_groups`, `owned_groups`) thay vì toàn bộ object `Profiles`
- Sau đó code cố gắng truy cập `profile.joined_groups` và `profile.owned_groups` → Lỗi vì `profile` không phải là object `Profiles` đầy đủ
- SQLModel trả về tuple thay vì object khi select cụ thể các cột

---

## ✅ Giải Pháp

Sửa query để select toàn bộ object `Profiles`:

**Code Đúng:**
```python
profile = session.exec(
    select(Profiles)  # ✅ ĐÚNG - Select toàn bộ object
    .where(Profiles.auth_user_id == auth_uuid)
).first()
```

---

## 📝 Chi Tiết Thay Đổi

### File: `backend/group_services/utils.py`

**Dòng 85-88 (Trước):**
```python
profile = session.exec(
    select(Profiles.joined_groups, Profiles.owned_groups)
    .where(Profiles.auth_user_id == auth_uuid)
).first()
```

**Dòng 85-88 (Sau):**
```python
profile = session.exec(
    select(Profiles)
    .where(Profiles.auth_user_id == auth_uuid)
).first()
```

---

## 🔄 Luồng Hoạt Động Sau Khi Fix

```
1. Frontend gọi: GET /groups/plan
   ↓
2. Backend endpoint: get_my_group_plan()
   ↓
3. Call: member.get_group_plan(session, auth_uuid)
   ↓
4. Call: get_user_group_info(session, auth_uuid)
   ↓
5. ✅ Query đúng: select(Profiles).where(...)
   ↓
6. ✅ Trả về Profile object đầy đủ
   ↓
7. ✅ Access profile.joined_groups và profile.owned_groups
   ↓
8. ✅ Lấy được group_id
   ↓
9. ✅ Query TravelGroup
   ↓
10. ✅ Return GroupPlanOutput
    ↓
11. Frontend nhận được itinerary thành công
```

---

## 🧪 Test Sau Khi Fix

### 1. Restart Backend
```bash
cd backend
python main.py
```

### 2. Test API với Curl/Postman
```bash
curl -X GET "http://localhost:8000/groups/plan" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**Expected Response (200 OK):**
```json
{
  "group_id": 1,
  "group_name": "Travel Group Name",
  "preferred_city": "Hanoi",
  "travel_dates": "...",
  "itinerary": {
    "day_1": [...],
    "day_2": [...]
  },
  "group_image_url": "...",
  "interests": [...]
}
```

### 3. Test Từ Frontend
- Mở app Flutter
- Login vào account có nhóm
- Vào Chatbox → Click icon 🗺️
- ✅ Bản đồ hiển thị với các điểm từ itinerary

---

## 📊 Các Trường Hợp Khác

### Case 1: User Chưa Có Nhóm
**Response:** 400 Bad Request
```json
{
  "detail": "Chưa tham gia nhóm nào."
}
```

### Case 2: User Không Tồn Tại
**Response:** 404 Not Found
```json
{
  "detail": "Không tìm thấy profile"
}
```

### Case 3: Group ID Invalid
**Response:** 404 Not Found
```json
{
  "detail": "Lỗi dữ liệu nhóm ID: {group_id}"
}
```

---

## 🎯 Kết Luận

**Lỗi đã được fix:**
- ✅ SQL query sử dụng đúng `select(Profiles)` thay vì select từng cột
- ✅ API `/groups/plan` hoạt động bình thường
- ✅ MapRouteScreen có thể lấy được itinerary để vẽ bản đồ

**Files đã sửa:**
- `backend/group_services/utils.py` - Hàm `get_user_group_info()`

**Impact:**
- Không ảnh hưởng đến các API khác
- Không cần migrate database
- Chỉ cần restart backend để apply changes

---

## 🔗 Related APIs

API `/groups/plan` được sử dụng bởi:
1. ✅ `MapRouteScreen` - Hiển thị bản đồ lộ trình
2. ✅ `TravelPlanScreen` - Hiển thị kế hoạch chi tiết
3. ✅ Chatbox - Navigate to map route

Tất cả đều sẽ hoạt động bình thường sau khi fix.

