import 'dart:convert';
<<<<<<< HEAD
=======
import 'dart:async';
>>>>>>> week10
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

<<<<<<< HEAD
<<<<<<< HEAD
  // ... (Giữ nguyên getPreferredCity, updatePreferredCityRaw, updatePreferredCity) ...
  // ... (Giữ nguyên getPreferredCity, updatePreferredCityRaw, updatePreferredCity) ...
=======
  // Lấy thành phố yêu thích
>>>>>>> 3ee7efe (done all groupapis)
=======
  // ... (Giữ nguyên getPreferredCity, updatePreferredCityRaw, updatePreferredCity) ...
>>>>>>> week10
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
<<<<<<< HEAD
<<<<<<< HEAD
  // FIX: LƯU ITINERARY THEO THÀNH PHỐ HIỆN TẠI
  // FIX: LƯU ITINERARY THEO THÀNH PHỐ HIỆN TẠI
=======
  // FIX LỖI 422: CHUYỂN LIST THÀNH MAP {"1": "A", "2": "B"}
>>>>>>> 3ee7efe (done all groupapis)
  // ===============================================================
  Future<bool> toggleItineraryItem(String placeName, bool isAdding) async {
=======
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
>>>>>>> week10
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return false;

    try {
      final url = Uri.parse('$baseUrl/users/me');

<<<<<<< HEAD
<<<<<<< HEAD
      // 1. GET DỮ LIỆU
      // 1. GET DỮ LIỆU
=======
      // --- BƯỚC 1: LẤY DỮ LIỆU CŨ TỪ SERVER ---
>>>>>>> 3ee7efe (done all groupapis)
=======
      // 1. GET DỮ LIỆU MỚI NHẤT TỪ SERVER
>>>>>>> week10
      final getResponse = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (getResponse.statusCode != 200) return false;

      final data = jsonDecode(utf8.decode(getResponse.bodyBytes));
<<<<<<< HEAD
<<<<<<< HEAD
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
=======
      var profileData = data['profile'] ?? data;

      // Lấy tên thành phố đang chọn (Ví dụ: "Đà Nẵng")
      String currentCity = profileData['preferred_city'] ?? "Unknown";
>>>>>>> week10
      String prefix = "${currentCity}_";

      var rawItinerary = profileData['itinerary'];

<<<<<<< HEAD
      List<String> currentCityItems = [];
      Map<String, String> otherCityItems = {};

      // 2. PHÂN LOẠI: Cái nào của city này, cái nào của city khác
=======
      // 2. PHÂN LOẠI DỮ LIỆU: Thành phố hiện tại vs Thành phố khác
      // Format: {"Hà Nội_1": "Phố cổ", "Đà Nẵng_1": "Cầu Rồng", ...}
      List<String> currentCityPlaces = []; // Địa điểm của thành phố đang chọn
      Map<String, String> otherCityItems = {}; // Giữ nguyên data của thành phố khác

>>>>>>> week10
      if (rawItinerary != null && rawItinerary is Map) {
        rawItinerary.forEach((key, value) {
          String strKey = key.toString();
          String strVal = value.toString();

          if (strKey.startsWith(prefix)) {
<<<<<<< HEAD
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
=======
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
>>>>>>> 3ee7efe (done all groupapis)
=======
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
>>>>>>> week10
      final patchResponse = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
<<<<<<< HEAD
<<<<<<< HEAD
          'itinerary': finalPayload,
=======
>>>>>>> week10
          'itinerary': finalPayload,
        }),
      );

<<<<<<< HEAD
      return (patchResponse.statusCode == 200 || patchResponse.statusCode == 204);
      return (patchResponse.statusCode == 200 || patchResponse.statusCode == 204);
=======
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
>>>>>>> 3ee7efe (done all groupapis)
=======
      final success = (patchResponse.statusCode == 200 || patchResponse.statusCode == 204);

      if (!success) {
        print("❌ Server trả về: ${patchResponse.statusCode} - ${patchResponse.body}");
      } else {
        print("✅ Lưu thành công!");
      }

      return success;
>>>>>>> week10

    } catch (e) {
      print('❌ [UserService] Exception: $e');
      return false;
    }
  }

<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> week10
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

<<<<<<< HEAD
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
=======
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
>>>>>>> week10
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
<<<<<<< HEAD
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
=======
  // Lấy profile đầy đủ
>>>>>>> 3ee7efe (done all groupapis)
  Future<Map<String, dynamic>?> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return null;
<<<<<<< HEAD
    try {
      final url = Uri.parse('$baseUrl/users/me');
      final response = await http.get(url, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'});
=======

    try {
      final url = Uri.parse('$baseUrl/users/me');
      final response = await http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token'
          }
      );

>>>>>>> 3ee7efe (done all groupapis)
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['profile'] ?? data;
      }
<<<<<<< HEAD
    } catch (e) { print('❌ $e'); }
    } catch (e) { print('❌ $e'); }
=======
    } catch (e) {
      print('❌ Lỗi lấy profile: $e');
    }
>>>>>>> 3ee7efe (done all groupapis)
    return null;
  }
=======
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
>>>>>>> week10
}