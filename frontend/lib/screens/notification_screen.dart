import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../config/api_config.dart';
import '../services/notification_service.dart';
import '../widgets/optimized_list_widget.dart';
import 'chatbox_screen.dart';
import '../screens/host_member_screen.dart';
import '../services/auth_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationData> _notifications = [];
  bool _isLoading = true;

  List<Map<String, dynamic>> _groupRequests = [];
  bool _isLoadingRequests = false;

  @override
  void initState() {
    super.initState();
    // Xóa badge khi vào màn hình thông báo
    NotificationService().clearBadge();
    _loadNotifications();
    _loadGroupRequests();
  }

  Future<void> _handleRefresh() async {
    await _loadNotifications();
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _loadGroupRequests() async {
    setState(() => _isLoadingRequests = true);

    try {
      final token = await AuthService.getValidAccessToken();
      if (token == null) return;

      // Lấy danh sách nhóm của user
      final groupsUrl = ApiConfig.getUri(ApiConfig.myGroup);
      final groupsRes = await http.get(
        groupsUrl,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (groupsRes.statusCode != 200) return;

      final List<dynamic> groups = jsonDecode(groupsRes.body);
      List<Map<String, dynamic>> allRequests = [];

      // Với mỗi nhóm mà user là host, lấy pending requests
      for (var group in groups) {
        if (group['role'] == 'host') {
          final groupId = group['group_id'];
          final groupName = group['name'] ?? 'Nhóm';

          final requestsUrl = ApiConfig.getUri('${ApiConfig.baseUrl}/groups/$groupId/requests');
          final requestsRes = await http.get(
            requestsUrl,
            headers: {'Authorization': 'Bearer $token'},
          );

          if (requestsRes.statusCode == 200) {
            final List<dynamic> pending = jsonDecode(requestsRes.body);

            for (var req in pending) {
              allRequests.add({
                'type': 'group_request',
                'group_id': groupId,
                'group_name': groupName,
                'user_name': req['fullname'] ?? 'Người dùng',
                'email': req['email'],
                'avatar_url': req['avatar_url'],
                'requested_at': req['requested_at'],
                'profile_uuid': req['profile_uuid'],
              });
            }
          }
        }
      }

      setState(() {
        _groupRequests = allRequests;
        _isLoadingRequests = false;
      });
    } catch (e) {
      print('❌ Error loading group requests: $e');
      setState(() => _isLoadingRequests = false);
    }
  }

  /// Xử lý khi tap vào thông báo yêu cầu tham gia nhóm
  /// [notif] chứa payloadId là group_id của nhóm có người xin vào
  Future<void> _handleGroupRequestTap(NotificationData notif) async {
    // Logic: Lấy ID nhóm từ thông báo -> Gọi API chi tiết nhóm -> Mở màn hình duyệt
    if (notif.payloadId == null) return;

    final groupId = notif.payloadId!;

    // Xóa ngay khỏi list để UI mượt
    setState(() {
      _notifications.remove(notif);
    });

    // Hiện loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: Color(0xFFB99668))),
    );

    try {
      final token = await AuthService.getValidAccessToken();
      if (token == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      // Gọi API lấy chi tiết nhóm để có danh sách thành viên hiện tại
      final url = Uri.parse('${ApiConfig.baseUrl}/groups/$groupId/detail');
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (!mounted) return;
      Navigator.pop(context); // Tắt loading

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        // Parse danh sách thành viên
        final List<dynamic> memberListJson = data['members'] ?? [];
        final List<Member> members = memberListJson.map((m) => Member(
          id: m['profile_uuid'] ?? '',
          name: m['fullname'] ?? 'member_default'.tr(),
          email: m['email'] ?? '',
          avatarUrl: m['avatar_url'],
        )).toList();

        // Chuyển trang
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MemberScreenHost(
              groupId: groupId,
              groupName: data['name'] ?? 'Nhóm',
              currentMembers: members.length,
              maxMembers: data['max_members'] ?? 10,
              members: members,
              openPendingTab: true, // <--- Mở sẵn tab Chờ Duyệt
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${'load_group_error'.tr()}: ${response.statusCode}'))
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      print('Error: $e');
    }
  }

  /// Xử lý khi tap vào thông báo tin nhắn
  Future<void> _handleMessageTap(NotificationData notif) async {
    final prefs = await SharedPreferences.getInstance();

    // Lưu group_id để ChatboxScreen biết mở nhóm nào
    if (notif.payloadId != null) {
      await prefs.setString('cached_group_id', notif.payloadId!);
    }

    // Xóa thông báo khỏi list
    setState(() {
      _notifications.remove(notif);
    });

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ChatboxScreen()),
      );
    }
  }

  // === [MỚI] LOGIC KIỂM TRA NHÓM BỊ GIẢI TÁN ===
  // Logic: So sánh danh sách nhóm vừa tải về với danh sách đã lưu lần trước (Cache).
  // Nếu có ID nào nằm trong Cache mà KHÔNG có trong danh sách mới -> Nhóm đó đã giải tán.
  // === 1. HÀM CHECK NHÓM BỊ MẤT (Bao gồm: Giải tán + Bị Kick) ===
  Future<List<NotificationData>> _checkDisbandedGroups(
      List<dynamic> currentGroups, SharedPreferences prefs) async {

    List<NotificationData> notifs = [];

    List<String> cachedIds = prefs.getStringList('joined_group_ids_cache') ?? [];
    List<String> cachedNames = prefs.getStringList('joined_group_names_cache') ?? [];

    Set<String> currentIds = {};
    for (var g in currentGroups) {
      currentIds.add((g['id'] ?? g['group_id']).toString());
    }

    for (int i = 0; i < cachedIds.length; i++) {
      if (!currentIds.contains(cachedIds[i])) {
        String oldName = (i < cachedNames.length) ? cachedNames[i] : 'Nhóm cũ';

        // ==> SỬA LẠI CÂU THÔNG BÁO CHO HỢP LÝ CẢ 2 TRƯỜNG HỢP <==
        notifs.add(NotificationData(
          icon: 'assets/images/notification_logo.png',
          title: 'left_group'.tr(),
          subtitle: '${'left_group_desc'.tr()} "$oldName" ${'group_disbanded_or_kicked'.tr()}',
          type: NotificationType.security,
          time: 'recently'.tr(),
          unreadCount: 1,
          payloadId: null,
        ));
      }
    }

    // Update Cache
    List<String> newIds = [];
    List<String> newNames = [];
    for (var g in currentGroups) {
      newIds.add((g['id'] ?? g['group_id']).toString());
      newNames.add(g['name']?.toString() ?? 'Nhóm');
    }
    await prefs.setStringList('joined_group_ids_cache', newIds);
    await prefs.setStringList('joined_group_names_cache', newNames);

    return notifs;
  }

  // === 2. HÀM CHECK ĐƠN BỊ TỪ CHỐI (REJECTED) ===
  Future<List<NotificationData>> _checkRejectedRequests(
      List<dynamic> currentPendingRequests,
      List<dynamic> currentJoinedGroups, // Cần danh sách nhóm đã vào để phân biệt với được duyệt
      SharedPreferences prefs) async {

    List<NotificationData> notifs = [];

    // Lấy danh sách ID các nhóm mình ĐÃ xin vào lần trước
    List<String> cachedPendingIds = prefs.getStringList('pending_req_ids_cache') ?? [];
    List<String> cachedPendingNames = prefs.getStringList('pending_req_names_cache') ?? [];

    // Tạo Set các ID request hiện tại
    Set<String> currentPendingIds = {};
    for (var req in currentPendingRequests) {
      // API /users/me trả về pending_requests có field 'group_id'
      currentPendingIds.add((req['group_id']).toString());
    }

    // Tạo Set các ID nhóm đã tham gia (để check trường hợp được Duyệt)
    Set<String> joinedGroupIds = {};
    for (var g in currentJoinedGroups) {
      joinedGroupIds.add((g['id'] ?? g['group_id']).toString());
    }

    // SO SÁNH
    for (int i = 0; i < cachedPendingIds.length; i++) {
      String oldGroupId = cachedPendingIds[i];

      // Nếu đơn cũ biến mất khỏi danh sách chờ...
      if (!currentPendingIds.contains(oldGroupId)) {
        // ...Và CŨNG KHÔNG xuất hiện trong danh sách đã tham gia
        // ==> CHÍNH LÀ BỊ TỪ CHỐI (REJECT)
        if (!joinedGroupIds.contains(oldGroupId)) {
          String groupName = (i < cachedPendingNames.length) ? cachedPendingNames[i] : 'Nhóm';

          notifs.add(NotificationData(
            icon: 'assets/images/notification_logo.png', // Hoặc icon dấu X đỏ
            title: 'request_rejected'.tr(),
            subtitle: '${'request_rejected_desc'.tr()} "$groupName".',
            type: NotificationType.security,
            time: 'just_now'.tr(),
            unreadCount: 1,
            payloadId: null,
          ));
        }
      }
    }

    // Update Cache Pending
    List<String> newIds = [];
    List<String> newNames = [];
    for (var req in currentPendingRequests) {
      newIds.add((req['group_id']).toString());
      newNames.add(req['group_name']?.toString() ?? req['name']?.toString() ?? 'Nhóm');
    }
    await prefs.setStringList('pending_req_ids_cache', newIds);
    await prefs.setStringList('pending_req_names_cache', newNames);

    return notifs;
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('user_id');
    final accessToken = await AuthService.getValidAccessToken();

    if (accessToken == null) {
      setState(() => _isLoading = false);
      return;
    }

    List<NotificationData> finalNotifications = [];

    // Biến lưu danh sách nhóm đã tham gia (Dùng để check Chat & check Từ chối)
    List<dynamic> myJoinedGroups = [];

    // --- BƯỚC A: LẤY DANH SÁCH NHÓM CỦA TÔI (/groups/mine) ---
    // Mục đích: Check Chat, Check Bị Kick/Giải tán, Lấy dữ liệu để đối chiếu đơn từ chối
    try {
      final groupsResponse = await http.get(
        ApiConfig.getUri(ApiConfig.myGroup),
        headers: {"Authorization": "Bearer $accessToken"},
      );

      if (groupsResponse.statusCode == 200) {
        myJoinedGroups = jsonDecode(utf8.decode(groupsResponse.bodyBytes));

        // 1. Logic Check Bị Kick / Giải tán (So sánh với Cache cũ)
        final disbandedNotifs = await _checkDisbandedGroups(myJoinedGroups, prefs);
        finalNotifications.addAll(disbandedNotifs);

        // 2. Logic Check Chat (Vòng lặp)
        for (var group in myJoinedGroups) {
          final String groupId = (group['id'] ?? group['group_id']).toString();
          final String groupName = group['name']?.toString() ?? 'Nhóm chat';

          // Cache lại thông tin nhóm
          await prefs.setString('cached_group_id', groupId);
          await prefs.setString('cached_group_name', groupName);

          try {
            final historyResponse = await http.get(
              Uri.parse('${ApiConfig.baseUrl}/chat/$groupId/history'),
              headers: {"Authorization": "Bearer $accessToken"},
            );

            if (historyResponse.statusCode == 200) {
              final List<dynamic> messages = jsonDecode(utf8.decode(historyResponse.bodyBytes));
              final lastSeenId = prefs.getString('last_seen_message_id_$groupId');

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
              String? lastMessageTime;

              for (int i = lastSeenIndex + 1; i < messages.length; i++) {
                final msg = messages[i];
                final senderId = msg['sender_id']?.toString();
                if (senderId == currentUserId) continue;

                unreadCount++;
                final time = DateTime.parse(msg['created_at']).toLocal();
                lastMessageTime = _formatTime(time);
              }

              if (unreadCount > 0) {
                finalNotifications.add(NotificationData(
                  icon: 'assets/images/message.jpg',
                  title: groupName,
                  subtitle: unreadCount > 1 ? ' • $unreadCount tin nhắn mới' : ' • 1 tin nhắn mới',
                  type: NotificationType.message,
                  time: lastMessageTime,
                  unreadCount: unreadCount,
                  payloadId: groupId,
                ));
              }
            }
          } catch (e) {
            print('Lỗi chat group $groupId: $e');
          }
        }
      }
    } catch (e) {
      print('Lỗi phần Groups: $e');
    }

    // --- BƯỚC B: LẤY PROFILE CỦA TÔI (/users/me) ---
    // Mục đích: Host check đơn xin vào (owned_groups), Member check đơn bị từ chối (pending_requests)
    try {
      final profileUrl = Uri.parse('${ApiConfig.baseUrl}/users/me');
      final profileResponse = await http.get(
        profileUrl,
        headers: {"Authorization": "Bearer $accessToken"},
      );

      if (profileResponse.statusCode == 200) {
        final profileData = jsonDecode(utf8.decode(profileResponse.bodyBytes));

        // 3. Logic Host check Request (Dựa trên owned_groups)
        final List<dynamic> ownedGroups = profileData['owned_groups'] ?? [];

        for (var group in ownedGroups) {
          final groupId = group['group_id'] ?? group['id'];
          final groupName = group['name'] ?? 'Nhóm của tôi';

          if (groupId != null) {
            final requestUrl = Uri.parse('${ApiConfig.baseUrl}/groups/$groupId/requests');
            final requestResponse = await http.get(
              requestUrl,
              headers: {"Authorization": "Bearer $accessToken"},
            );

            if (requestResponse.statusCode == 200) {
              final List<dynamic> requests = jsonDecode(utf8.decode(requestResponse.bodyBytes));

              if (requests.isNotEmpty) {
                finalNotifications.add(NotificationData(
                  icon: 'assets/images/add_user_icon.jpg',
                  title: 'join_group'.tr(),
                  subtitle: '${'group_members'.tr()}: ${requests.length} ${'send_request'.tr()} "$groupName"',
                  type: NotificationType.groupRequest,
                  time: 'just_now'.tr(),
                  unreadCount: requests.length,
                  payloadId: groupId.toString(),
                ));
              }
            }
          }
        }

        // 4. Logic Check Đơn bị Từ chối (Rejected)
        // Check pending_requests xem có cái nào biến mất mà không nằm trong myJoinedGroups
        final List<dynamic> myPendingRequests = profileData['pending_requests'] ?? [];

        final rejectedNotifs = await _checkRejectedRequests(
            myPendingRequests,
            myJoinedGroups,
            prefs
        );
        finalNotifications.addAll(rejectedNotifs);
      }
    } catch (e) {
      print('Lỗi phần Profile: $e');
    }

    if (mounted) {
      setState(() {
        _notifications = finalNotifications;
        _isLoading = false;
      });

      // === THÊM MỚI: Cập nhật badge dựa trên số thông báo ===
      // Lưu ý: Không clear badge ở đây vì initState đã clear rồi
      // Chỉ cập nhật để các màn hình khác biết có thông báo hay không
      if (finalNotifications.isNotEmpty) {
        // Nếu đang ở màn hình notification thì không cần hiện badge
        // Nhưng cần lưu lại state để khi chuyển sang tab khác thì badge sẽ hiện
        // Logic này được xử lý trong custom_bottom_nav_bar.dart
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'just_now'.tr();
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${'minutes_ago'.tr()}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${'hours_ago'.tr()}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${'days_ago'.tr()}';
    } else {
      return DateFormat('d/M/yyyy').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
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
                backgroundImage: const AssetImage('assets/images/notification_logo.png'),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 6,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => const NotificationSkeletonItem(),
                      ),
                    )
                  : _notifications.isEmpty
                  ? RefreshIndicator(
                color: const Color(0xFFB99668),
                onRefresh: _handleRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: Center(
                      child: Text(
                        '${'no_notifications'.tr()}\n${'pull_to_refresh'.tr()}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontFamily: 'Alegreya',
                        ),
                      ),
                    ),
                  ),
                ),
              )
                  : RefreshIndicator(
                color: const Color(0xFFB99668),
                onRefresh: _handleRefresh,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: ListView.separated(
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];
                      return NotificationItem(
                        icon: notif.icon,
                        title: notif.title,
                        subtitle: notif.subtitle,
                        type: notif.type,
                        time: notif.time,
                        unreadCount: notif.unreadCount,
                        onTap: () {
                          // Xử lý theo loại thông báo
                          switch (notif.type) {
                            case NotificationType.groupRequest:
                              _handleGroupRequestTap(notif);
                              break;
                            case NotificationType.message:
                              _handleMessageTap(notif);
                              break;
                            default:
                              setState(() {
                                _notifications.remove(notif);
                              });
                              break;
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
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getIconBackgroundColor(),
                  ),
                  child: _buildIcon(),
                ),
                if (unreadCount != null && unreadCount! > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: type == NotificationType.groupRequest
                            ? Colors.orange
                            : Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFB99668), width: 2),
                      ),
                      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Alumni Sans',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: Color(0xFFEDE2CC),
                        fontSize: 14,
                        fontFamily: 'Alegreya',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (time != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      time!,
                      style: const TextStyle(
                        color: Color(0xFFEDE2CC),
                        fontSize: 12,
                        fontFamily: 'Alegreya',
                      ),
                    ),
                  ],
                ],
              ),
            ),
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

  Color _getIconBackgroundColor() {
    switch (type) {
      case NotificationType.message:
        return const Color(0xFFE0CEC0);
      case NotificationType.groupRequest:
        return const Color(0xFFFFE0B2); // Màu cam nhạt cho group request
      default:
        return const Color(0xFFE0CEC0);
    }
  }

  Widget _buildIcon() {
    switch (type) {
      case NotificationType.message:
        return const Icon(Icons.message, color: Colors.white, size: 28);
      case NotificationType.groupRequest:
        return const Icon(Icons.group_add, color: Colors.orange, size: 28);
      default:
        return Image.asset(icon, fit: BoxFit.cover);
    }
  }
}

/// Skeleton loading item cho danh sách notification
class NotificationSkeletonItem extends StatefulWidget {
  const NotificationSkeletonItem({Key? key}) : super(key: key);

  @override
  State<NotificationSkeletonItem> createState() => _NotificationSkeletonItemState();
}

class _NotificationSkeletonItemState extends State<NotificationSkeletonItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFB99668).withOpacity(0.5),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Row(
            children: [
              // Avatar skeleton
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: const [
                      Color(0xFFD9CBB3),
                      Color(0xFFF5EFE7),
                      Color(0xFFD9CBB3),
                    ],
                    stops: [
                      (_animation.value - 0.3).clamp(0.0, 1.0),
                      _animation.value.clamp(0.0, 1.0),
                      (_animation.value + 0.3).clamp(0.0, 1.0),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title skeleton
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: const [
                            Color(0xFFD9CBB3),
                            Color(0xFFF5EFE7),
                            Color(0xFFD9CBB3),
                          ],
                          stops: [
                            (_animation.value - 0.3).clamp(0.0, 1.0),
                            _animation.value.clamp(0.0, 1.0),
                            (_animation.value + 0.3).clamp(0.0, 1.0),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Subtitle skeleton
                    Container(
                      width: double.infinity,
                      height: 14,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: const [
                            Color(0xFFD9CBB3),
                            Color(0xFFF5EFE7),
                            Color(0xFFD9CBB3),
                          ],
                          stops: [
                            (_animation.value - 0.3).clamp(0.0, 1.0),
                            _animation.value.clamp(0.0, 1.0),
                            (_animation.value + 0.3).clamp(0.0, 1.0),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Time skeleton
                    Container(
                      width: 60,
                      height: 12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: const [
                            Color(0xFFD9CBB3),
                            Color(0xFFF5EFE7),
                            Color(0xFFD9CBB3),
                          ],
                          stops: [
                            (_animation.value - 0.3).clamp(0.0, 1.0),
                            _animation.value.clamp(0.0, 1.0),
                            (_animation.value + 0.3).clamp(0.0, 1.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow skeleton
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: const [
                      Color(0xFFD9CBB3),
                      Color(0xFFF5EFE7),
                      Color(0xFFD9CBB3),
                    ],
                    stops: [
                      (_animation.value - 0.3).clamp(0.0, 1.0),
                      _animation.value.clamp(0.0, 1.0),
                      (_animation.value + 0.3).clamp(0.0, 1.0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
