import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../config/api_config.dart';
import '../services/notification_service.dart'; // === THÊM MỚI: Import notification service ===
import 'chatbox_screen.dart'; // === THÊM MỚI: Import chatbox screen ===
import '../screens/host_member_screen.dart';
import '../services/auth_service.dart'; 

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
  String? _groupId;

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
    final currentUserId = prefs.getString('user_id');
    
    // Luôn lấy token tươi nhất (tự động refresh nếu hết hạn)
    final accessToken = await AuthService.getValidAccessToken();
    if (accessToken == null) {
      setState(() => _isLoading = false);
      return;
    }

    List<NotificationData> notifications = [];

    // === 1. LẤY DANH SÁCH GROUP + PLAN + UNREAD MESSAGES CHO TỪNG GROUP ===
    try {
      final groupsResponse = await http.get(
        ApiConfig.getUri(ApiConfig.myGroup), // GET /groups/mine
        headers: {"Authorization": "Bearer $accessToken"},
      );

      if (groupsResponse.statusCode != 200) throw Exception("Không tải được groups");

      final List<dynamic> groups = jsonDecode(utf8.decode(groupsResponse.bodyBytes));
      
      for (var group in groups) {
        final String groupId = group['id'].toString();
        final String groupName = group['name']?.toString() ?? 'Nhóm chat';
        final String? groupImageUrl = group['group_image_url']?.toString();

        // Cache group mới nhất (cho background notification & mở chat nhanh)
        await prefs.setString('cached_group_id', groupId);
        await prefs.setString('cached_group_name', groupName);

        // === Lấy lịch sử tin nhắn của riêng group này ===
        try {
          final historyResponse = await http.get(
            Uri.parse('${ApiConfig.baseUrl}/chat/$groupId/history'),
            headers: {"Authorization": "Bearer $accessToken"},
          );

          if (historyResponse.statusCode == 200) {
            final List<dynamic> messages = jsonDecode(utf8.decode(historyResponse.bodyBytes));

            final lastSeenId = prefs.getString('last_seen_message_id_$groupId'); // riêng từng group
            int lastSeenIndex = -1;

            if (lastSeenId != null) {
              for (int i = 0; i < messages.length; i++) {
                if (messages[i]['id'].toString() == lastSeenId) {
                  lastSeenIndex = i;
                  break;
                }
              }
            }

            int unreadCount = 0;
            String? lastMessageContent;
            String? lastMessageTime;

            for (int i = lastSeenIndex + 1; i < messages.length; i++) {
              final msg = messages[i];
              final senderId = msg['sender_id']?.toString();

              if (senderId == currentUserId) continue; // bỏ qua tin của mình

              unreadCount++;
              lastMessageContent = msg['content']?.toString() ?? 'Đã gửi một ảnh';
              final time = DateTime.parse(msg['created_at']).toLocal();
              lastMessageTime = _formatTime(time);
            }

            if (unreadCount > 0) {
              notifications.add(NotificationData(
                icon: 'assets/images/message.jpg',
                title: groupName,
                subtitle: unreadCount > 1 ? ' • $unreadCount tin nhắn mới' : ' • 1 tin nhắn mới',
                type: NotificationType.message,
                time: lastMessageTime,
                unreadCount: unreadCount,
                payloadId: groupId, // để khi tap thì mở đúng group
              ));

              // Gửi system notification (chỉ gửi cho group có tin mới)
              await NotificationService().showMessageNotification(
                groupName: groupName,
                message: lastMessageContent ?? '',
                unreadCount: unreadCount,
                groupId: groupId,
              );
            }
          }
        } catch (e) {
          print('Lỗi load history group $groupId: $e');
        }

        // === LẤY YÊU CẦU THAM GIA NHÓM (chỉ owner mới thấy) ===
        if (group['role']?.toString().toLowerCase() == 'owner') {
          try {
            final reqResponse = await http.get(
              Uri.parse('${ApiConfig.baseUrl}/groups/$groupId/requests'),
              headers: {"Authorization": "Bearer $accessToken"},
            );

            if (reqResponse.statusCode == 200) {
              final List<dynamic> requests = jsonDecode(utf8.decode(reqResponse.bodyBytes));
              if (requests.isNotEmpty) {
                notifications.add(NotificationData(
                  icon: 'assets/images/add_user_icon.jpg',
                  title: 'Yêu cầu tham gia nhóm',
                  subtitle: 'Có ${requests.length} người muốn vào "$groupName"',
                  type: NotificationType.groupRequest,
                  time: 'Vừa xong',
                  unreadCount: requests.length,
                  payloadId: groupId,
                ));
              }
            }
          } catch (e) {
            print('Lỗi load requests group $groupId: $e');
          }
        }
      }
    } catch (e) {
      print('Lỗi tải danh sách group: $e');
    }

    // Nếu không có thông báo nào → hiện mock nhẹ hoặc để trống
    if (notifications.isEmpty) {
      // Có thể thêm thông báo kiểu "Mọi thứ yên bình" ở đây nếu muốn
    }

    setState(() {
      _notifications = notifications;
      _isLoading = false;
    });
  }

  Future<void> _handleGroupRequestTap() async {
    if (_groupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy thông tin nhóm')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: Color(0xFFB99668))),
    );

    try {
      final token = _accessToken ?? await AuthService.getValidAccessToken();
      if (token == null) throw Exception("No token");

      final url = Uri.parse('${ApiConfig.baseUrl}/groups/$_groupId/detail'); // hoặc /my-group nếu cần
      final response = await http.get(url, headers: {"Authorization": "Bearer $token"});

      Navigator.of(context).pop(); // tắt loading

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        final List<dynamic> memberListJson = data['members'] ?? [];
        final List<Member> members = memberListJson.map((m) => Member(
          id: m['profile_uuid'] ?? '',
          name: m['fullname'] ?? 'Thành viên',
          email: m['email'] ?? '',
          avatarUrl: m['avatar_url'],
        )).toList();

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MemberScreenHost(
                groupId: _groupId!,
                groupName: data['name'] ?? 'Nhóm của tôi',
                currentMembers: members.length,
                maxMembers: data['max_members'] ?? 10,
                members: members,
                openPendingTab: true, // ← Mở thẳng tab "Yêu cầu tham gia"
              ),
            ),
          );
        }
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
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
                          setState(() {
                            _notifications.remove(notif);
                          });
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
                          } else if (notif.type == NotificationType.groupRequest) {
                            // === GỌI HÀM MỚI ===
                            await _handleGroupRequestTap();
                            // _loadNotifications(); // Reload sau khi quay lại
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

enum NotificationType { matching, message, security, groupRequest }
// Model cho dữ liệu thông báo
class NotificationData {
  final String icon;
  final String title;
  final String? subtitle;
  final NotificationType type;
  final String? time;
  final int? unreadCount;
  final String? payloadId;

  NotificationData({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.type,
    this.time,
    this.unreadCount,
    this.payloadId,
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