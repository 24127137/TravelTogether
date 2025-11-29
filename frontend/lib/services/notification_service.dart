import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'dart:convert'; // === THÊM MỚI: Để parse JSON payload ===

import '../main.dart' show navigatorKey; // === THÊM MỚI: Import global navigator key ===
import '../screens/chatbox_screen.dart'; // === THÊM MỚI: Import màn hình chat ===
import '../screens/ai_chatbot_screen.dart'; // === THÊM MỚI: Import màn hình AI chat ===
import '../screens/notification_screen.dart'; // === THÊM MỚI: Import màn hình notification ===

/// Service quản lý Local Notifications
/// Hỗ trợ cả Android và iOS
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

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

    // Initialize
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
    debugPrint('✅ NotificationService initialized');

    // === LUU Ý: KHÔNG tự động request permission ở đây ===
    // Thay vào đó, app sẽ hiển thị NotificationPermissionDialog (custom UI)
    // để giải thích tại sao cần permission trước khi gọi requestPermission()
    // Xem: widgets/notification_permission_dialog.dart
  }

  /// Xử lý khi user tap vào notification
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Notification tapped: ${response.payload}');

    if (response.payload == null || response.payload!.isEmpty) {
      debugPrint('⚠️ No payload found in notification');
      return;
    }

    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint('⚠️ Navigator context is null, cannot navigate');
      return;
    }

    // Parse payload để biết loại notification và navigate tới màn hình tương ứng
    try {
      final payload = response.payload!;

      debugPrint('🔍 Processing payload: $payload');

      // Xử lý theo loại notification
      switch (payload) {
        case 'message':
          // Navigate tới màn hình chat nhóm
          debugPrint('🚀 Navigating to ChatboxScreen');
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ChatboxScreen(),
            ),
          );
          break;

        case 'ai_chat':
          // Navigate tới màn hình AI chatbot
          debugPrint('🚀 Navigating to AiChatbotScreen');
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AiChatbotScreen(),
            ),
          );
          break;

        case 'group_request':
          // Navigate tới màn hình notifications để xem yêu cầu
          debugPrint('🚀 Navigating to NotificationScreen');
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const NotificationScreen(),
            ),
          );
          break;

        default:
          // Nếu payload có format khác (ví dụ JSON), có thể parse thêm
          debugPrint('⚠️ Unknown payload type: $payload');
          // Thử parse JSON nếu có
          try {
            final jsonData = jsonDecode(payload);
            final type = jsonData['type'] as String?;

            if (type == 'message') {
              final groupId = jsonData['group_id'] as String?;
              debugPrint('🚀 Navigating to ChatboxScreen with groupId: $groupId');
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ChatboxScreen(),
                ),
              );
            } else if (type == 'ai_chat') {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AiChatbotScreen(),
                ),
              );
            } else if (type == 'group_request') {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
            }
          } catch (e) {
            debugPrint('⚠️ Failed to parse JSON payload: $e');
          }
      }
    } catch (e) {
      debugPrint('❌ Error handling notification tap: $e');
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

    // Android notification details
    final androidDetails = AndroidNotificationDetails(
      'travel_together_channel', // channel ID
      'Travel Together Notifications', // channel name
      channelDescription: 'Thông báo từ Travel Together',
      importance: Importance.max,
      priority: priority == NotificationPriority.high ? Priority.high : Priority.defaultPriority,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    // iOS notification details
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
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

    debugPrint('📬 Notification sent: $title - $body');
  }

  /// Hiển thị notification tin nhắn mới
  Future<void> showMessageNotification({
    required String groupName,
    required String message,
    required int unreadCount,
    String? groupId, // === THÊM MỚI: ID của nhóm để navigate chính xác ===
  }) async {
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
    // Tạo payload JSON
    final payloadData = {
      'type': 'group_request',
      'group_id': groupId,
      'group_name': groupName,
      'user_name': userName,
    };

    await showNotification(
      id: 2,
      title: 'Yêu cầu tham gia nhóm',
      body: '$userName muốn tham gia nhóm "$groupName"',
      payload: jsonEncode(payloadData), // === SỬA: Dùng JSON payload ===
      priority: NotificationPriority.high,
    );
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

