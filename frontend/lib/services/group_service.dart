import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class GroupService {
  final String baseUrl = ApiConfig.baseUrl;

  // Lấy kế hoạch của nhóm mình đang tham gia
  Future<Map<String, dynamic>?> getMyGroupPlan(String token) async {
    try {
      final url = Uri.parse('$baseUrl/groups/plan');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Trả về JSON chứa itinerary
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        print('❌ Lỗi lấy Group Plan: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Exception GroupService: $e');
      return null;
    }
  }
}