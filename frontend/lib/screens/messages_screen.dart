/// File: messages_screen.dart
/// Mô tả: Widget nội dung tin nhắn. Đã dịch sang tiếng Việt.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../data/mock_messages.dart';
import 'chatbox_screen.dart';
//File này là screen tên là <OFFICIAL MESSAGE> trong figma
class MessagesScreen extends StatelessWidget {
  final VoidCallback? onBack;
  final String? accessToken;

  const MessagesScreen({Key? key, this.onBack, this.accessToken}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7), // Thêm màu nền cho đẹp hơn
      // Removed default AppBar to use the custom header inside the body
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20), // move search bar down slightly
            _buildSearchBar(),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(left: 12, right: 20),
                itemCount: mockMessages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 20),
                itemBuilder: (context, index) {
                  final m = mockMessages[index];
                  return _MessageTile(
                    sender: m.sender,
                    message: m.message,
                    time: m.time,
                    isOnline: m.isOnline == true,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- HEADER ----------
  Widget _buildHeader(BuildContext context) {
    return Padding(
      // remove left padding so back button sits at the screen edge
      padding: const EdgeInsets.only(top: 12, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back button aligned to the far left
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.arrow_back, color: Color(0xFFB99668)),
            onPressed: () {
              // Navigate back using pop instead of pushAndRemoveUntil
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(width: 12),
          // Cream-colored title pushed to the left (next to back button)
          Text(
            'messages'.tr(),
            style: const TextStyle(
              color: Color(0xFF8A724C),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- SEARCH BAR ----------
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 20),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'search_conversation'.tr(),
          hintStyle: const TextStyle(
            color: Color(0xFF7C838D),
            fontSize: 15,
          ),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF7C838D)),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(width: 1, color: Color(0xFFD4C9B9)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(width: 1, color: Color(0xFFB99668)),
          ),
        ),
      ),
    );
  }
}

// ---------- MESSAGE TILE ----------
class _MessageTile extends StatelessWidget {
  final String sender, message, time;
  final bool isOnline;

  const _MessageTile({
    required this.sender,
    required this.message,
    required this.time,
    required this.isOnline,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        // **********************************************
        // 2. THỰC HIỆN NAVIGATION ĐẾN CHATBOXSCREEN
        // **********************************************
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ChatboxScreen(),
          ),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: Color(0xFFD9CBB3),
                child: Icon(Icons.person, size: 32, color: Colors.white),
              ),
              if (isOnline)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD336),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sender,
                  style: const TextStyle(
                    color: Color(0xFF1B1E28),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF7C838D),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: const TextStyle(
                  color: Color(0xFF7C838D),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 6),
              const Icon(Icons.check, color: Color(0xFF7C838D), size: 16),
            ],
          ),
        ],
      ),
    );
  }
}