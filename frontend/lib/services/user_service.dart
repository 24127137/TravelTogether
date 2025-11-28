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

  // ... (Giữ nguyên getPreferredCity, updatePreferredCityRaw, updatePreferredCity) ...
  // ... (Giữ nguyên getPreferredCity, updatePreferredCityRaw, updatePreferredCity) ...
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
  // FIX: LƯU ITINERARY THEO THÀNH PHỐ HIỆN TẠI
  // FIX: LƯU ITINERARY THEO THÀNH PHỐ HIỆN TẠI
  // ===============================================================
  Future<bool> toggleItineraryItem(String placeName, bool isAdding) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return false;

    try {
      final url = Uri.parse('$baseUrl/users/me');

      // 1. GET DỮ LIỆU
      // 1. GET DỮ LIỆU
      final getResponse = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (getResponse.statusCode != 200) return false;

      final data = jsonDecode(utf8.decode(getResponse.bodyBytes));
      var profileData = data['profile'] ?? data;

      // Lấy tên thành phố đang chọn (Ví dụ: "Đà Nẵng")
      // Nếu null thì dùng "Unknown"
      String currentCity = profileData['preferred_city'] ?? "Unknown";

      // Tạo prefix để phân biệt (Ví dụ: "Đà Nẵng_")
      String prefix = "${currentCity}_";


      // Lấy tên thành phố đang chọn (Ví dụ: "Đà Nẵng")
      // Nếu null thì dùng "Unknown"
      String currentCity = profileData['preferred_city'] ?? "Unknown";

      // Tạo prefix để phân biệt (Ví dụ: "Đà Nẵng_")
      String prefix = "${currentCity}_";

      var rawItinerary = profileData['itinerary'];

      List<String> currentCityItems = [];
      Map<String, String> otherCityItems = {};

      // 2. PHÂN LOẠI: Cái nào của city này, cái nào của city khác
      if (rawItinerary != null && rawItinerary is Map) {
        rawItinerary.forEach((key, value) {
          String strKey = key.toString();
          String strVal = value.toString();

          if (strKey.startsWith(prefix)) {
            currentCityItems.add(strVal);
      List<String> currentCityItems = [];
      Map<String, String> otherCityItems = {};

      // 2. PHÂN LOẠI: Cái nào của city này, cái nào của city khác
      if (rawItinerary != null && rawItinerary is Map) {
        rawItinerary.forEach((key, value) {
          String strKey = key.toString();
          String strVal = value.toString();

          if (strKey.startsWith(prefix)) {
            currentCityItems.add(strVal);
          } else {
            // Giữ lại dữ liệu của các thành phố khác
            otherCityItems[strKey] = strVal;
            // Giữ lại dữ liệu của các thành phố khác
            otherCityItems[strKey] = strVal;
          }
        });
        });
      }

      // 3. THÊM / XÓA (Chỉ tác động vào list của city hiện tại)
      // 3. THÊM / XÓA (Chỉ tác động vào list của city hiện tại)
      if (isAdding) {
        if (!currentCityItems.contains(placeName)) {
          currentCityItems.add(placeName);
        if (!currentCityItems.contains(placeName)) {
          currentCityItems.add(placeName);
        }
      } else {
        currentCityItems.remove(placeName);
        currentCityItems.remove(placeName);
      }

      // 4. ĐÓNG GÓI LẠI
      Map<String, String> finalPayload = {};

      // 4.1 Chép lại city khác
      finalPayload.addAll(otherCityItems);

      // 4.2 Chép city hiện tại với key mới (đánh số lại)
      for (int i = 0; i < currentCityItems.length; i++) {
        String newKey = "$prefix${i + 1}"; // Ví dụ: "Đà Nẵng_1"
        finalPayload[newKey] = currentCityItems[i];
      // 4. ĐÓNG GÓI LẠI
      Map<String, String> finalPayload = {};

      // 4.1 Chép lại city khác
      finalPayload.addAll(otherCityItems);

      // 4.2 Chép city hiện tại với key mới (đánh số lại)
      for (int i = 0; i < currentCityItems.length; i++) {
        String newKey = "$prefix${i + 1}"; // Ví dụ: "Đà Nẵng_1"
        finalPayload[newKey] = currentCityItems[i];
      }

      print("📝 Payload chuẩn bị gửi: $finalPayload");
      print("📝 Payload chuẩn bị gửi: $finalPayload");

      // 5. GỬI ĐI
      // 5. GỬI ĐI
      final patchResponse = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'itinerary': finalPayload,
          'itinerary': finalPayload,
        }),
      );

      return (patchResponse.statusCode == 200 || patchResponse.statusCode == 204);
      return (patchResponse.statusCode == 200 || patchResponse.statusCode == 204);

    } catch (e) {
      print('❌ [UserService] Exception: $e');
      return false;
    }
  }

  // Hàm này trả về danh sách tên địa điểm đã lưu: ["Cầu Rồng", "Bà Nà Hills"]
  Future<List<String>> getSavedItineraryNames() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return [];

    try {
      final url = Uri.parse('$baseUrl/users/me');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        var profileData = data['profile'] ?? data;
        var rawItinerary = profileData['itinerary'];

        List<String> savedNames = [];

        // Logic giải mã (giống hàm toggle): Lấy tất cả Value trong Map ra
        if (rawItinerary != null) {
          if (rawItinerary is Map) {
            // Backend trả về {"Đà Nẵng_1": "Cầu Rồng", "Hà Nội_1": "Hồ Gươm"}
            // Ta chỉ cần lấy phần Value ("Cầu Rồng", "Hồ Gươm")
            for (var val in rawItinerary.values) {
              savedNames.add(val.toString());
            }
          } else if (rawItinerary is List) {
            // Fallback trường hợp cũ
            savedNames = List<String>.from(rawItinerary.map((e) => e.toString()));
          }
        }
        return savedNames;
      }
    } catch (e) {
      print('❌ Lỗi lấy itinerary: $e');
    }
    return [];
  }

  // ... (Hàm getUserProfile giữ nguyên) ...
  Future<Map<String, dynamic>?> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return [];

    if (token == null) return null;
    try {
      final url = Uri.parse('$baseUrl/users/me');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      final response = await http.get(url, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        var profileData = data['profile'] ?? data;
        var rawItinerary = profileData['itinerary'];

        List<String> savedNames = [];

        // Logic giải mã (giống hàm toggle): Lấy tất cả Value trong Map ra
        if (rawItinerary != null) {
          if (rawItinerary is Map) {
            // Backend trả về {"Đà Nẵng_1": "Cầu Rồng", "Hà Nội_1": "Hồ Gươm"}
            // Ta chỉ cần lấy phần Value ("Cầu Rồng", "Hồ Gươm")
            for (var val in rawItinerary.values) {
              savedNames.add(val.toString());
            }
          } else if (rawItinerary is List) {
            // Fallback trường hợp cũ
            savedNames = List<String>.from(rawItinerary.map((e) => e.toString()));
          }
        }
        return savedNames;
      }
    } catch (e) {
      print('❌ Lỗi lấy itinerary: $e');
    }
    return [];
  }

  // ... (Hàm getUserProfile giữ nguyên) ...
  Future<Map<String, dynamic>?> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return null;
    try {
      final url = Uri.parse('$baseUrl/users/me');
      final response = await http.get(url, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['profile'] ?? data;
      }
    } catch (e) { print('❌ $e'); }
    } catch (e) { print('❌ $e'); }
    return null;
  }
}