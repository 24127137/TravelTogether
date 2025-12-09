import 'dart:convert';
import 'dart:async';
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
  // FIX: LƯU ITINERARY THEO THÀNH PHỐ HIỆN TẠI VỚI MUTEX LOCK
  // ===============================================================

  // Queue để xử lý tuần tự các request
  static final List<_ItineraryTask> _taskQueue = [];
  static bool _isProcessing = false;

  Future<bool> toggleItineraryItem(String placeName, bool isAdding) async {
    // Tạo completer để đợi kết quả
    final completer = Completer<bool>();

    // Thêm task vào queue
    _taskQueue.add(_ItineraryTask(placeName, isAdding, completer));

    // Chạy queue nếu chưa đang xử lý
    _processQueue();

    return completer.future;
  }

  Future<void> _processQueue() async {
    if (_isProcessing || _taskQueue.isEmpty) return;
    _isProcessing = true;

    while (_taskQueue.isNotEmpty) {
      final task = _taskQueue.removeAt(0);
      final result = await _executeToggle(task.placeName, task.isAdding);
      task.completer.complete(result);

      // Delay nhỏ giữa các request để đảm bảo server xử lý xong
      await Future.delayed(const Duration(milliseconds: 100));
    }

    _isProcessing = false;
  }

  Future<bool> _executeToggle(String placeName, bool isAdding) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return false;

    try {
      final url = Uri.parse('$baseUrl/users/me');

      // 1. GET DỮ LIỆU MỚI NHẤT TỪ SERVER
      final getResponse = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (getResponse.statusCode != 200) return false;

      final data = jsonDecode(utf8.decode(getResponse.bodyBytes));
      var profileData = data['profile'] ?? data;

      // Lấy tên thành phố đang chọn (Ví dụ: "Đà Nẵng")
      String currentCity = profileData['preferred_city'] ?? "Unknown";
      String prefix = "${currentCity}_";

      var rawItinerary = profileData['itinerary'];

      // 2. PHÂN LOẠI DỮ LIỆU: Thành phố hiện tại vs Thành phố khác
      // Format: {"Hà Nội_1": "Phố cổ", "Đà Nẵng_1": "Cầu Rồng", ...}
      List<String> currentCityPlaces = []; // Địa điểm của thành phố đang chọn
      Map<String, String> otherCityItems = {}; // Giữ nguyên data của thành phố khác

      if (rawItinerary != null && rawItinerary is Map) {
        rawItinerary.forEach((key, value) {
          String strKey = key.toString();
          String strVal = value.toString();

          if (strKey.startsWith(prefix)) {
            // Thuộc thành phố hiện tại -> lấy tên địa điểm
            currentCityPlaces.add(strVal);
          } else {
            // Thuộc thành phố khác -> giữ nguyên
            otherCityItems[strKey] = strVal;
          }
        });
      }

      print("📊 [Before] $currentCity có ${currentCityPlaces.length} địa điểm: $currentCityPlaces");
      print("📊 [Before] Thành phố khác: $otherCityItems");

      // 3. THÊM / XÓA địa điểm (chỉ tác động vào currentCityPlaces)
      if (isAdding) {
        if (!currentCityPlaces.contains(placeName)) {
          currentCityPlaces.add(placeName);
          print("➕ Thêm '$placeName' vào $currentCity");
        }
      } else {
        currentCityPlaces.remove(placeName);
        print("➖ Xóa '$placeName' khỏi $currentCity");
      }

      // 4. TẠO PAYLOAD MỚI: GIỮ NGUYÊN THÀNH PHỐ KHÁC + ĐÁNH SỐ LẠI THÀNH PHỐ HIỆN TẠI
      Map<String, String> finalPayload = {};

      // 4.1 Copy tất cả thành phố khác (không thay đổi gì)
      finalPayload.addAll(otherCityItems);

      // 4.2 Đánh số lại thành phố hiện tại: Hà Nội_1, Hà Nội_2, ...
      for (int i = 0; i < currentCityPlaces.length; i++) {
        String newKey = "$prefix${i + 1}";
        finalPayload[newKey] = currentCityPlaces[i];
      }

      print("📝 [After] Payload gửi đi (${finalPayload.length} items): $finalPayload");

      // 5. GỬI LÊN SERVER
      final patchResponse = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'itinerary': finalPayload,
        }),
      );

      final success = (patchResponse.statusCode == 200 || patchResponse.statusCode == 204);

      if (!success) {
        print("❌ Server trả về: ${patchResponse.statusCode} - ${patchResponse.body}");
      } else {
        print("✅ Lưu thành công!");
      }

      return success;

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

        // Format: {"Hà Nội_1": "Phố cổ", "Đà Nẵng_1": "Cầu Rồng"}
        // Ta lấy tất cả Value (tên địa điểm) để đồng bộ trạng thái tim
        if (rawItinerary != null) {
          if (rawItinerary is Map) {
            for (var val in rawItinerary.values) {
              String name = val.toString();
              if (!savedNames.contains(name)) {
                savedNames.add(name);
              }
            }
          } else if (rawItinerary is List) {
            // Fallback trường hợp cũ (nếu có)
            for (var e in rawItinerary) {
              String name = e.toString();
              if (!savedNames.contains(name)) {
                savedNames.add(name);
              }
            }
          }
        }
        print("📥 [UserService] Đã load ${savedNames.length} địa điểm từ DB: $savedNames");
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
    return null;
  }
}

// Helper class cho task queue
class _ItineraryTask {
  final String placeName;
  final bool isAdding;
  final Completer<bool> completer;

  _ItineraryTask(this.placeName, this.isAdding, this.completer);
}