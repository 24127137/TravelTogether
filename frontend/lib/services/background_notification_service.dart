import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../config/api_config.dart';
import '../services/notification_service.dart';
import '../screens/chatbox_screen.dart'; // === THÊM MỚI: Import để check isInChatScreen ===

/// Service lắng nghe WebSocket để nhận thông báo real-time
/// Chạy ở background ngay cả khi không mở app
class BackgroundNotificationService {
  static final BackgroundNotificationService _instance = BackgroundNotificationService._internal();
  factory BackgroundNotificationService() => _instance;
  BackgroundNotificationService._internal();

  WebSocketChannel? _channel;
  String? _currentUserId;
  String? _accessToken;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  Timer? _pollingTimer;
  Timer? _keepAliveTimer; // === THÊM: Timer để giữ WebSocket sống ===
  int _lastPendingCount = 0;

  /// Khởi động service - gọi khi login thành công
  Future<void> start() async {
    debugPrint('🚀 ===== STARTING BACKGROUND NOTIFICATION SERVICE =====');

    if (_isConnected) {
      debugPrint('🔌 Background notification service already running');
      return;
    }

    // Load token và user ID
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _currentUserId = prefs.getString('user_id');

    debugPrint('📋 Token: ${_accessToken?.substring(0, 20)}...');
    debugPrint('👤 User ID: $_currentUserId');

    if (_accessToken == null || _currentUserId == null) {
      debugPrint('❌ Cannot start notification service: No token or user ID');
      debugPrint('   Token exists: ${_accessToken != null}');
      debugPrint('   User ID exists: ${_currentUserId != null}');
      return;
    }

    await _connectWebSocket();

    // === THÊM MỚI: Start polling group requests ===
    await _startPollingGroupRequests();
    debugPrint('✅ Group request polling started');
  }

  /// Kết nối WebSocket
  Future<void> _connectWebSocket() async {
    if (_accessToken == null) return;

    try {
      final wsUrl = '${ApiConfig.chatWebSocket}?token=$_accessToken';
      debugPrint('🔌 Connecting background WebSocket...');
      debugPrint('   URL: $wsUrl');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isConnected = true;

      debugPrint('✅ WebSocket channel created, waiting for connection...');

      // === THÊM: Start keepalive ping để giữ kết nối ===
      _startKeepAlive();

      // Lắng nghe tin nhắn
      _channel!.stream.listen(
        (message) {
          debugPrint('📥 ===== WEBSOCKET MESSAGE RECEIVED =====');
          debugPrint('   Raw message: $message');
          _handleWebSocketMessage(message);
        },
        onError: (error) {
          debugPrint('❌ Background WebSocket error: $error');
          _isConnected = false;
          _keepAliveTimer?.cancel();
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('🔌 Background WebSocket connection closed');
          _isConnected = false;
          _keepAliveTimer?.cancel();
          _scheduleReconnect();
        },
      );

      debugPrint('✅ Background notification service started successfully');
      debugPrint('   Listening for messages...');
    } catch (e) {
      debugPrint('❌ Error connecting background WebSocket: $e');
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  /// === THÊM MỚI: Keepalive để giữ WebSocket connection sống ===
  void _startKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 25), (timer) {
      if (_channel != null && _isConnected) {
        try {
          // Gửi ping message để giữ kết nối
          _channel!.sink.add(jsonEncode({'type': 'ping'}));
          debugPrint('🏓 WebSocket keepalive ping sent');
        } catch (e) {
          debugPrint('❌ Keepalive ping failed: $e');
          _isConnected = false;
          _scheduleReconnect();
        }
      }
    });
  }

  /// Xử lý tin nhắn từ WebSocket
  Future<void> _handleWebSocketMessage(dynamic message) async {
    try {
      debugPrint('📬 Processing WebSocket message...');

      final data = jsonDecode(message);
      debugPrint('   Decoded JSON: $data');

      // Bỏ qua error messages
      if (data.containsKey('error')) {
        debugPrint('   ⚠️ Error message, skipping');
        return;
      }

      // Lấy thông tin tin nhắn
      final senderId = data['sender_id']?.toString() ?? '';
      final content = data['content'] ?? '';
      final messageType = data['message_type'] ?? 'text';

      debugPrint('   Sender ID: $senderId');
      debugPrint('   Current User ID: $_currentUserId');
      debugPrint('   Content: $content');
      debugPrint('   Message Type: $messageType');

      // Chỉ gửi notification nếu là tin nhắn từ người khác
      if (senderId.isEmpty || senderId == _currentUserId) {
        debugPrint('   ⏩ Skipping: Message from self or empty sender');
        return; // Tin nhắn của mình, bỏ qua
      }

      debugPrint('   ✅ Message from other user, sending notification...');

      // Load group name
      String groupName = 'Nhóm chat';
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedGroupName = prefs.getString('cached_group_name');
        if (cachedGroupName != null && cachedGroupName.isNotEmpty) {
          groupName = cachedGroupName;
        }
        debugPrint('   Group name: $groupName');
      } catch (e) {
        debugPrint('   ⚠️ Could not load group name: $e');
      }

      // Gửi system notification
      String notificationBody;
      if (messageType == 'image') {
        notificationBody = '📷 Đã gửi một ảnh';
      } else {
        notificationBody = content.length > 50
          ? '${content.substring(0, 50)}...'
          : content;
      }

      debugPrint('   Sending notification:');
      debugPrint('   - Title: $groupName');
      debugPrint('   - Body: $notificationBody');

      // === THÊM MỚI: Kiểm tra xem user có đang ở trong chat screen không ===
      if (ChatboxScreen.isCurrentlyInChatScreen) {
        debugPrint('   🔕 User is in chat screen, skipping notification');
        return;
      }

      await NotificationService().showNotification(
        id: 1, // ID cố định cho message notifications
        title: groupName,
        body: notificationBody,
        payload: 'message',
        priority: NotificationPriority.high,
      );

      debugPrint('   ✅ System notification sent successfully!');
    } catch (e) {
      debugPrint('   ❌ Error handling background WebSocket message: $e');
      debugPrint('   Stack trace: ${StackTrace.current}');
    }
  }

  /// Tự động reconnect sau khi mất kết nối
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      debugPrint('🔄 Attempting to reconnect background WebSocket...');
      _connectWebSocket();
    });
  }

  /// Dừng service - gọi khi logout
  Future<void> stop() async {
    debugPrint('🛑 Stopping background notification service');
    _reconnectTimer?.cancel();
    _pollingTimer?.cancel();
    _keepAliveTimer?.cancel(); // === THÊM: Cancel keepalive timer ===
    await _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _accessToken = null;
    _currentUserId = null;
    _lastPendingCount = 0;
  }

  /// Start polling để kiểm tra group requests mới
  Future<void> _startPollingGroupRequests() async {
    _pollingTimer?.cancel();

    // === QUAN TRỌNG: Check ngay lập tức lần đầu ===
    await _checkNewGroupRequests();
    debugPrint('📋 First group request check completed');

    // Sau đó check định kỳ mỗi 30 giây
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      debugPrint('⏰ Polling group requests...');
      await _checkNewGroupRequests();
    });
  }

  Future<void> _checkNewGroupRequests() async {
    try {
      debugPrint('🔍 Checking for new group requests...');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) {
        debugPrint('❌ No token for polling');
        return;
      }

      // Gọi API lấy danh sách nhóm của host
      final url = Uri.parse('${ApiConfig.baseUrl}/groups/mine');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      debugPrint('📥 Groups response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> groups = jsonDecode(response.body);
        debugPrint('📋 Found ${groups.length} groups');

        int totalPending = 0;
        String? latestGroupName;
        String? latestUserName;

        for (var group in groups) {
          debugPrint('   Group: ${group['name']} - Role: ${group['role']}');

          if (group['role'] == 'host') {
            final groupId = group['group_id'];
            final pendingUrl = Uri.parse('${ApiConfig.baseUrl}/groups/$groupId/requests');
            final pendingRes = await http.get(
              pendingUrl,
              headers: {'Authorization': 'Bearer $token'},
            );

            debugPrint('   Pending requests response: ${pendingRes.statusCode}');

            if (pendingRes.statusCode == 200) {
              final List<dynamic> pending = jsonDecode(pendingRes.body);
              debugPrint('   Found ${pending.length} pending requests for group ${group['name']}');

              totalPending += pending.length;
              if (pending.isNotEmpty) {
                latestGroupName = group['name'];
                // Lấy tên người request mới nhất
                latestUserName = pending.last['fullname'] ?? 'Ai đó';
              }
            }
          }
        }

        debugPrint('📊 Total pending: $totalPending, Last count: $_lastPendingCount');

        // Nếu có request mới hơn lần check trước
        if (totalPending > _lastPendingCount && latestGroupName != null) {
          debugPrint('🔔 NEW REQUEST DETECTED! Sending notification...');

          await NotificationService().showGroupRequestNotification(
            userName: latestUserName ?? 'Có người',
            groupName: latestGroupName,
          );

          debugPrint('✅ Group request notification sent!');
        }

        _lastPendingCount = totalPending;
        debugPrint('📝 Updated lastPendingCount to: $_lastPendingCount');
      }
    } catch (e) {
      debugPrint('❌ Error polling group requests: $e');
    }
  }


  /// Kiểm tra trạng thái kết nối
  bool get isConnected => _isConnected;
}

