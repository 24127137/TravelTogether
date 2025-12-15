/// File: message.dart
/// Description: Message model for chat/message data.

class Message {
  final String sender;
  final String message;
  final String time;
  final bool isOnline;
  final bool isUser;
  final String? imageUrl;
<<<<<<< HEAD
  final String messageType; // 'text' hoặc 'image'
  final String? senderAvatarUrl; // === THÊM MỚI: Avatar của người gửi ===
  final bool isSeen; // === THÊM MỚI: Trạng thái đã seen hay chưa ===
  final DateTime? createdAt; // === THÊM MỚI: Thời gian tạo tin nhắn (để group theo ngày) ===
=======
  final String messageType; // 'text', 'image', 'system', 'leave_group', 'join_group'
  final String? senderAvatarUrl; //Avatar của người gửi
  final bool isSeen; //Trạng thái đã seen hay chưa
  final DateTime? createdAt; //Thời gian tạo tin nhắn (để group theo ngày)
  final String? senderName; //Tên người gửi (dùng cho system message)
>>>>>>> week10

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
<<<<<<< HEAD
    this.createdAt, // === THÊM MỚI ===
  });

=======
    this.createdAt, 
    this.senderName, 
  });

  //Kiểm tra có phải system message không
  bool get isSystemMessage =>
      messageType == 'system' ||
      messageType == 'leave_group' ||
      messageType == 'join_group' ||
      messageType == 'kick_member';

>>>>>>> week10
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

<<<<<<< HEAD
    // === THÊM MỚI (GĐ 13): Parse imageUrl và messageType ===
    final imageUrl = map['image_url']?.toString();
    final messageType = map['message_type']?.toString() ?? 'text';
    final senderAvatarUrl = map['sender_avatar_url']?.toString();

    // === THÊM MỚI: Parse createdAt ===
=======

    final imageUrl = map['image_url']?.toString();
    final messageType = map['message_type']?.toString() ?? 'text';
    final senderAvatarUrl = map['sender_avatar_url']?.toString();
    final senderName = map['sender_name']?.toString(); 

    //Parse createdAt
>>>>>>> week10
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
<<<<<<< HEAD
      createdAt: createdAt, // === THÊM MỚI ===
=======
      createdAt: createdAt,
      senderName: senderName, 
>>>>>>> week10
    );
  }
}
