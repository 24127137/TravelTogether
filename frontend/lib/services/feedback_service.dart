import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/feedback_models.dart'; // Import model vào đây

class FeedbackService {
  // TODO: Thay đổi URL này thành địa chỉ server thật của bạn
  // Ví dụ: "http://192.168.1.10:8000/feedbacks" hoặc domain thật
  final String baseUrl = "http://192.168.1.3:8000/feedbacks";

  /// Lấy danh sách các nhóm đã hết hạn nhưng chưa đánh giá xong
  Future<List<PendingReviewGroup>> getPendingReviews(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pending-reviews'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Backend trả về: { "pending_groups": [...] }
        var list = data['pending_groups'] as List? ?? [];
        return list.map((e) => PendingReviewGroup.fromJson(e)).toList();
      } else {
        // Có thể in log lỗi ra đây để debug
        print('Error fetching reviews: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load pending reviews');
      }
    } catch (e) {
      print('Exception in getPendingReviews: $e');
      rethrow;
    }
  }

  /// Gửi đánh giá lên server
  Future<bool> submitFeedback({
    required String token,
    required int revId,
    required int groupId,
    required int rating,
    required List<String> contentTags,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "rev_id": revId,
          "group_id": groupId,
          "rating": rating,
          "content": contentTags,
          "anonymous": false // Chỉnh thành true nếu muốn ẩn danh
        }),
      );

      // 200 OK là thành công
      return response.statusCode == 200;
    } catch (e) {
      print('Exception in submitFeedback: $e');
      return false;
    }
  }
}