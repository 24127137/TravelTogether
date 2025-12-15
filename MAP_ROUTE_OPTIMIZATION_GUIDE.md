# 🗺️ Hướng dẫn Tối ưu hóa Lộ trình Bản đồ

## 📋 Tổng quan
File `map_route_screen.dart` đã được cập nhật để:
1. ✅ Tự động lấy thông tin nhóm từ profile (giống `travel_plan_screen.dart`)
2. ✅ Tối ưu hóa thứ tự các địa điểm để có lộ trình ngắn nhất
3. ✅ Hiển thị danh sách địa điểm theo thứ tự đã tối ưu
4. ✅ Đổi màu AppBar sang màu kem (#FFF8E7)

---

## 🔄 Các thay đổi chính

### 1. **Logic lấy Group Plan**
Thay đổi từ:
```dart
// CŨ: Yêu cầu bắt buộc groupId
if (widget.groupId == null) {
  throw Exception('Không có ID nhóm');
}
```

Sang:
```dart
// MỚI: Tự động detect group từ profile
final profile = await _userService.getUserProfile();
// Kiểm tra status nhóm (open/closed/expired)
// Nếu không có nhóm -> dùng personal itinerary
```

### 2. **Parse Itinerary**
```dart
Future<void> _parseItineraryData(dynamic itineraryData, String cityContext, bool isGroupPlan)
```
- ✅ Hỗ trợ cả Group Plan và Personal Itinerary
- ✅ Filter theo thành phố (cho personal plan)
- ✅ Sử dụng Geocoding API để chuyển tên địa điểm thành tọa độ

### 3. **Tối ưu hóa Lộ trình với OSRM**

#### API Endpoint
```dart
// Sử dụng OSRM /trip endpoint
https://router.project-osrm.org/trip/v1/driving/{coordinates}
  ?overview=full
  &geometries=polyline
  &source=first
  &roundtrip=false  // Không quay về điểm xuất phát
```

#### Cập nhật thứ tự điểm
```dart
void _updatePointsOrder(List optimizedWaypoints)
```
- Parse `waypoint_index` từ OSRM response
- Sắp xếp lại `_selectedPoints` và `_locationNames` theo thứ tự tối ưu
- Log chi tiết quá trình reorder

### 4. **UI Improvements**

#### AppBar màu kem
```dart
AppBar(
  backgroundColor: const Color(0xFFFFF8E7), // Màu kem
  iconTheme: const IconThemeData(color: Colors.black87),
  // ...
)
```

#### Card hiển thị lộ trình
```dart
Positioned(
  top: 16, left: 16, right: 16,
  child: Card(
    // Hiển thị danh sách địa điểm theo thứ tự đã tối ưu
    // 1. Biển Mỹ Khê
    // 2. Chợ Hàn
    // 3. Bán đảo Sơn Trà
    // 4. Ngũ Hành Sơn
  )
)
```

---

## 🎯 Cách hoạt động

### Input
```json
{
  "Đà Nẵng_1": "Biển Mỹ Khê",
  "Đà Nẵng_2": "Chợ Hàn",
  "Đà Nẵng_3": "Bán đảo Sơn Trà",
  "Đà Nẵng_4": "Ngũ Hành Sơn"
}
```

### Quy trình xử lý

1. **Geocoding** (Chuyển tên → tọa độ)
   ```
   Biển Mỹ Khê → (16.0467, 108.2399)
   Chợ Hàn → (16.0678, 108.2208)
   ...
   ```

2. **OSRM Optimization** (Tối ưu thứ tự)
   ```
   Input:  [Mỹ Khê, Chợ Hàn, Sơn Trà, Ngũ Hành Sơn]
   Output: [Chợ Hàn, Mỹ Khê, Ngũ Hành Sơn, Sơn Trà]  ← Thứ tự ngắn nhất
   ```

3. **Reorder Points** (Cập nhật State)
   ```dart
   _selectedPoints = [điểm_theo_thứ_tự_mới]
   _locationNames = [tên_theo_thứ_tự_mới]
   ```

4. **Render Map** (Hiển thị)
   - Markers: Theo thứ tự đã tối ưu
   - Polyline: Đường đi ngắn nhất
   - Card: Danh sách địa điểm 1→2→3→4

---

## 🧪 Test & Verify

### Console Output mong đợi
```
🗺️ Đang geocode 4 địa điểm...
✅ Geocoded: Biển Mỹ Khê → LatLng(16.0467, 108.2399)
✅ Geocoded: Chợ Hàn → LatLng(16.0678, 108.2208)
...
✅ Successfully parsed 4 locations

🗺️ Fetching OPTIMIZED route from OSRM...
🔄 Reordering 4 waypoints...
  [0] Chợ Hàn (original index: 1)
  [1] Biển Mỹ Khê (original index: 0)
  [2] Ngũ Hành Sơn (original index: 3)
  [3] Bán đảo Sơn Trà (original index: 2)
✅ Đã sắp xếp lại 4 điểm theo OSRM optimization

✅ Route decoded and OPTIMIZED: 234 points
📍 Optimized order: Chợ Hàn → Biển Mỹ Khê → Ngũ Hành Sơn → Bán đảo Sơn Trà
```

### Visual Check
1. ✅ AppBar màu kem (#FFF8E7)
2. ✅ Card phía trên hiển thị danh sách địa điểm 1→2→3→4
3. ✅ Markers: Xanh (start) → Cam (waypoints) → Đỏ (end)
4. ✅ Polyline: Màu xanh dương, nối các điểm theo thứ tự tối ưu
5. ✅ Không còn thông báo lỗi "401 Unauthorized"

---

## 📦 Dependencies

```yaml
# pubspec.yaml
dependencies:
  flutter_map: ^7.0.2
  latlong2: ^0.9.1
  http: ^1.2.2
  geocoding: ^3.0.0
```

---

## 🔧 Troubleshooting

### Lỗi: "Không có ID nhóm hợp lệ"
**Giải pháp:** Code đã được sửa để không bắt buộc groupId. Nó sẽ tự động lấy từ profile.

### Lỗi: "401 Unauthorized"
**Nguyên nhân:** Token hết hạn hoặc chưa đăng nhập.
**Giải pháp:** Code đã dùng `AuthService.getValidAccessToken()` để tự động refresh token.

### Lỗi: Geocoding thất bại
**Nguyên nhân:** Tên địa điểm không rõ ràng hoặc không tồn tại.
**Giải pháp:** 
- Thêm context thành phố: `"Biển Mỹ Khê, Đà Nẵng"`
- Sử dụng tên tiếng Anh: `"My Khe Beach, Danang"`

### Thứ tự không tối ưu
**Nguyên nhân:** OSRM waypoints data không có `waypoint_index`.
**Giải pháp:** Code đã xử lý fallback, giữ nguyên thứ tự ban đầu nếu không parse được.

---

## 🚀 Cải tiến trong tương lai

- [ ] Thêm tùy chọn cho user chọn phương tiện: driving / walking / cycling
- [ ] Hiển thị thời gian ước tính và khoảng cách
- [ ] Cho phép user kéo thả để thay đổi thứ tự thủ công
- [ ] Cache kết quả geocoding để giảm API calls
- [ ] Hỗ trợ offline mode với bản đồ downloaded
- [ ] Thêm chức năng xuất lộ trình thành PDF

---

## ✅ Kết luận

Map Route Screen đã được tối ưu hóa hoàn toàn:
- ✅ Tự động lấy dữ liệu từ Group Plan hoặc Personal Itinerary
- ✅ Sắp xếp địa điểm theo lộ trình ngắn nhất
- ✅ UI thân thiện với màu kem và danh sách địa điểm rõ ràng
- ✅ Xử lý lỗi tốt, không crash khi thiếu dữ liệu

**Ngày cập nhật:** 01/12/2025

