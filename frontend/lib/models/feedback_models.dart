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