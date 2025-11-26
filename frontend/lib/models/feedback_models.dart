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
      profileId: json['profile_id'],
      // Fallback nếu tên null thì hiển thị default
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
      groupId: json['group_id'],
      groupName: json['group_name'] ?? 'Nhóm du lịch',
      groupImageUrl: json['group_image_url'],
      unreviewedMembers: membersList,
    );
  }
}

// --- CÁC MODEL MỚI CHO REPUTATION ---

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
      id: json['id'],
      rating: (json['rating'] ?? 0).toDouble(),
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
      groupId: json['group_id'],
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
      averageRating: (json['average_rating'] ?? 0).toDouble(),
      totalFeedbacks: json['total_feedbacks'] ?? 0,
      groups: groupList,
    );
  }
}