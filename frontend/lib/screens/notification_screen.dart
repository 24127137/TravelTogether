import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../config/api_config.dart';
import 'chatbox_screen.dart'; // === THÊM MỚI: Import chatbox screen ===

//File này là screen tên là <Notification> trong figma
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationData> _notifications = [];
  bool _isLoading = true;
  String? _accessToken;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  // Hàm xử lý pull-to-refresh
  Future<void> _handleRefresh() async {
    await _loadNotifications();
    // Thêm delay nhỏ để animation mượt hơn
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    final currentUserId = prefs.getString('user_id');
    final lastSeenMessageId = prefs.getString('last_seen_message_id');

    List<NotificationData> notifications = [];

    // Load thông báo tin nhắn mới từ group chat
    if (_accessToken != null) {
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

          // Đếm số tin nhắn chưa đọc
          int unreadCount = 0;
          String? lastMessageContent;
          String? lastMessageTime;
          String? groupName;

          for (var msg in messages.reversed) {
            final senderId = msg['sender_id']?.toString() ?? '';
            final messageId = msg['id']?.toString() ?? '';
            final isMyMessage = (currentUserId != null && senderId == currentUserId);

            // Nếu không phải tin nhắn của mình và chưa seen
            if (!isMyMessage) {
              if (lastSeenMessageId == null || messageId != lastSeenMessageId) {
                unreadCount++;

                // Lưu tin nhắn cuối cùng chưa đọc
                if (lastMessageContent == null) {
                  lastMessageContent = msg['content'] ?? '';
                  final createdAtUtc = DateTime.parse(msg['created_at']);
                  final createdAtLocal = createdAtUtc.toLocal();
                  lastMessageTime = _formatTime(createdAtLocal);
                }
              } else {
                // Đã gặp tin nhắn đã seen, dừng đếm
                break;
              }
            }
          }

          // Load group name
          try {
            final groupUrl = ApiConfig.getUri(ApiConfig.myGroup);
            final groupResponse = await http.get(
              groupUrl,
              headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer $_accessToken",
              },
            );

            if (groupResponse.statusCode == 200) {
              final groupData = jsonDecode(utf8.decode(groupResponse.bodyBytes));
              groupName = groupData['name'] ?? 'Nhóm chat';
            }
          } catch (e) {
            print('Error loading group name: $e');
            groupName = 'Nhóm chat';
          }

          // Nếu có tin nhắn chưa đọc, thêm vào danh sách thông báo
          if (unreadCount > 0) {
            notifications.add(NotificationData(
              icon: 'assets/images/message.jpg',
              title: groupName ?? 'Nhóm chat',
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
    }

    // === MOCK DATA CŨ (COMMENTED) ===
    /*
    notifications.addAll([
      NotificationData(
        icon: 'assets/images/heart.jpg',
        title: 'Tìm nhóm thành công',
        type: NotificationType.matching,
      ),
      NotificationData(
        icon: 'assets/images/message.jpg',
        title: '1 tháng 2 lần',
        subtitle: ' nhắn tin',
        type: NotificationType.message,
      ),
      NotificationData(
        icon: 'assets/images/alert.png',
        title: 'Bảo mật',
        type: NotificationType.security,
      ),
    ]);
    */

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
            // Profile avatar trên cùng
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: CircleAvatar(
                radius: 72.5,
                backgroundImage: AssetImage('assets/images/notification_logo.png'),
              ),
            ),

            // Danh sách thông báo
            Expanded(
              child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFB99668),
                    ),
                  )
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
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.notifications_none,
                                  size: 64,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Không có thông báo mới',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFFB99668),
                      backgroundColor: Colors.white,
                      strokeWidth: 3.0,
                      displacement: 40.0,
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
                                // === THÊM MỚI: Navigate to chatbox when tap on message notification ===
                                if (notif.type == NotificationType.message) {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ChatboxScreen(),
                                    ),
                                  );
                                  // Reload notifications sau khi quay lại
                                  _loadNotifications();
                                }
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

enum NotificationType { matching, message, security }

// Model cho dữ liệu thông báo
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
  final VoidCallback? onTap; // === THÊM MỚI: Callback khi tap ===

  const NotificationItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.type,
    this.time,
    this.unreadCount,
    this.onTap, // === THÊM MỚI ===
  });

  @override
  Widget build(BuildContext context) {
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
            // Icon với background
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: type == NotificationType.message
                        ? const Color(0xFFE0CEC0)
                        : null,
                    image: type != NotificationType.message
                        ? DecorationImage(
                      image: AssetImage(icon),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: type == NotificationType.message
                      ? const Icon(Icons.message, color: Colors.white, size: 28)
                      : null,
                ),
                // Badge hiển thị số tin nhắn chưa đọc
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
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        unreadCount! > 99 ? '99+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title với subtitle
                  subtitle != null
                      ? Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: title,
                          style: const TextStyle(
                            color: Color(0xFFEDE2CC),
                            fontSize: 18,
                            fontFamily: 'Alegreya',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
                  )
                      : Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFEDE2CC),
                      fontSize: 18,
                      fontFamily: 'Alegreya',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  // Time
                  if (time != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      time!,
                      style: TextStyle(
                        color: const Color(0xFFEDE2CC).withValues(alpha: 0.7),
                        fontSize: 12,
                        fontFamily: 'Alegreya',
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Arrow icon
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFFEDE2CC),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
