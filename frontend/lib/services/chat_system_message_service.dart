import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

/// Service để gửi system message vào chat group
/// Vì backend chỉ hỗ trợ message_type 'text' và 'image',
/// ta sử dụng prefix đặc biệt để đánh dấu system message
class ChatSystemMessageService {
  // Prefix để đánh dấu system message
  static const String systemPrefix = '[SYSTEM]';
  static const String leaveGroupPrefix = '[LEAVE_GROUP]';
  static const String joinGroupPrefix = '[JOIN_GROUP]';
  static const String kickMemberPrefix = '[KICK_MEMBER]';

  /// Gửi thông báo thành viên rời nhóm
  static Future<bool> sendLeaveGroupMessage({
    required String groupId,
    required String memberName,
  }) async {
    return await _sendSystemMessage(
      groupId: groupId,
      content: '$leaveGroupPrefix$memberName',
    );
  }

  /// Gửi thông báo thành viên tham gia nhóm
  static Future<bool> sendJoinGroupMessage({
    required String groupId,
    required String memberName,
  }) async {
    return await _sendSystemMessage(
      groupId: groupId,
      content: '$joinGroupPrefix$memberName',
    );
  }

  /// Gửi thông báo thành viên bị kick
  static Future<bool> sendKickMemberMessage({
    required String groupId,
    required String memberName,
  }) async {
    return await _sendSystemMessage(
      groupId: groupId,
      content: '$kickMemberPrefix$memberName',
    );
  }

  /// Gửi system message qua WebSocket
  static Future<bool> _sendSystemMessage({
    required String groupId,
    required String content,
  }) async {
    try {
      final accessToken = await AuthService.getValidAccessToken();
      if (accessToken == null) {
        print('❌ ChatSystemMessageService: No access token');
        return false;
      }

      // Tạo WebSocket connection
      final wsUrl = ApiConfig.chatWebSocketByGroup(groupId);
      print('🔌 ChatSystemMessageService: Connecting to $wsUrl');

      final channel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      // Gửi message
      channel.sink.add(jsonEncode({
        "message_type": "text",
        "content": content,
      }));

      print('📤 ChatSystemMessageService: Sent system message: $content');

      // Đợi một chút rồi đóng connection
      await Future.delayed(const Duration(milliseconds: 500));
      await channel.sink.close();

      print('✅ ChatSystemMessageService: Message sent successfully');
      return true;
    } catch (e) {
      print('❌ ChatSystemMessageService: Error sending message: $e');
      return false;
    }
  }

  /// Kiểm tra xem message có phải là system message không
  static bool isSystemMessage(String content) {
    return content.startsWith(systemPrefix) ||
        content.startsWith(leaveGroupPrefix) ||
        content.startsWith(joinGroupPrefix) ||
        content.startsWith(kickMemberPrefix);
  }

  /// Parse system message để lấy thông tin
  static Map<String, String>? parseSystemMessage(String content) {
    if (content.startsWith(leaveGroupPrefix)) {
      final name = content.substring(leaveGroupPrefix.length);
      return {
        'type': 'leave_group',
        'name': name,
        'display': '$name đã rời khỏi nhóm',
      };
    }
    if (content.startsWith(joinGroupPrefix)) {
      final name = content.substring(joinGroupPrefix.length);
      return {
        'type': 'join_group',
        'name': name,
        'display': '$name đã tham gia nhóm',
      };
    }
    if (content.startsWith(kickMemberPrefix)) {
      final name = content.substring(kickMemberPrefix.length);
      return {
        'type': 'kick_member',
        'name': name,
        'display': '$name đã bị xóa khỏi nhóm',
      };
    }
    if (content.startsWith(systemPrefix)) {
      final text = content.substring(systemPrefix.length);
      return {
        'type': 'system',
        'name': '',
        'display': text,
      };
    }
    return null;
  }
}

