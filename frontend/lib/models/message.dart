/// File: message.dart
/// Description: Message model for chat/message data.

class Message {
  final String sender;
  final String message;
  final String time;
  // make non-nullable with default false to avoid runtime null issues
  final bool isOnline;
  final bool isUser;
  // === THÊM MỚI (GĐ 13): Hỗ trợ tin nhắn ảnh ===
  final String? imageUrl;
  final String messageType; // 'text' hoặc 'image'
  final String? senderAvatarUrl; // === THÊM MỚI: Avatar của người gửi ===
  final bool isSeen; // === THÊM MỚI: Trạng thái đã seen hay chưa ===

  const Message({
    required this.sender,
    required this.message,
    required this.time,
    this.isOnline = false,
    this.isUser = false,
    this.imageUrl,
    this.messageType = 'text',
    this.senderAvatarUrl, // === THÊM MỚI ===
    this.isSeen = true, // === THÊM MỚI: Mặc định là đã seen ===
  });

  /// Create a Message from a dynamic map (e.g., Firestore document) safely.
  factory Message.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const Message(sender: 'Unknown', message: '', time: '00:00');
    }

    // normalize values and provide sensible defaults
    final sender = (map['sender'] ?? map['from'] ?? map['user'])?.toString() ?? 'Unknown';
    final message = (map['text'] ?? map['message'] ?? '')?.toString() ?? '';
    final time = (map['time'] ?? map['timestamp'] ?? '')?.toString() ?? '';

    // allow boolean-like strings or numbers
    bool parseBool(dynamic v) {
      if (v == null) return false;
      if (v is bool) return v;
      if (v is num) return v != 0;
      final s = v.toString().toLowerCase();
      return s == 'true' || s == '1' || s == 'yes';
    }

    final isUser = parseBool(map['isUser'] ?? map['userIs'] ?? map['fromUser']);
    final isOnline = parseBool(map['isOnline'] ?? map['online']);

    // === THÊM MỚI (GĐ 13): Parse imageUrl và messageType ===
    final imageUrl = map['image_url']?.toString();
    final messageType = map['message_type']?.toString() ?? 'text';
    final senderAvatarUrl = map['sender_avatar_url']?.toString(); // === THÊM MỚI ===

    return Message(
      sender: sender,
      message: message,
      time: time,
      isOnline: isOnline,
      isUser: isUser,
      imageUrl: imageUrl,
      messageType: messageType,
      senderAvatarUrl: senderAvatarUrl, // === THÊM MỚI ===
    );
  }
}
