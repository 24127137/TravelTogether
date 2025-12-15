<<<<<<< HEAD
=======
// Hàm tiện ích giúp chuyển đổi số an toàn (tránh lỗi crash khi server trả String)
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

>>>>>>> week10
class UnreviewedMember {
  final int profileId;
  final String fullname;
  final String email;

  UnreviewedMember({
    required this.profileId,
    required this.fullname,
    required this.email,
  });

  factory UnreviewedMember.fromJson(Map<String, dynamic> json) {
    return UnreviewedMember(
<<<<<<< HEAD
      profileId: json['profile_id'],
      // Fallback nếu tên null thì hiển thị default
=======
      profileId: json['profile_id'] is int ? json['profile_id'] : int.tryParse(json['profile_id'].toString()) ?? 0,
>>>>>>> week10
      fullname: json['fullname'] ?? 'Thành viên',
      email: json['email'] ?? '',
    );
  }
}

class PendingReviewGroup {
  final int groupId;
  final String groupName;
  final String? groupImageUrl;
  final List<UnreviewedMember> unreviewedMembers;

  PendingReviewGroup({
    required this.groupId,
    required this.groupName,
    this.groupImageUrl,
    required this.unreviewedMembers,
  });

  factory PendingReviewGroup.fromJson(Map<String, dynamic> json) {
    var list = json['unreviewed_members'] as List? ?? [];
    List<UnreviewedMember> membersList = list.map((i) => UnreviewedMember.fromJson(i)).toList();

    return PendingReviewGroup(
<<<<<<< HEAD
      groupId: json['group_id'],
=======
      groupId: json['group_id'] is int ? json['group_id'] : int.tryParse(json['group_id'].toString()) ?? 0,
>>>>>>> week10
      groupName: json['group_name'] ?? 'Nhóm du lịch',
      groupImageUrl: json['group_image_url'],
      unreviewedMembers: membersList,
    );
  }
}

<<<<<<< HEAD
// --- CÁC MODEL MỚI CHO REPUTATION ---
=======
// --- CÁC MODEL CHO REPUTATION (Đã sửa lỗi parse số) ---
>>>>>>> week10

class FeedbackDetail {
  final int id;
  final double rating;
  final List<String> content; // Tags
  final String? senderName;
  final bool anonymous;

  FeedbackDetail({
    required this.id,
    required this.rating,
    required this.content,
    this.senderName,
    required this.anonymous,
  });

  factory FeedbackDetail.fromJson(Map<String, dynamic> json) {
    return FeedbackDetail(
<<<<<<< HEAD
      id: json['id'],
      rating: (json['rating'] ?? 0).toDouble(),
=======
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      // SỬA: Dùng hàm _parseDouble an toàn
      rating: _parseDouble(json['rating']),
>>>>>>> week10
      content: (json['content'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      senderName: json['sender_name'],
      anonymous: json['anonymous'] ?? false,
    );
  }
}

class GroupReputationSummary {
  final int groupId;
  final String groupName;
  final String? groupImageUrl;
  final List<FeedbackDetail> feedbacks;

  GroupReputationSummary({
    required this.groupId,
    required this.groupName,
    this.groupImageUrl,
    required this.feedbacks,
  });

  factory GroupReputationSummary.fromJson(Map<String, dynamic> json) {
    var list = json['feedbacks'] as List? ?? [];
    List<FeedbackDetail> fbList = list.map((i) => FeedbackDetail.fromJson(i)).toList();

    return GroupReputationSummary(
<<<<<<< HEAD
      groupId: json['group_id'],
=======
      groupId: json['group_id'] is int ? json['group_id'] : int.tryParse(json['group_id'].toString()) ?? 0,
>>>>>>> week10
      groupName: json['group_name'] ?? 'Nhóm',
      groupImageUrl: json['group_image_url'],
      feedbacks: fbList,
    );
  }
}

class MyReputationResponse {
  final double averageRating;
  final int totalFeedbacks;
  final List<GroupReputationSummary> groups;

  MyReputationResponse({
    required this.averageRating,
    required this.totalFeedbacks,
    required this.groups,
  });

  factory MyReputationResponse.fromJson(Map<String, dynamic> json) {
    var list = json['groups'] as List? ?? [];
    List<GroupReputationSummary> groupList = list.map((i) => GroupReputationSummary.fromJson(i)).toList();

    return MyReputationResponse(
<<<<<<< HEAD
      averageRating: (json['average_rating'] ?? 0).toDouble(),
      totalFeedbacks: json['total_feedbacks'] ?? 0,
=======
      // SỬA: Dùng hàm _parseDouble an toàn
      averageRating: _parseDouble(json['average_rating']),
      totalFeedbacks: json['total_feedbacks'] is int ? json['total_feedbacks'] : int.tryParse(json['total_feedbacks'].toString()) ?? 0,
>>>>>>> week10
      groups: groupList,
    );
  }
}