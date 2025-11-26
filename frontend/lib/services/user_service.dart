import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class UserService {
  final String baseUrl = ApiConfig.baseUrl;

  final Map<String, String> _cityMap = {
    'dalat': 'Đà Lạt',
    'danang': 'Đà Nẵng',
    'hanoi': 'Hà Nội',
    'nhatrang': 'Nha Trang',
    'phuquoc': 'Phú Quốc',
    'hoian': 'Hội An',
    'hue': 'Huế',
    'saigon': 'TP. Hồ Chí Minh',
    'sapa': 'Sa Pa',
    'halong': 'Hạ Long',
  };

  // Lấy preferred_city hiện tại
  Future<String?> getPreferredCity() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return null;

    try {
      final url = Uri.parse('$baseUrl/users/me');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Kiểm tra xem backend trả về structure nào.
        // Thường là data['preferred_city'] hoặc data['profile']['preferred_city']
        // Tạm thời để an toàn:
        return data['preferred_city'] ?? data['profile']?['preferred_city'];
      }
    } catch (e) {
      print('❌ Lỗi lấy thông tin user: $e');
    }
    return null;
  }

  // Cập nhật theo ID (logic cũ)
  Future<bool> updatePreferredCity(String cityId) async {
    final dbCityName = _cityMap[cityId];
    if (dbCityName == null) return false;
    return updatePreferredCityRaw(dbCityName);
  }

  // --- MỚI: Sửa PUT thành PATCH ---
  Future<bool> updatePreferredCityRaw(String dbCityName) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return false;

    try {
      final url = Uri.parse('$baseUrl/users/me');
      print("💾 Updating preferred_city via PATCH to: $dbCityName");

      // SỬA Ở ĐÂY: Dùng PATCH thay vì PUT
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'preferred_city': dbCityName,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print("✅ Đã update city thành công: $dbCityName");
        return true;
      } else {
        // In body lỗi để debug nếu backend từ chối
        print("❌ Server từ chối update (Code ${response.statusCode}): ${response.body}");
        return false;
      }
    } catch (e) {
      print('❌ Exception update city raw: $e');
      return false;
    }
  }
}