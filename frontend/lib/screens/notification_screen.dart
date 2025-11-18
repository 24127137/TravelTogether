import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/notification.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Profile avatar trên cùng
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: CircleAvatar(
                radius: 72.5,
                backgroundImage: AssetImage('assets/images/notification_logo.png'),
              ),
            ),

            // Danh sách thông báo
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: ListView(
                  children: [
                    NotificationItem(
                      icon: 'assets/images/heart.jpg',
                      title: 'Tìm nhóm thành công',
                      type: NotificationType.matching,
                    ),
                    const SizedBox(height: 20),
                    NotificationItem(
                      icon: 'assets/images/message.jpg',
                      title: '1 tháng 2 lần',
                      subtitle: ' nhắn tin',
                      type: NotificationType.message,
                    ),
                    const SizedBox(height: 20),
                    NotificationItem(
                      icon: 'assets/images/alert.png',
                      title: 'Bảo mật',
                      type: NotificationType.security,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum NotificationType { matching, message, security }

class NotificationItem extends StatelessWidget {
  final String icon;
  final String title;
  final String? subtitle;
  final NotificationType type;

  const NotificationItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFB99668),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        children: [
          // Icon với background
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: type == NotificationType.message
                  ? const Color(0xFFE0CEC0)
                  : null,
              image: type != NotificationType.message
                  ? DecorationImage(
                image: AssetImage(icon),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: type == NotificationType.message
                ? Icon(Icons.message, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 22),

          // Text
          Expanded(
            child: subtitle != null
                ? Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: title,
                    style: const TextStyle(
                      color: Color(0xFFEDE2CC),
                      fontSize: 28,
                      fontFamily: 'Alegreya',
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.28,
                    ),
                  ),
                  TextSpan(
                    text: subtitle,
                    style: const TextStyle(
                      color: Color(0xFFEDE2CC),
                      fontSize: 28,
                      fontFamily: 'Alegreya',
                      fontWeight: FontWeight.w400,
                      letterSpacing: -1.28,
                    ),
                  ),
                ],
              ),
            )
                : Text(
              title,
              style: const TextStyle(
                color: Color(0xFFEDE2CC),
                fontSize: 28,
                fontFamily: 'Alegreya',
                fontWeight: FontWeight.w400,
                letterSpacing: -1.28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
