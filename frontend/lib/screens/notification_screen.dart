import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../config/api_config.dart';
import '../services/notification_service.dart';
import 'chatbox_screen.dart';
// Import UserService để lấy thông tin Host
import '../services/user_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationData> _notifications = [];
  bool _isLoading = true;
  String? _accessToken;
  final UserService _userService = UserService(); // Khởi tạo UserService

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    // Xóa badge đỏ khi vào màn hình này
    NotificationService().clearBadge();
  }

  Future<void> _handleRefresh() async {
    await _loadNotifications();
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    final currentUserId = prefs.getString('user_id');
    final lastSeenMessageId = prefs.getString('last_seen_message_id');

    List<NotificationData> notifications = [];

    if (_accessToken != null) {
      // ======================================================
      // 1. LOAD THÔNG BÁO TIN NHẮN (Giữ nguyên logic cũ)
      // ======================================================
      try {
        final url = ApiConfig.getUri(ApiConfig.chatHistory);
        final response = await http.get(
          url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $_accessToken",
          },
        );

        if (response.statusCode == 200) {
          final List<dynamic> messages = jsonDecode(utf8.decode(response.bodyBytes));
          int unreadCount = 0;
          String? lastMessageTime;
          String? groupName;

          int lastSeenIndex = -1;
          if (lastSeenMessageId != null) {
            for (int i = 0; i < messages.length; i++) {
              if (messages[i]['id']?.toString() == lastSeenMessageId) {
                lastSeenIndex = i;
                break;
              }
            }
          }

          for (int i = lastSeenIndex + 1; i < messages.length; i++) {
            final msg = messages[i];
            final senderId = msg['sender_id']?.toString() ?? '';
            final isMyMessage = (currentUserId != null && senderId == currentUserId);

            if (isMyMessage) continue;

            unreadCount++;
            final createdAtUtc = DateTime.parse(msg['created_at']);
            lastMessageTime = _formatTime(createdAtUtc.toLocal());
          }

          // Load tên nhóm để hiển thị
          groupName = prefs.getString('cached_group_name') ?? 'Nhóm chat';

          if (unreadCount > 0) {
            notifications.add(NotificationData(
              icon: 'assets/images/message.jpg',
              title: groupName,
              subtitle: unreadCount > 1
                  ? ' - $unreadCount tin nhắn mới'
                  : ' - 1 tin nhắn mới',
              type: NotificationType.message,
              time: lastMessageTime,
              unreadCount: unreadCount,
            ));
          }
        }
      } catch (e) {
        print('Error loading chat notifications: $e');
      }

      // ======================================================
      // 2. LOAD THÔNG BÁO YÊU CẦU GIA NHẬP (MỚI)
      // ======================================================
      try {
        // B1: Lấy Profile để check xem User có phải là Host không
        final userProfile = await _userService.getUserProfile();

        if (userProfile != null) {
          final List ownedGroups = userProfile['owned_groups'] ?? [];

          // Nếu user đang làm chủ ít nhất 1 nhóm
          if (ownedGroups.isNotEmpty) {
            // B2: Gọi API lấy danh sách yêu cầu pending
            // Endpoint: /groups/manage/requests
            final requestUrl = ApiConfig.getUri(ApiConfig.groupManageRequests);
            final requestResponse = await http.get(
              requestUrl,
              headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer $_accessToken",
              },
            );

            if (requestResponse.statusCode == 200) {
              final List<dynamic> requests = jsonDecode(utf8.decode(requestResponse.bodyBytes));

              // B3: Duyệt danh sách yêu cầu và tạo NotificationData
              for (var req in requests) {
                // Chỉ lấy những request đang chờ duyệt (status 'pending')
                // Tùy vào API trả về, giả sử API trả về list requests

                final String requesterName = req['user']?['fullname'] ?? 'Ai đó';
                final String targetGroupName = req['group']?['name'] ?? 'nhóm của bạn';
                final String createdAt = req['created_at'] ?? '';

                String timeDisplay = '';
                if (createdAt.isNotEmpty) {
                  timeDisplay = _formatTime(DateTime.parse(createdAt).toLocal());
                }

                notifications.add(NotificationData(
                  // Icon placeholder (sẽ được xử lý trong UI)
                  icon: 'assets/images/user_add.png',
                  title: '$requesterName xin gia nhập nhóm $targetGroupName',
                  subtitle: null, // Không cần subtitle
                  type: NotificationType.groupRequest, // Loại mới
                  time: timeDisplay,
                ));
              }
            }
          }
        }
      } catch (e) {
        print('Error loading group requests: $e');
      }
    }

    setState(() {
      _notifications = notifications;
      _isLoading = false;
    });
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return DateFormat('d/M/yyyy').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/notification.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: CircleAvatar(
                radius: 72.5,
                backgroundImage: AssetImage('assets/images/notification_logo.png'),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFB99668)))
                  : _notifications.isEmpty
                  ? RefreshIndicator(
                color: const Color(0xFFB99668),
                backgroundColor: Colors.white,
                onRefresh: _handleRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: Text(
                        'Không có thông báo mới',
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
                      ),
                    ),
                  ),
                ),
              )
                  : RefreshIndicator(
                color: const Color(0xFFB99668),
                backgroundColor: Colors.white,
                onRefresh: _handleRefresh,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 20),
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];
                      return NotificationItem(
                        icon: notif.icon,
                        title: notif.title,
                        subtitle: notif.subtitle,
                        type: notif.type,
                        time: notif.time,
                        unreadCount: notif.unreadCount,
                        onTap: () async {
                          if (notif.type == NotificationType.message) {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ChatboxScreen()),
                            );
                            _loadNotifications();
                          }
                          // Xử lý tap cho Group Request (nếu cần)
                          // Ví dụ: Navigate sang màn hình Duyệt thành viên
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 1. CẬP NHẬT ENUM
enum NotificationType { matching, message, security, groupRequest }

class NotificationData {
  final String icon;
  final String title;
  final String? subtitle;
  final NotificationType type;
  final String? time;
  final int? unreadCount;

  NotificationData({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.type,
    this.time,
    this.unreadCount,
  });
}

class NotificationItem extends StatelessWidget {
  final String icon;
  final String title;
  final String? subtitle;
  final NotificationType type;
  final String? time;
  final int? unreadCount;
  final VoidCallback? onTap;

  const NotificationItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.type,
    this.time,
    this.unreadCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Định nghĩa màu nền và icon cho từng loại
    Color iconBgColor;
    Widget iconWidget;

    switch (type) {
      case NotificationType.message:
        iconBgColor = const Color(0xFFE0CEC0); // Màu nâu nhạt
        iconWidget = const Icon(Icons.message, color: Colors.white, size: 28);
        break;
      case NotificationType.groupRequest:
        iconBgColor = const Color(0xFF81C784); // Màu xanh lá cho Request
        iconWidget = const Icon(Icons.person_add, color: Colors.white, size: 28);
        break;
      default:
      // Các loại khác dùng hình ảnh asset
        iconBgColor = Colors.transparent;
        iconWidget = Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: AssetImage(icon),
              fit: BoxFit.cover,
            ),
          ),
        );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFB99668),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          children: [
            // Icon section
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconBgColor,
                  ),
                  // Nếu là default (ảnh) thì widget container ở trên đã có ảnh
                  // Nếu là icon (message/request) thì hiển thị iconWidget
                  child: type == NotificationType.message || type == NotificationType.groupRequest
                      ? Center(child: iconWidget)
                      : iconWidget,
                ),
                if (unreadCount != null && unreadCount! > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFB99668), width: 2),
                      ),
                      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                      child: Text(
                        unreadCount! > 99 ? '99+' : '$unreadCount',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),

            // Content section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: title,
                          style: const TextStyle(
                            color: Color(0xFFEDE2CC),
                            fontSize: 18,
                            fontFamily: 'Alegreya', // Font chữ của bạn
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (subtitle != null)
                          TextSpan(
                            text: subtitle,
                            style: const TextStyle(
                              color: Color(0xFFEDE2CC),
                              fontSize: 16,
                              fontFamily: 'Alegreya',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (time != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      time!,
                      style: TextStyle(
                        color: const Color(0xFFEDE2CC).withOpacity(0.7),
                        fontSize: 12,
                        fontFamily: 'Alegreya',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFFEDE2CC), size: 20),
          ],
        ),
      ),
    );
  }
}