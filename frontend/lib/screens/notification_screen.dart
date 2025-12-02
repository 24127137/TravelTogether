import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/notification_service.dart';
import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../screens/host_member_screen.dart' as host;

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _hasNewNotifications = false;
  List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  String? _accessToken;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    // Clear notification badge khi vào màn hình
    NotificationService().clearBadge();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _accessToken = await AuthService.getValidAccessToken();
      if (_accessToken == null) {
        throw Exception('No access token found');
      }

      final url = ApiConfig.getUri(ApiConfig.groupManageRequests);
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_accessToken",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));

        setState(() {
          _notifications = data.map((item) => NotificationItem(
            id: item['profile_uuid'] as String,
            title: 'Yêu cầu tham gia nhóm',
            message: '${item['fullname']} muốn tham gia nhóm của bạn',
            time: _formatTimeAgo(DateTime.parse(item['requested_at'] as String)),
            isRead: false,
            type: 'group_request',
            userData: {
              'profile_uuid': item['profile_uuid'],
              'fullname': item['fullname'],
              'email': item['email'],
              'avatar_url': item['avatar_url'],
              'requested_at': item['requested_at'],
            },
          )).toList();

          _hasNewNotifications = _notifications.any((n) => !n.isRead);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải thông báo: $e')),
        );
      }
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  // === THÊM MỚI: Load đầy đủ dữ liệu nhóm và navigate tới MemberScreenHost ===
  Future<void> _navigateToMemberScreenWithFullData() async {
    try {
      // Hiển thị loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFB99668)),
        ),
      );

      _accessToken = await AuthService.getValidAccessToken();
      if (_accessToken == null) {
        throw Exception('No access token found');
      }

      // Gọi API lấy thông tin nhóm đầy đủ
      final groupUrl = ApiConfig.getUri(ApiConfig.myGroup);
      final groupResponse = await http.get(
        groupUrl,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_accessToken",
        },
      );

      if (groupResponse.statusCode != 200) {
        throw Exception('Failed to load group data: ${groupResponse.statusCode}');
      }

      final groupData = jsonDecode(utf8.decode(groupResponse.bodyBytes));

      // Parse dữ liệu nhóm
      final groupName = groupData['name']?.toString() ?? 'Unknown Group';
      final currentMembers = groupData['member_count'] as int? ?? 0;
      final maxMembers = groupData['max_members'] as int? ?? 0;

      // Parse danh sách members
      final List<host.Member> members = [];
      final List<dynamic> membersList = groupData['members'] ?? [];

      for (var memberData in membersList) {
        try {
          final profileUuid = memberData['profile_uuid']?.toString();
          final fullname = memberData['fullname']?.toString();
          final email = memberData['email']?.toString();
          final avatarUrl = memberData['avatar_url']?.toString();

          if (profileUuid != null && profileUuid.isNotEmpty) {
            members.add(host.Member(
              id: profileUuid,
              name: fullname ?? 'Unknown',
              email: email ?? 'no-email@example.com',
              avatarUrl: avatarUrl,
            ));
          }
        } catch (e) {
          print('⚠️ Error parsing member: $e');
          continue;
        }
      }

      // Đóng loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Navigate tới MemberScreenHost với dữ liệu đầy đủ và mở tab Pending
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => host.MemberScreenHost(
              groupName: groupName,
              currentMembers: currentMembers,
              maxMembers: maxMembers,
              members: members,
              openPendingTab: true, // === QUAN TRỌNG: Mở tab Pending ===
            ),
          ),
        );

        // Reload notifications sau khi quay lại để cập nhật trạng thái
        _loadNotifications();
      }

    } catch (e) {
      // Đóng loading dialog nếu có lỗi
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu nhóm: $e')),
        );
      }
    }
  }

  // === SỬA ĐỔI: Handle tap notification với việc xóa notification ===
  Future<void> _handleNotificationTap(NotificationItem notification) async {
    if (notification.type == 'group_request') {
      // Xóa notification khỏi danh sách trước khi navigate
      setState(() {
        _notifications.removeWhere((n) => n.id == notification.id);
        _hasNewNotifications = _notifications.any((n) => !n.isRead);
      });

      // Navigate với dữ liệu đầy đủ
      await _navigateToMemberScreenWithFullData();
    } else {
      // Xử lý các loại notification khác (message, etc.)
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
          _hasNewNotifications = _notifications.any((n) => !n.isRead);
        }
      });
    }
  }

  // === THÊM MỚI: Xóa một notification cụ thể ===
  void _removeNotification(String notificationId) {
    setState(() {
      _notifications.removeWhere((n) => n.id == notificationId);
      _hasNewNotifications = _notifications.any((n) => !n.isRead);
    });
  }

  // === THÊM MỚI: Xóa tất cả notifications ===
  void _clearAllNotifications() {
    setState(() {
      _notifications.clear();
      _hasNewNotifications = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'notification_title'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_notifications.isNotEmpty) // === Chỉ hiển thị nếu có notifications ===
            IconButton(
              icon: const Icon(Icons.clear_all, color: Colors.white),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Xóa tất cả thông báo'),
                    content: const Text('Bạn có chắc muốn xóa tất cả thông báo?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _clearAllNotifications();
                        },
                        child: const Text('Xóa tất cả', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              tooltip: 'Xóa tất cả thông báo',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFB99668)),
            )
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 80,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'no_notifications'.tr(),
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  color: const Color(0xFFB99668),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return Dismissible(
                        key: Key(notification.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          _removeNotification(notification.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã xóa thông báo')),
                          );
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: _buildNotificationCard(notification),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead ? const Color(0xFF1A1A1A) : const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead ? Colors.transparent : const Color(0xFFB99668),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleNotificationTap(notification),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar hoặc icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB99668),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: notification.type == 'group_request'
                      ? const Icon(Icons.group_add, color: Colors.white, size: 24)
                      : const Icon(Icons.message, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),

                // Nội dung
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.time,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Indicator cho unread notification
                if (!notification.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFB99668),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// === Data model cho notification ===
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String time;
  final bool isRead;
  final String type;
  final Map<String, dynamic>? userData;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    this.isRead = false,
    required this.type,
    this.userData,
  });

  // === THÊM MỚI: copyWith method để update notification ===
  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    String? time,
    bool? isRead,
    String? type,
    Map<String, dynamic>? userData,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      time: time ?? this.time,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      userData: userData ?? this.userData,
    );
  }
}
