/// File: message.dart
/// Description: Message model for chat/message data.

class Message {
  final String sender;
  final String message;
  final String time;
  // make non-nullable with default false to avoid runtime null issues
  final bool isOnline;
  final bool isUser;

  const Message({
    required this.sender,
    required this.message,
    required this.time,
    this.isOnline = false,
    this.isUser = false,
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

    return Message(
      sender: sender,
      message: message,
      time: time,
      isOnline: isOnline,
      isUser: isUser,
    );
  }
}
