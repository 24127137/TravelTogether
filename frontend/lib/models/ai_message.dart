/// Model for AI Chat messages
class AiMessage {
  final String role; // "user" or "assistant"
  final String text;
  final String time;
  final String? imageUrl; // === THÊM MỚI: Hỗ trợ tin nhắn ảnh ===

  AiMessage({
    required this.role,
    required this.text,
    required this.time,
    this.imageUrl, // === THÊM MỚI ===
  });

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'text': text,
      'time': time,
      'imageUrl': imageUrl, // === THÊM MỚI ===
    };
  }

  factory AiMessage.fromJson(Map<String, dynamic> json) {
    return AiMessage(
      role: json['role'] ?? 'user',
      text: json['text'] ?? '',
      time: json['time'] ?? '',
      imageUrl: json['imageUrl'], // === THÊM MỚI ===
    );
  }

  bool get isUser => role == 'user';
}

