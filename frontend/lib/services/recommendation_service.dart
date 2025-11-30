import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart'; // Đảm bảo bạn có file config này chứa baseUrl

class RecommendationService {
  // Thay đổi URL này cho phù hợp với server của bạn (giống trong feedback_service)
  // Ví dụ: http://10.0.2.2:8000 hoặc IP LAN
  final String baseUrl = ApiConfig.baseUrl;

  Future<List<RecommendationOutput>> getMyRecommendations() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception('Chưa đăng nhập');
    }

    try {
      final url = Uri.parse('$baseUrl/recommendations/me');
      print('🤖 Calling AI Recommend: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        print('✅ AI Response: ${data.length} items');
        return data.map((e) => RecommendationOutput.fromJson(e)).toList();
      } else {
        print('❌ AI Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load recommendations');
      }
    } catch (e) {
      print('❌ AI Exception: $e');
      rethrow;
    }
  }
}

class RecommendationOutput {
  final String locationName;
  final int score;

  RecommendationOutput({required this.locationName, required this.score});

  factory RecommendationOutput.fromJson(Map<String, dynamic> json) {
    return RecommendationOutput(
      locationName: json['location_name'] ?? '',
      score: json['score'] ?? 0,
    );
  }
}