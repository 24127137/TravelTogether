import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../main.dart' show navigatorKey;
import '../screens/chatbox_screen.dart';
import '../screens/ai_chatbot_screen.dart';
import '../screens/notification_screen.dart';
import '../screens/host_member_screen.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

/// Service quản lý Local Notifications
/// Hỗ trợ cả Android và iOS
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final ValueNotifier<bool> showBadgeNotifier = ValueNotifier(false);
  
  factory NotificationService() => _instance;
  
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  final _onMessageStreamController = StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onMessageReceived => _onMessageStreamController.stream;

  // === THÊM MỚI: Hàm xóa chấm đỏ (gọi khi user vào màn hình thông báo) ===
  void clearBadge() {
    showBadgeNotifier.value = false;
  }

  // === THÊM MỚI: Hàm bật chấm đỏ (gọi khi có thông báo mới) ===
  void showBadge() {
    showBadgeNotifier.value = true;
  }

  // === THÊM MỚI: Cập nhật badge dựa trên số lượng notifications ===
  void updateBadge(int notificationCount) {
    showBadgeNotifier.value = notificationCount > 0;
  }

  void dispose() {
    _onMessageStreamController.close();
  }

  /// Khởi tạo notification service
  /// Phải gọi hàm này trước khi sử dụng
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize Local Notifications
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("🔔 FCM received in foreground: ${message.notification?.title}");
      
      // 1. Bắn data vào stream để UI (NotificationScreen) cập nhật ngay lập tức
      _onMessageStreamController.add(message);
      
      // 2. Bật chấm đỏ
      showBadge();

      // 3. Hiện thông báo pop-up (Local Notification)
      // Chỉ hiện nếu có title/body, tránh hiện notification rỗng
      if (message.notification != null) {
        showNotification(
          id: message.hashCode, // Dùng hashcode làm ID tạm
          title: message.notification!.title ?? 'Thông báo mới',
          body: message.notification!.body ?? '',
          payload: jsonEncode(message.data), // Quan trọng: Truyền data payload để navigate
        );
      }
    });

    // === Tạo notification channel với độ ưu tiên cao cho Android ===
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        // Tạo channel cho tin nhắn
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'travel_together_channel',
            'Travel Together Notifications',
            description: 'Thông báo từ Travel Together',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            showBadge: true,
          ),
        );

        // Tạo channel riêng cho group requests
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'group_request_channel',
            'Group Request Notifications',
            description: 'Thông báo yêu cầu tham gia nhóm',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            showBadge: true,
          ),
        );

        debugPrint('✅ Android notification channels created');
      }
    }

    _initialized = true;
    debugPrint('✅ NotificationService initialized');
  }

  /// Xử lý khi user tap vào notification
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Notification tapped: ${response.payload}');

    if (response.payload == null || response.payload!.isEmpty) {
      debugPrint('⚠️ No payload found in notification');
      return;
    }

    // Sử dụng navigatorKey thay vì context để tránh lỗi "No Material widget found"
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      debugPrint('⚠️ Navigator state is null, cannot navigate');
      return;
    }

    // Parse payload để biết loại notification và navigate tới màn hình tương ứng
    try {
      final payload = response.payload!;
      debugPrint('🔍 Processing payload: $payload');

      // Thử parse JSON payload trước
      try {
        final jsonData = jsonDecode(payload);
        final type = jsonData['type'] as String?;

        debugPrint('📋 Notification type: $type');

        if (type == 'group_request') {
          final groupId = jsonData['group_id']?.toString();
          final groupName = jsonData['group_name']?.toString() ?? 'Nhóm';

          debugPrint('🚀 Opening MemberScreenHost for group: $groupId - $groupName');

          // Navigate trực tiếp đến MemberScreenHost với tab pending
          _navigateToMemberScreenHost(navigator, groupId, groupName);
          return;
        } else if (type == 'message') {
          final groupId = jsonData['group_id']?.toString();
          debugPrint('🚀 Navigating to ChatboxScreen with groupId: $groupId');

          // Lưu groupId vào SharedPreferences để ChatboxScreen biết mở nhóm nào
          if (groupId != null) {
            SharedPreferences.getInstance().then((prefs) {
              prefs.setString('cached_group_id', groupId);
            });
          }

          navigator.push(
            MaterialPageRoute(builder: (context) => const ChatboxScreen()),
          );
          return;
        } else if (type == 'ai_chat') {
          navigator.push(
            MaterialPageRoute(builder: (context) => const AiChatbotScreen()),
          );
          return;
        }
      } catch (e) {
        debugPrint('⚠️ Payload is not JSON, trying simple string match');
      }

      // Fallback: xử lý payload đơn giản (string)
      switch (payload) {
        case 'message':
          debugPrint('🚀 Navigating to ChatboxScreen');
          navigator.push(
            MaterialPageRoute(builder: (context) => const ChatboxScreen()),
          );
          break;

        case 'ai_chat':
          debugPrint('🚀 Navigating to AiChatbotScreen');
          navigator.push(
            MaterialPageRoute(builder: (context) => const AiChatbotScreen()),
          );
          break;

        case 'group_request':
          // Fallback: mở NotificationScreen để user tự chọn
          debugPrint('🚀 Navigating to NotificationScreen (fallback)');
          navigator.push(
            MaterialPageRoute(builder: (context) => const NotificationScreen()),
          );
          break;

        default:
          debugPrint('⚠️ Unknown payload type: $payload');
      }
    } catch (e) {
      debugPrint('❌ Error handling notification tap: $e');
    }
  }

  /// Navigate đến MemberScreenHost với thông tin nhóm
  Future<void> _navigateToMemberScreenHost(
    NavigatorState navigator,
    String? groupId,
    String groupName,
  ) async {
    if (groupId == null) {
      debugPrint('⚠️ No groupId, navigating to NotificationScreen');
      navigator.push(
        MaterialPageRoute(builder: (context) => const NotificationScreen()),
      );
      return;
    }

    try {
      // Lấy token
      final token = await AuthService.getValidAccessToken();
      if (token == null) {
        debugPrint('❌ No token, cannot fetch group detail');
        navigator.push(
          MaterialPageRoute(builder: (context) => const NotificationScreen()),
        );
        return;
      }

      // Gọi API lấy chi tiết nhóm
      final url = Uri.parse('${ApiConfig.baseUrl}/groups/$groupId/detail');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        // Parse danh sách thành viên
        final List<dynamic> memberListJson = data['members'] ?? [];
        final List<Member> members = memberListJson.map((m) => Member(
          id: m['profile_uuid'] ?? '',
          name: m['fullname'] ?? 'Thành viên',
          email: m['email'] ?? '',
          avatarUrl: m['avatar_url'],
        )).toList();

        debugPrint('✅ Loaded ${members.length} members, navigating to MemberScreenHost');

        // Navigate đến MemberScreenHost với tab Chờ Duyệt mở sẵn
        navigator.push(
          MaterialPageRoute(
            builder: (context) => MemberScreenHost(
              groupId: groupId,
              groupName: data['name'] ?? groupName,
              currentMembers: members.length,
              maxMembers: data['max_members'] ?? 10,
              members: members,
              openPendingTab: true, // Mở sẵn tab Chờ Duyệt
            ),
          ),
        );
      } else {
        debugPrint('❌ Failed to get group detail: ${response.statusCode}');
        // Fallback to NotificationScreen
        navigator.push(
          MaterialPageRoute(builder: (context) => const NotificationScreen()),
        );
      }
    } catch (e) {
      debugPrint('❌ Error navigating to MemberScreenHost: $e');
      // Fallback to NotificationScreen
      navigator.push(
        MaterialPageRoute(builder: (context) => const NotificationScreen()),
      );
    }
  }

  /// Xin quyền thông báo (chủ yếu cho iOS)
  /// Trả về true nếu được cấp quyền
  Future<bool> requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final granted = await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Android 13+ cần xin quyền thông báo
      final androidImplementation = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidImplementation?.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  /// Kiểm tra quyền thông báo hiện tại
  Future<bool> checkPermission() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final granted = await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImplementation = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidImplementation?.areNotificationsEnabled();
      return granted ?? false;
    }
    return true;
  }

  /// Hiển thị notification ngay lập tức
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationPriority priority = NotificationPriority.high,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    debugPrint('🔔 ===== SHOWING NOTIFICATION =====');
    debugPrint('   Title: $title');
    debugPrint('   Body: $body');
    debugPrint('   Payload: $payload');

    // Kiểm tra permission trước
    final hasPermission = await checkPermission();
    debugPrint('   Permission granted: $hasPermission');

    if (!hasPermission) {
      debugPrint('   ⚠️ Notification permission NOT granted, skipping notification');
      // Vẫn bật badge để user biết có thông báo
      showBadgeNotifier.value = true;
      return;
    }

    // Android notification details
    final androidDetails = AndroidNotificationDetails(
      'travel_together_channel', // channel ID
      'Travel Together Notifications', // channel name
      channelDescription: 'Thông báo từ Travel Together',
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      fullScreenIntent: true, // === THÊM: Hiện trên lock screen ===
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public, // === THÊM: Hiện trên lock screen ===
    );

    // iOS notification details
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive, // === THÊM: Ưu tiên cao ===
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );

    debugPrint('✅ Notification shown successfully with ID: $id');

    debugPrint('📬 Notification sent: $title - $body');
  }

  /// Hiển thị notification tin nhắn mới
  Future<void> showMessageNotification({
    required String groupName,
    required String message,
    required int unreadCount,
    String? groupId, // === THÊM MỚI: ID của nhóm để navigate chính xác ===
  }) async {
    // === THÊM MỚI: Bật chấm đỏ lên khi có tin nhắn ===
    showBadgeNotifier.value = true;
    // Tạo payload JSON để lưu thêm thông tin
    final payloadData = {
      'type': 'message',
      'group_id': groupId,
      'group_name': groupName,
    };

    await showNotification(
      id: 1, // ID cố định cho message notifications
      title: groupName,
      body: unreadCount > 1
          ? '$unreadCount tin nhắn mới'
          : message,
      payload: jsonEncode(payloadData), // === SỬA: Dùng JSON payload ===
      priority: NotificationPriority.high,
    );
  }

  /// Hiển thị notification yêu cầu tham gia nhóm
  Future<void> showGroupRequestNotification({
    required String userName,
    required String groupName,
    String? groupId, // === THÊM MỚI: ID của nhóm ===
  }) async {
    if (!_initialized) {
      await initialize();
    }

    showBadgeNotifier.value = true;

    // Tạo payload JSON
    final payloadData = {
      'type': 'group_request',
      'group_id': groupId,
      'group_name': groupName,
      'user_name': userName,
    };

    // === SỬA: Dùng channel riêng và cấu hình chi tiết hơn ===
    final androidDetails = AndroidNotificationDetails(
      'group_request_channel', // Channel ID riêng
      'Group Request Notifications',
      channelDescription: 'Thông báo yêu cầu tham gia nhóm',
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      fullScreenIntent: true, // Hiện trên lock screen
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Dùng timestamp để tạo unique ID
    final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _notifications.show(
      notificationId,
      'Yêu cầu tham gia nhóm',
      '$userName muốn tham gia nhóm "$groupName"',
      details,
      payload: jsonEncode(payloadData),
    );

    debugPrint('🔔 Group request notification shown with ID: $notificationId');
  }

  /// Hiển thị notification AI chatbot
  Future<void> showAIChatNotification({
    required String message,
  }) async {
    // Tạo payload JSON
    final payloadData = {
      'type': 'ai_chat',
      'message': message,
    };

    await showNotification(
      id: 3,
      title: 'AI Travel Assistant',
      body: message,
      payload: jsonEncode(payloadData), // === SỬA: Dùng JSON payload ===
      priority: NotificationPriority.normal,
    );
  }

  /// Hủy một notification theo ID
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Hủy tất cả notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Lên lịch notification (scheduled)
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    final androidDetails = AndroidNotificationDetails(
      'travel_together_channel',
      'Travel Together Notifications',
      channelDescription: 'Thông báo từ Travel Together',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );

    debugPrint('⏰ Notification scheduled: $title at $scheduledDate');
  }
}

/// Mức độ ưu tiên notification
enum NotificationPriority {
  normal,
  high,
}