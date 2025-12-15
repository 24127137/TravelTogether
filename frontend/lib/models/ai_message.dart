/// Model for AI Chat messages
class AiMessage {
  final String role; // "user" or "assistant"
  final String text;
  final String time;
<<<<<<< HEAD
  final String? imageUrl; // === THÊM MỚI: Hỗ trợ tin nhắn ảnh ===
=======
  final String? imageUrl; // Hỗ trợ tin nhắn ảnh
>>>>>>> week10

  AiMessage({
    required this.role,
    required this.text,
    required this.time,
<<<<<<< HEAD
    this.imageUrl, // === THÊM MỚI ===
=======
    this.imageUrl, 
>>>>>>> week10
  });

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'text': text,
      'time': time,
<<<<<<< HEAD
      'imageUrl': imageUrl, // === THÊM MỚI ===
=======
      'imageUrl': imageUrl, 
>>>>>>> week10
    };
  }

  factory AiMessage.fromJson(Map<String, dynamic> json) {
    return AiMessage(
      role: json['role'] ?? 'user',
      text: json['text'] ?? '',
      time: json['time'] ?? '',
<<<<<<< HEAD
      imageUrl: json['imageUrl'], // === THÊM MỚI ===
=======
      imageUrl: json['imageUrl'], 
>>>>>>> week10
    );
  }

  bool get isUser => role == 'user';
}

