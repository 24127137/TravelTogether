/// File: message.dart
/// Description: Message model for chat/message data.

class Message {
  final String sender;
  final String message;
  final String time;
  final bool isOnline;
  final bool isUser;
  final String? imageUrl;
  final String messageType; // 'text' hoặc 'image'
  final String? senderAvatarUrl; // === THÊM MỚI: Avatar của người gửi ===
  final bool isSeen; // === THÊM MỚI: Trạng thái đã seen hay chưa ===
  final DateTime? createdAt; // === THÊM MỚI: Thời gian tạo tin nhắn (để group theo ngày) ===

  const Message({
    required this.sender,
    required this.message,
    required this.time,
    this.isOnline = false,
    this.isUser = false,
    this.imageUrl,
    this.messageType = 'text',
    this.senderAvatarUrl,
    this.isSeen = true,
    this.createdAt, // === THÊM MỚI ===
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
    final senderAvatarUrl = map['sender_avatar_url']?.toString();

    // === THÊM MỚI: Parse createdAt ===
    DateTime? createdAt;
    if (map['created_at'] != null) {
      try {
        createdAt = DateTime.parse(map['created_at'].toString()).toLocal();
      } catch (e) {
        createdAt = null;
      }
    }

    return Message(
      sender: sender,
      message: message,
      time: time,
      isOnline: isOnline,
      isUser: isUser,
      imageUrl: imageUrl,
      messageType: messageType,
      senderAvatarUrl: senderAvatarUrl,
      createdAt: createdAt, // === THÊM MỚI ===
    );
  }
}
