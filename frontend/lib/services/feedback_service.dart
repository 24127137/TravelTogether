import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/feedback_models.dart'; // Import model vào đây
import '../config/api_config.dart'; // Use centralized API config

class FeedbackService {
  // Use the feedback base URL from ApiConfig instead of a hardcoded string
  final String baseUrl = ApiConfig.feedbackBaseUrl;

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

  Future<MyReputationResponse?> getMyReputation(String token) async {
    try {
      final url = Uri.parse('$baseUrl/my-reputation');
      print("📡 Calling Reputation API: $url");

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return MyReputationResponse.fromJson(data);
      } else {
        print('❌ Error fetching reputation: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Exception in getMyReputation: $e');
      return null;
    }
  }

  /// Lấy reputation của user khác bằng profile_uuid
  Future<MyReputationResponse?> getUserReputation(String token, String profileUuid) async {
    try {
      // 1. Gọi API List Feedbacks với tham số receiver_uuid
      final url = Uri.parse('$baseUrl/?receiver_uuid=$profileUuid');

      print("📡 Calling Feedback API: $url");

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));

        // API trả về: { "meta": { "average_rating": 4.5, "total": 10 }, "data": [...] }
        final meta = jsonResponse['meta'] ?? {};
        final List<dynamic> rawData = jsonResponse['data'] ?? [];

        // 2. Lấy Rating trung bình và Tổng số feedback
        double avgRating = 0.0;
        if (meta['average_rating'] != null) {
          avgRating = double.tryParse(meta['average_rating'].toString()) ?? 0.0;
        }

        int totalFeedbacks = 0;
        if (meta['total'] != null) {
          totalFeedbacks = int.tryParse(meta['total'].toString()) ?? 0;
        }

        // 3. Chuyển đổi danh sách thô (data) thành danh sách FeedbackDetail
        // Lưu ý: FeedbackDetail.fromJson cần khớp với model bạn đã có
        List<FeedbackDetail> details = rawData.map((e) => FeedbackDetail.fromJson(e)).toList();

        // 4. Đóng gói vào MyReputationResponse
        // Vì API này trả về list phẳng, ta tạo một "nhóm giả" (dummy group) để chứa tất cả feedback
        // Điều này giúp UI (vốn hiển thị theo nhóm) vẫn hoạt động bình thường mà không cần sửa UI
        return MyReputationResponse(
          averageRating: avgRating,
          totalFeedbacks: totalFeedbacks,
          groups: [
            if (details.isNotEmpty)
              GroupReputationSummary(
                groupId: 0, // ID giả
                groupName: "Tất cả đánh giá", // Tên hiển thị chung
                feedbacks: details,
                groupImageUrl: null,
              )
          ],
        );
      }

      print('❌ API Error: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('❌ Error fetching user reputation: $e');
      return null;
    }
  }
}