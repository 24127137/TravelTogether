import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class GroupService {
  final String baseUrl = ApiConfig.baseUrl;

  // Lấy kế hoạch của nhóm mình đang tham gia
  Future<Map<String, dynamic>?> getGroupPlanById(String token, int groupId) async {
    try {
      // Gọi vào endpoint: /groups/{id}/public-plan
      final url = Uri.parse('$baseUrl/groups/$groupId/public-plan');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        print('❌ Lỗi lấy Public Plan: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Exception GroupService: $e');
      return null;
    }
  }
}