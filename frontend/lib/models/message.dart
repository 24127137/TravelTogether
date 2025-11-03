/// File: message.dart
/// Description: Message model for chat/message data.

class Message {
  final String sender;
  final String message;
  final String time;
  final bool isOnline;

  Message({
    required this.sender,
    required this.message,
    required this.time,
    required this.isOnline,
  });
}

