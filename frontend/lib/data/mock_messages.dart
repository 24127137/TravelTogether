/// File: mock_messages.dart
<<<<<<< HEAD
/// Description: Mock data for messages based on the provided image.
import '../models/message.dart';


final List<Message> mockMessages = [
  // Tin nhắn bắt đầu cuộc trò chuyện (Chào Bot!!!)
  Message(
    sender: 'User',
    message: 'Chào Bot!!!',
    time: '9:24',
    isUser: true, // Tin nhắn của User -> Hiển thị bên phải
    isOnline: true,
  ),

  // Tin nhắn chi tiết kế hoạch
  Message(
    sender: 'User',
    message:
    'Mình muốn lên kế hoạch cho kỳ nghỉ với chồng của mình! Chồng mình thì thích leo núi, cắm trại! Còn riêng mình, mình thích bơi lặn sâu xuống dưới đại dương, phơi nắng trên những bãi cát trắng tinh. Mình cũng muốn kết nối với những người bạn mới! Yaayyy!',
    time: '9:30',
    isUser: true, // Tin nhắn của User -> Hiển thị bên phải
    isOnline: true,
  ),

  // Chatbot phản hồi 1
  Message(
    sender: 'Chatbot',
    message: 'Cảm ơn bạn.',
    time: '9:30', // Giả định thời gian giống tin nhắn User cuối
    isUser: false, // Tin nhắn của Chatbot -> Hiển thị bên trái
    isOnline: true,
  ),

  // Chatbot phản hồi 2 (Đề xuất)
  Message(
    sender: 'Chatbot',
    message: 'Bạn nên đi Phú Quốc, một hòn ngọc thật sự!!!',
    time: '9:30',
    isUser: false, // Tin nhắn của Chatbot -> Hiển thị bên trái
    isOnline: true,
  ),

  // User phản hồi cuối
  Message(
    sender: 'User',
    message: 'Oke bạn, để mình tìm hiểu',
    time: '9:39',
    isUser: true, // Tin nhắn của User -> Hiển thị bên phải
    isOnline: true,
  ),
];
=======
/// Description: Mock data for messages. Replace with API/backend in future.

import '../models/message.dart';

final List<Message> mockMessages = [
  Message(
    sender: 'six wonders',
    message: 'Hi, John! 👋 How are you doing?',
    time: '09:46',
    isOnline: true,
  ),
  Message(
    sender: 'HANOI IN YOUR HEART',
    message: 'You: I will be at home',
    time: '07:56',
    isOnline: false,
  ),
];

>>>>>>> 9fb9c5b (Add homepage frontend and after that implementation)
