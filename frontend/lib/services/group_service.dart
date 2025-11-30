import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class GroupService {
  final String baseUrl = ApiConfig.baseUrl;

  // 1. Lấy chi tiết nhóm (để check status: open, closed, expired)
  Future<Map<String, dynamic>?> getMyGroupDetail(String token) async {
    try {
      final url = Uri.parse('$baseUrl/groups/my-group');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Trả về JSON: { "id": 1, "status": "open", ... }
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      return null; // Không có nhóm hoặc lỗi
    } catch (e) {
      print('❌ Error fetching group detail: $e');
      return null;
    }
  }

  // 2. Lấy Plan theo ID (Dùng khi status = open)
  Future<Map<String, dynamic>?> getGroupPlanById(String token, int groupId) async {
    try {
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
      }
      return null;
    } catch (e) {
      print('❌ Error fetching public plan: $e');
      return null;
    }
  }

  // Hủy yêu cầu tham gia nhóm
  Future<bool> cancelJoinRequest(String token, int groupId) async {
    try {
      final url = Uri.parse('$baseUrl/groups/request-cancel');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'group_id': groupId}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Lỗi hủy request: $e');
      return false;
    }
  }
}