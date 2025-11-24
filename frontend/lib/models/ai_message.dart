/// Model for AI Chat messages
class AiMessage {
  final String role; // "user" or "assistant"
  final String text;
  final String time;

  AiMessage({
    required this.role,
    required this.text,
    required this.time,
  });

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'text': text,
      'time': time,
    };
  }

  factory AiMessage.fromJson(Map<String, dynamic> json) {
    return AiMessage(
      role: json['role'] ?? 'user',
      text: json['text'] ?? '',
      time: json['time'] ?? '',
    );
  }

  bool get isUser => role == 'user';
}

