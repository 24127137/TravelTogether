import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../config/api_config.dart';
import '../services/notification_service.dart';
import '../screens/chatbox_screen.dart';

/// Service lắng nghe WebSocket và polling để nhận thông báo real-time
/// Chạy ở background ngay cả khi không mở app
class BackgroundNotificationService {
  static final BackgroundNotificationService _instance = BackgroundNotificationService._internal();
  factory BackgroundNotificationService() => _instance;
  BackgroundNotificationService._internal();

  // WebSocket connections cho từng group
  final Map<String, WebSocketChannel> _groupChannels = {};

  String? _currentUserId;
  String? _accessToken;
  bool _isRunning = false;

  Timer? _pollingTimer;
  Timer? _messagePollingTimer; // Polling tin nhắn mới

  int _lastPendingCount = 0;

  // Lưu last message ID cho từng group để check tin nhắn mới
  final Map<String, String> _lastMessageIds = {};

  // Cache tên user theo UUID
  final Map<String, String> _userNames = {};

  /// Khởi động service - gọi khi login thành công
  Future<void> start() async {
    debugPrint('🚀 ===== STARTING BACKGROUND NOTIFICATION SERVICE =====');

    if (_isRunning) {
      debugPrint('🔌 Background notification service already running');
      return;
    }

    // Load token và user ID
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _currentUserId = prefs.getString('user_id');

    debugPrint('📋 Token exists: ${_accessToken != null}');
    debugPrint('👤 User ID: $_currentUserId');

    if (_accessToken == null || _currentUserId == null) {
      debugPrint('❌ Cannot start notification service: No token or user ID');
      return;
    }

    _isRunning = true;

    // Lấy danh sách group và kết nối WebSocket cho mỗi group
    await _connectToAllGroups();

    // Start polling group requests (mỗi 30 giây)
    await _startPollingGroupRequests();

    // Start polling tin nhắn mới (mỗi 10 giây) - Backup khi WebSocket fail
    await _startPollingNewMessages();

    debugPrint('✅ Background notification service started successfully');
  }

  /// Kết nối WebSocket tới tất cả các nhóm user đang tham gia
  Future<void> _connectToAllGroups() async {
    if (_accessToken == null) return;

    try {
      debugPrint('🔌 Fetching groups to connect WebSocket...');

      final url = Uri.parse('${ApiConfig.baseUrl}/groups/mine');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> groups = jsonDecode(response.body);
        debugPrint('📋 Found ${groups.length} groups to connect');

        for (var group in groups) {
          final groupId = (group['group_id'] ?? group['id'])?.toString();
          final groupName = group['name']?.toString() ?? 'Nhóm chat';

          if (groupId == null) continue;

          // Gọi API detail để lấy members (giống chatbox_screen.dart)
          try {
            final detailUrl = Uri.parse('${ApiConfig.baseUrl}/groups/$groupId/detail');
            final detailRes = await http.get(
              detailUrl,
              headers: {'Authorization': 'Bearer $_accessToken'},
            );

            if (detailRes.statusCode == 200) {
              final detailData = jsonDecode(utf8.decode(detailRes.bodyBytes));
              final members = detailData['members'] as List<dynamic>? ?? [];

              // Cache tên members giống chatbox_screen.dart
              for (var member in members) {
                final uuid = member['profile_uuid']?.toString();
                final fullname = member['fullname']?.toString();
                if (uuid != null && uuid.isNotEmpty && fullname != null && fullname.isNotEmpty) {
                  _userNames[uuid] = fullname;
                  debugPrint('   📝 Cached: $uuid -> $fullname');
                }
              }
            }
          } catch (e) {
            debugPrint('⚠️ Error fetching group detail for $groupId: $e');
          }

          await _connectToGroup(groupId, groupName);
        }

        debugPrint('📋 Cached ${_userNames.length} user names');
      }
    } catch (e) {
      debugPrint('❌ Error fetching groups: $e');
    }
  }

  /// Kết nối WebSocket tới một group cụ thể
  Future<void> _connectToGroup(String groupId, String groupName) async {
    // Đóng connection cũ nếu có
    if (_groupChannels.containsKey(groupId)) {
      try {
        await _groupChannels[groupId]?.sink.close();
      } catch (_) {}
    }

    try {
      final wsUrl = ApiConfig.chatWebSocketByGroup(groupId);
      debugPrint('🔌 Connecting WebSocket to group $groupId: $wsUrl');

      // Sử dụng IOWebSocketChannel để gửi headers (giống chatbox_screen.dart)
      final channel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      _groupChannels[groupId] = channel;

      // Lắng nghe tin nhắn từ group này
      channel.stream.listen(
        (message) {
          debugPrint('📥 WebSocket message from group $groupId');
          _handleWebSocketMessage(message, groupId, groupName);
        },
        onError: (error) {
          debugPrint('❌ WebSocket error for group $groupId: $error');
          _groupChannels.remove(groupId);
          // Reconnect sau 5 giây
          Future.delayed(const Duration(seconds: 5), () {
            if (_isRunning) {
              _connectToGroup(groupId, groupName);
            }
          });
        },
        onDone: () {
          debugPrint('🔌 WebSocket closed for group $groupId');
          _groupChannels.remove(groupId);
          // Reconnect sau 5 giây
          Future.delayed(const Duration(seconds: 5), () {
            if (_isRunning) {
              _connectToGroup(groupId, groupName);
            }
          });
        },
      );

      debugPrint('✅ WebSocket connected to group $groupId ($groupName)');
    } catch (e) {
      debugPrint('❌ Error connecting WebSocket to group $groupId: $e');
    }
  }

  /// Xử lý tin nhắn từ WebSocket
  Future<void> _handleWebSocketMessage(dynamic message, String groupId, String groupName) async {
    try {
      final data = jsonDecode(message);

      // Bỏ qua error messages
      if (data.containsKey('error')) {
        debugPrint('   ⚠️ Error message from WebSocket, skipping');
        return;
      }

      final senderId = data['sender_id']?.toString() ?? '';
      // Lấy sender_name từ API, nếu không có thì lấy từ cache _userNames
      final senderName = data['sender_name']?.toString() ?? _userNames[senderId] ?? 'Ai đó';
      final content = data['content'] ?? '';
      final messageType = data['message_type'] ?? 'text';
      final messageId = data['id']?.toString();

      debugPrint('📨 Message from: $senderName (ID: $senderId)');

      // Bỏ qua tin nhắn của chính mình
      if (senderId.isEmpty || senderId == _currentUserId) {
        return;
      }

      // Kiểm tra xem user có đang ở trong chat screen không
      if (ChatboxScreen.isCurrentlyInChatScreen) {
        debugPrint('   🔕 User is in chat screen, skipping notification');
        return;
      }

      // Cập nhật last message ID
      if (messageId != null) {
        _lastMessageIds[groupId] = messageId;
      }

      // Gửi notification với tên người gửi
      await _sendMessageNotification(groupName, senderName, content, messageType);
    } catch (e) {
      debugPrint('❌ Error handling WebSocket message: $e');
    }
  }

  /// Gửi notification cho tin nhắn mới (hiển thị tên người gửi như Messenger)
  Future<void> _sendMessageNotification(String groupName, String senderName, String content, String messageType) async {
    // Format body như Messenger: "Tên người: nội dung"
    String notificationBody;

    if (messageType == 'multi') {
      // Nhiều tin nhắn mới
      notificationBody = content;
    } else if (messageType == 'image') {
      notificationBody = '$senderName: 📷 Đã gửi một ảnh';
    } else {
      final truncatedContent = content.length > 40
        ? '${content.substring(0, 40)}...'
        : content;
      notificationBody = '$senderName: $truncatedContent';
    }

    debugPrint('🔔 Sending message notification: $groupName - $notificationBody');

    // Bật badge
    NotificationService().showBadge();

    await NotificationService().showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000, // ID unique
      title: groupName,
      body: notificationBody,
      payload: 'message',
      priority: NotificationPriority.high,
    );
  }

  /// Polling tin nhắn mới - Backup khi WebSocket không hoạt động
  Future<void> _startPollingNewMessages() async {
    _messagePollingTimer?.cancel();

    // Check ngay lần đầu
    await _checkNewMessages();

    // Sau đó check định kỳ mỗi 10 giây
    _messagePollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (_isRunning) {
        await _checkNewMessages();
      }
    });

    debugPrint('✅ Message polling started (every 10 seconds)');
  }

  /// Kiểm tra tin nhắn mới từ tất cả các nhóm
  Future<void> _checkNewMessages() async {
    if (_accessToken == null || _currentUserId == null) return;

    // Bỏ qua nếu đang ở trong chat screen
    if (ChatboxScreen.isCurrentlyInChatScreen) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      // Lấy danh sách nhóm
      final url = Uri.parse('${ApiConfig.baseUrl}/groups/mine');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode != 200) return;

      final List<dynamic> groups = jsonDecode(response.body);

      for (var group in groups) {
        final groupId = (group['group_id'] ?? group['id'])?.toString();
        final groupName = group['name']?.toString() ?? 'Nhóm chat';

        if (groupId == null) continue;

        try {
          // Lấy lịch sử chat của group
          final historyUrl = Uri.parse('${ApiConfig.baseUrl}/chat/$groupId/history');
          final historyRes = await http.get(
            historyUrl,
            headers: {'Authorization': 'Bearer $_accessToken'},
          );

          if (historyRes.statusCode != 200) continue;

          final List<dynamic> messages = jsonDecode(utf8.decode(historyRes.bodyBytes));
          if (messages.isEmpty) continue;

          // Lấy last seen ID từ SharedPreferences
          final lastSeenId = prefs.getString('last_seen_message_id_$groupId');

          // Nếu chưa có lastPolledId, khởi tạo từ lastSeenId hoặc tin nhắn cuối cùng
          if (!_lastMessageIds.containsKey(groupId)) {
            if (lastSeenId != null) {
              _lastMessageIds[groupId] = lastSeenId;
              debugPrint('📝 Initialized lastPolledId for group $groupId from lastSeenId: $lastSeenId');
            } else {
              // Lần đầu, lấy tin nhắn cuối để không spam notification
              final lastMsg = messages.last;
              final lastMsgId = lastMsg['id']?.toString();
              if (lastMsgId != null) {
                _lastMessageIds[groupId] = lastMsgId;
                debugPrint('📝 Initialized lastPolledId for group $groupId from last message: $lastMsgId');
              }
            }
            continue; // Skip notification lần đầu tiên
          }

          // Lấy last polled ID
          final lastPolledId = _lastMessageIds[groupId];

          // Tìm tin nhắn mới từ người khác
          int newMessageCount = 0;
          String? latestContent;
          String? latestMessageType;
          String? latestMessageId;
          String? latestSenderName;

          for (int i = messages.length - 1; i >= 0; i--) {
            final msg = messages[i];
            final msgId = msg['id']?.toString();
            final senderId = msg['sender_id']?.toString();

            // Bỏ qua tin nhắn của mình
            if (senderId == _currentUserId) continue;

            // Dừng nếu đã thấy tin nhắn này trước đó
            if (msgId == lastPolledId) break;

            newMessageCount++;
            latestContent ??= msg['content'];
            latestMessageType ??= msg['message_type'];
            latestMessageId ??= msgId;
            // Lấy sender_name từ API, nếu không có thì lấy từ cache _userNames
            latestSenderName ??= msg['sender_name']?.toString() ?? _userNames[senderId];
          }

          // Nếu có tin nhắn mới
          if (newMessageCount > 0 && latestContent != null) {
            debugPrint('📬 Found $newMessageCount new messages in group $groupName');

            // Cập nhật last polled ID
            if (latestMessageId != null) {
              _lastMessageIds[groupId] = latestMessageId;
            }

            // Gửi notification với tên người gửi
            if (newMessageCount > 1) {
              // Nhiều tin nhắn mới
              await _sendMessageNotification(
                groupName,
                '',
                '$newMessageCount tin nhắn mới',
                'multi',
              );
            } else {
              // 1 tin nhắn mới - hiển thị tên người gửi
              await _sendMessageNotification(
                groupName,
                latestSenderName ?? 'Ai đó',
                latestContent,
                latestMessageType ?? 'text',
              );
            }
          }
        } catch (e) {
          debugPrint('❌ Error checking messages for group $groupId: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Error polling new messages: $e');
    }
  }

  /// Start polling để kiểm tra group requests mới
  Future<void> _startPollingGroupRequests() async {
    _pollingTimer?.cancel();

    // Check ngay lập tức lần đầu
    await _checkNewGroupRequests();
    debugPrint('📋 First group request check completed');

    // Sau đó check định kỳ mỗi 30 giây
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_isRunning) {
        await _checkNewGroupRequests();
      }
    });

    debugPrint('✅ Group request polling started (every 30 seconds)');
  }

  // Biến đánh dấu lần check đầu tiên
  bool _isFirstGroupRequestCheck = true;

  Future<void> _checkNewGroupRequests() async {
    try {
      debugPrint('🔍 Checking for new group requests...');

      if (_accessToken == null) {
        debugPrint('❌ No token for polling');
        return;
      }

      // Gọi API lấy danh sách nhóm của host
      final url = Uri.parse('${ApiConfig.baseUrl}/groups/mine');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      debugPrint('📥 Groups response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> groups = jsonDecode(response.body);
        debugPrint('📋 Found ${groups.length} groups');

        int totalPending = 0;
        String? latestGroupName;
        String? latestUserName;

        for (var group in groups) {
          final role = group['role']?.toString();

          // Chỉ kiểm tra nếu là host hoặc owner
          if (role == 'host' || role == 'owner') {
            final groupId = group['group_id'] ?? group['id'];
            final pendingUrl = Uri.parse('${ApiConfig.baseUrl}/groups/$groupId/requests');
            final pendingRes = await http.get(
              pendingUrl,
              headers: {'Authorization': 'Bearer $_accessToken'},
            );

            if (pendingRes.statusCode == 200) {
              final List<dynamic> pending = jsonDecode(pendingRes.body);
              debugPrint('   Found ${pending.length} pending requests for group ${group['name']}');

              totalPending += pending.length;
              if (pending.isNotEmpty) {
                latestGroupName = group['name'];
                latestUserName = pending.last['fullname'] ?? 'Ai đó';
              }
            }
          }
        }

        debugPrint('📊 Total pending: $totalPending, Last count: $_lastPendingCount, First check: $_isFirstGroupRequestCheck');

        // Lần đầu tiên chỉ lưu count, không gửi notification
        if (_isFirstGroupRequestCheck) {
          _lastPendingCount = totalPending;
          _isFirstGroupRequestCheck = false;
          debugPrint('📝 First check - initialized lastPendingCount to: $totalPending');

          // Chỉ bật badge nếu có pending requests
          if (totalPending > 0) {
            NotificationService().showBadge();
          }
          return;
        }

        // Nếu có request mới hơn lần check trước
        if (totalPending > _lastPendingCount && latestGroupName != null) {
          debugPrint('🔔 NEW REQUEST DETECTED! Sending notification...');

          // Bật chấm đỏ badge
          NotificationService().showBadge();

          await NotificationService().showGroupRequestNotification(
            userName: latestUserName ?? 'Có người',
            groupName: latestGroupName,
          );

          debugPrint('✅ Group request notification sent!');
        }

        // Cập nhật badge nếu có pending requests
        if (totalPending > 0) {
          NotificationService().showBadge();
        }

        _lastPendingCount = totalPending;
      }
    } catch (e) {
      debugPrint('❌ Error polling group requests: $e');
    }
  }

  /// Dừng service - gọi khi logout
  Future<void> stop() async {
    debugPrint('🛑 Stopping background notification service');

    _isRunning = false;

    _pollingTimer?.cancel();
    _messagePollingTimer?.cancel();

    // Đóng tất cả WebSocket connections
    for (var entry in _groupChannels.entries) {
      try {
        await entry.value.sink.close();
      } catch (_) {}
    }
    _groupChannels.clear();

    _accessToken = null;
    _currentUserId = null;
    _lastPendingCount = 0;
    _lastMessageIds.clear();
    _userNames.clear();
    _isFirstGroupRequestCheck = true; // Reset để lần sau start lại

    debugPrint('✅ Background notification service stopped');
  }

  /// Kiểm tra trạng thái đang chạy
  bool get isRunning => _isRunning;

  /// Số lượng WebSocket connections đang active
  int get activeConnections => _groupChannels.length;
}
