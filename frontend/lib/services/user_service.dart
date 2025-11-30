import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class UserService {
  final String baseUrl = ApiConfig.baseUrl;

  final Map<String, String> _cityMap = {
    'dalat': 'Đà Lạt', 'danang': 'Đà Nẵng', 'hanoi': 'Hà Nội',
    'nhatrang': 'Nha Trang', 'phuquoc': 'Phú Quốc', 'hoian': 'Hội An',
    'hue': 'Huế', 'saigon': 'TP. Hồ Chí Minh', 'hochiminh': 'TP. Hồ Chí Minh',
    'sapa': 'Sa Pa', 'halong': 'Hạ Long',
  };

  // Lấy thành phố yêu thích
  Future<String?> getPreferredCity() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return null;
    try {
      final url = Uri.parse('$baseUrl/users/me');
      final response = await http.get(url, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['preferred_city'] ?? data['profile']?['preferred_city'];
      }
    } catch (e) { print('❌ $e'); }
    return null;
  }

  Future<bool> updatePreferredCityRaw(String dbCityName) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return false;
    try {
      final url = Uri.parse('$baseUrl/users/me');
      final response = await http.patch(url, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: jsonEncode({'preferred_city': dbCityName}));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) { return false; }
  }

  Future<bool> updatePreferredCity(String cityId) async {
    final dbCityName = _cityMap[cityId];
    if (dbCityName == null) return false;
    return updatePreferredCityRaw(dbCityName);
  }

  // ===============================================================
  // FIX LỖI 422: CHUYỂN LIST THÀNH MAP {"1": "A", "2": "B"}
  // ===============================================================
  Future<bool> toggleItineraryItem(String placeName, bool isAdding) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return false;

    try {
      final url = Uri.parse('$baseUrl/users/me');

      // --- BƯỚC 1: LẤY DỮ LIỆU CŨ TỪ SERVER ---
      final getResponse = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (getResponse.statusCode != 200) return false;

      final data = jsonDecode(utf8.decode(getResponse.bodyBytes));
      List<String> currentItineraryList = []; // Dùng List để dễ thêm/xóa

      var profileData = data['profile'] ?? data;
      var rawItinerary = profileData['itinerary'];

      // LOGIC GIẢI MÃ: Chuyển mọi định dạng (Map hoặc List) về List<String> để xử lý
      if (rawItinerary != null) {
        if (rawItinerary is List) {
          // Trường hợp 1: Là List ["A", "B"]
          currentItineraryList = List<String>.from(rawItinerary.map((e) => e.toString()));
        } else if (rawItinerary is Map) {
          // Trường hợp 2: Là Map
          if (rawItinerary.containsKey('places') && rawItinerary['places'] is List) {
            // Dạng cũ: {"places": ["A", "B"]}
            var list = rawItinerary['places'] as List;
            currentItineraryList = list.map((e) => e.toString()).toList();
          } else {
            // Dạng chuẩn Backend: {"1": "A", "2": "B"}
            // Lấy values ra và cho vào List
            for (var val in rawItinerary.values) {
              currentItineraryList.add(val.toString());
            }
          }
        }
      }

      // --- BƯỚC 2: THỰC HIỆN THÊM / XÓA ---
      if (isAdding) {
        if (!currentItineraryList.contains(placeName)) {
          currentItineraryList.add(placeName);
        }
      } else {
        currentItineraryList.remove(placeName);
      }

      // --- BƯỚC 3: ĐÓNG GÓI LẠI THÀNH MAP SỐ THỨ TỰ (QUAN TRỌNG) ---
      // Backend yêu cầu Dict[str, str] nên ta phải chuyển List -> Map
      // Ví dụ: ["A", "B"] -> {"1": "A", "2": "B"}
      Map<String, String> payloadMap = {};
      for (int i = 0; i < currentItineraryList.length; i++) {
        // Key là số thứ tự dạng chuỗi ("1", "2"...)
        payloadMap[(i + 1).toString()] = currentItineraryList[i];
      }

      print("📝 Payload gửi đi (Map chuẩn): {'itinerary': $payloadMap}");

      // --- BƯỚC 4: GỬI PATCH ---
      final patchResponse = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'itinerary': payloadMap, // Gửi Map { "1": "..." } thay vì List
        }),
      );

      if (patchResponse.statusCode == 200 || patchResponse.statusCode == 204) {
        print("✅ [UserService] Lưu Itinerary thành công!");
        return true;
      } else {
        print("❌ [UserService] Lỗi server: ${patchResponse.statusCode} - ${patchResponse.body}");
        return false;
      }

    } catch (e) {
      print('❌ [UserService] Exception: $e');
      return false;
    }
  }

  // Lấy profile đầy đủ
  Future<Map<String, dynamic>?> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return null;

    try {
      final url = Uri.parse('$baseUrl/users/me');
      final response = await http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token'
          }
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['profile'] ?? data;
      }
    } catch (e) {
      print('❌ Lỗi lấy profile: $e');
    }
    return null;
  }
}