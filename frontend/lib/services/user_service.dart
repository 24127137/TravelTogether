import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class UserService {
  final String baseUrl = ApiConfig.baseUrl;

  final Map<String, String> _cityMap = {
    'dalat': 'Đà Lạt', 'danang': 'Đà Nẵng', 'hanoi': 'Hà Nội',
    'nhatrang': 'Nha Trang', 'phuquoc': 'Phú Quốc', 'hoian': 'Hội An',
    'hue': 'Huế', 'saigon': 'TP. Hồ Chí Minh', 'hochiminh': 'TP. Hồ Chí Minh', 'sapa': 'Sa Pa', 'halong': 'Hạ Long',
  };

  // ... (Giữ nguyên getPreferredCity & updatePreferredCity cũ) ...
  Future<String?> getPreferredCity() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return null;
    try {
      final url = Uri.parse('$baseUrl/users/me');
      final response = await http.get(url, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
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
  // FIX LỖI 422: ĐÓNG GÓI LIST VÀO DICTIONARY
  // ===============================================================
  Future<bool> toggleItineraryItem(String placeName, bool isAdding) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return false;

    try {
      final url = Uri.parse('$baseUrl/users/me');

      // --- BƯỚC 1: GET (LẤY DỮ LIỆU CŨ) ---
      final getResponse = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (getResponse.statusCode != 200) return false;

      final data = jsonDecode(getResponse.body);
      List<dynamic> currentItinerary = [];

      // Lấy data an toàn
      var profileData = data['profile'] ?? data;
      var rawItinerary = profileData['itinerary'];

      // LOGIC MỞ GÓI (UNWRAP)
      if (rawItinerary != null) {
        if (rawItinerary is List) {
          // Trường hợp backend trả về List (Lý tưởng)
          currentItinerary = List.from(rawItinerary);
        } else if (rawItinerary is Map) {
          // Trường hợp backend trả về Dict (Thực tế lỗi 422 đang gặp)
          // Ta quy ước key là 'places'
          if (rawItinerary['places'] is List) {
            currentItinerary = List.from(rawItinerary['places']);
          }
        }
      }

      // --- BƯỚC 2: MODIFY (THÊM/XÓA) ---
      if (isAdding) {
        if (!currentItinerary.contains(placeName)) {
          currentItinerary.add(placeName);
        }
      } else {
        currentItinerary.remove(placeName);
      }

      print("📝 Payload chuẩn bị gửi: {'places': $currentItinerary}");

      // --- BƯỚC 3: PATCH (GỬI ĐI VỚI DẠNG DICTIONARY) ---
      final patchResponse = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          // QUAN TRỌNG: Gói List vào trong Map với key là 'places'
          // Để thỏa mãn yêu cầu "Input should be a valid dictionary" của Backend
          'itinerary': {'places': currentItinerary},
        }),
      );

      if (patchResponse.statusCode == 200 || patchResponse.statusCode == 204) {
        print("✅ [UserService] Lưu Itinerary thành công!");
        return true;
      } else {
        print("❌ [UserService] Lỗi server: ${patchResponse.body}");
        return false;
      }

    } catch (e) {
      print('❌ [UserService] Exception: $e');
      return false;
    }
  }

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
        // Cần decode utf8 để hiển thị tiếng Việt đúng
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        // Backend có thể trả về trực tiếp hoặc bọc trong key 'profile'
        return data['profile'] ?? data;
      }
    } catch (e) {
      print('❌ Lỗi lấy profile: $e');
    }
    return null;
  }
}
