# ✅ Hướng Dẫn Hoàn Chỉnh - MapRouteScreen

## 🎯 Mục Tiêu Đã Hoàn Thành

Đã tạo màn hình `MapRouteScreen` để hiển thị bản đồ và vẽ lộ trình giữa các địa điểm từ API `/groups/plan`.

---

## 📦 Các Package Đã Sử Dụng

### 1. **flutter_map** (^7.0.2)
- Hiển thị bản đồ OpenStreetMap
- Hỗ trợ TileLayer, MarkerLayer, PolylineLayer

### 2. **latlong2** (^0.9.1)
- Định nghĩa tọa độ LatLng

### 3. **geocoding** (^3.0.0)
- Chuyển đổi tên địa điểm → tọa độ (Geocoding)
- Chuyển đổi tọa độ → địa chỉ (Reverse Geocoding)

### 4. **http** (^1.2.0)
- Gọi API backend và OSRM Routing Service

---

## 🔧 Các Tính Năng Chính

### 1. **Lấy Dữ Liệu từ API**
- **Group Plan**: Ưu tiên lấy từ `/groups/plan` nếu user có nhóm active
- **Personal Plan**: Fallback về `/users/profile` nếu không có nhóm hoặc nhóm expired
- Parse itinerary từ JSON để lấy danh sách địa điểm

### 2. **Geocoding Thông Minh**
```dart
// Tự động chuyển đổi tên địa điểm thành tọa độ
Future<LatLng?> _geocodeLocation(String locationName, String cityContext) async {
  final searchQuery = '$locationName, $cityContext';
  final locations = await locationFromAddress(searchQuery);
  
  if (locations.isNotEmpty) {
    return LatLng(locations.first.latitude, locations.first.longitude);
  }
  return null;
}
```

### 3. **Parse Itinerary Linh Hoạt**
- Hỗ trợ parse JSON string hoặc Map/List trực tiếp
- Tự động detect tọa độ từ các trường: `latitude/lat`, `longitude/lng/lon`
- Fallback sang geocoding nếu không có tọa độ
- Fallback sang dữ liệu mặc định nếu không parse được

### 4. **Vẽ Lộ Trình với OSRM**
```dart
// Sử dụng OSRM Public Demo Server
final url = Uri.parse(
  'https://router.project-osrm.org/route/v1/driving/$coordinates?overview=full&geometries=polyline',
);

// Decode polyline thành danh sách LatLng
final decodedPoints = _decodePolyline(encodedPolyline);
```

### 5. **Hiển thị Bản Đồ**
- **TileLayer**: Bản đồ nền OpenStreetMap
- **PolylineLayer**: Vẽ đường đi (màu xanh, độ dày 4px)
- **MarkerLayer**: Đánh dấu các điểm
  - 🟢 **Điểm đầu** (Icons.location_on, màu xanh lá)
  - 🟠 **Điểm dừng** (Icons.place, màu cam)
  - 🔴 **Điểm cuối** (Icons.flag, màu đỏ)

### 6. **UI/UX Features**
- Loading indicator khi tải dữ liệu
- Error handling với thông báo lỗi rõ ràng
- Zoom in/out buttons
- Fit bounds để hiển thị tất cả điểm
- Tap vào marker để xem thông tin địa điểm
- Legend (chú thích) ở góc dưới trái

---

## 🚀 Cách Sử Dụng

### Từ ChatboxScreen:
```dart
IconButton(
  icon: const Icon(Icons.map, color: Colors.white, size: 28),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MapRouteScreen(),
      ),
    );
  },
  tooltip: 'Xem lộ trình',
),
```

---

## 📊 Luồng Xử Lý Dữ Liệu

```
1. initState() 
   └─> _initializeMap()
       └─> _fetchGroupPlan()
           ├─> [TRY] Get /groups/my-group (check status)
           │   └─> if status == 'open' → Get /groups/plan
           │       └─> _parseItinerary(groupData)
           │
           └─> [FALLBACK] Get /users/profile
               └─> _parseItinerary(personalData)

2. _parseItinerary(data)
   ├─> Parse JSON itinerary
   ├─> Extract coordinates từ activity
   │   ├─> [IF có lat/lng] → Add to points
   │   └─> [ELSE] → _geocodeLocation(locationName)
   │
   └─> [FALLBACK] _useDefaultLocations(city)

3. _fetchRoute()
   ├─> Build OSRM API URL
   ├─> Call OSRM API
   └─> Decode polyline → _routePoints

4. Build Widget
   ├─> TileLayer (OSM)
   ├─> PolylineLayer (_routePoints)
   └─> MarkerLayer (_selectedPoints)
```

---

## 🗺️ Format Itinerary Hỗ Trợ

### Option 1: Có tọa độ sẵn
```json
{
  "day_1": [
    {
      "location": "Hồ Hoàn Kiếm",
      "latitude": 21.0285,
      "longitude": 105.8542
    }
  ]
}
```

### Option 2: Chỉ có tên (sẽ geocode)
```json
{
  "day_1": [
    {
      "location": "Hồ Hoàn Kiếm"
    }
  ]
}
```

### Option 3: String JSON
```json
{
  "day_1": "[{\"location\":\"Hồ Hoàn Kiếm\",\"lat\":21.0285,\"lng\":105.8542}]"
}
```

---

## 🛠️ Xử Lý Lỗi

### 1. **Không có token**
```
Lỗi: Không tìm thấy token xác thực
→ Yêu cầu login lại
```

### 2. **Không có nhóm/nhóm expired**
```
⚠️ Không lấy được group plan: ...
👤 Sử dụng personal plan (fallback tự động)
```

### 3. **Parse itinerary thất bại**
```
⚠️ No coordinates found, using default locations
→ Hiển thị điểm mặc định theo thành phố
```

### 4. **Geocoding thất bại**
```
⚠️ Geocoding failed for [địa điểm]: ...
→ Bỏ qua địa điểm đó, tiếp tục với địa điểm khác
```

### 5. **OSRM API lỗi**
```
❌ Lỗi khi lấy lộ trình: ...
→ Hiển thị chỉ markers, không có đường đi
```

---

## 🎨 Cải Tiến So Với Code Cũ

### ✅ Đã Sửa:
1. **Fallback thông minh**: Group plan → Personal plan → Default locations
2. **Geocoding tự động**: Chuyển tên địa điểm → tọa độ
3. **Parse itinerary linh hoạt**: Hỗ trợ nhiều format JSON
4. **Error handling tốt hơn**: Không crash khi lỗi, có fallback
5. **UI/UX cải thiện**: Loading, error messages, zoom controls

### ⚠️ Lưu Ý:
- Package `flutter_polyline_points` không được sử dụng (có thể xóa import)
- Sử dụng hàm `_decodePolyline` tự viết để decode OSRM polyline
- Geocoding cần internet và có thể chậm → có thể cache kết quả

---

## 📱 Testing Checklist

- [ ] Test với group plan có tọa độ sẵn
- [ ] Test với group plan chỉ có tên địa điểm
- [ ] Test với personal plan
- [ ] Test khi không có nhóm
- [ ] Test khi nhóm expired
- [ ] Test với itinerary rỗng
- [ ] Test zoom in/out
- [ ] Test tap vào marker
- [ ] Test nút refresh
- [ ] Test fit bounds

---

## 🔗 API Endpoints Sử Dụng

1. **GET** `/groups/my-group` - Check group status
2. **GET** `/groups/plan` - Get group plan
3. **GET** `/users/profile` - Get personal plan (fallback)
4. **GET** `https://router.project-osrm.org/route/v1/driving/...` - OSRM routing

---

## ✨ Kết Luận

MapRouteScreen đã hoàn chỉnh với các tính năng:
- ✅ Lấy dữ liệu từ API backend
- ✅ Geocoding tự động
- ✅ Vẽ lộ trình với OSRM
- ✅ UI/UX thân thiện
- ✅ Error handling tốt
- ✅ Fallback thông minh

**Sẵn sàng để testing và deploy!** 🚀

