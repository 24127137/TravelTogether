/// File: messages_screen.dart
/// Mô tả: Widget nội dung tin nhắn. Đã dịch sang tiếng Việt.

import 'package:flutter/material.dart';
import '../models/message.dart';
import '../data/mock_messages.dart';

class MessagesScreen extends StatelessWidget {
  final VoidCallback? onBack;
  const MessagesScreen({Key? key, this.onBack}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin nhắn'),
        leading: onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildSearchBar(),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: mockMessages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 20),
                itemBuilder: (context, index) {
                  final m = mockMessages[index];
                  return _MessageTile(
                    sender: m.sender,
                    message: m.message,
                    time: m.time,
                    isOnline: m.isOnline,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFFB99668)),
            onPressed: () {
              if (onBack != null) onBack!(); else Navigator.pop(context);
            },
          ),
          const Text(
            'Tin nhắn',
            style: TextStyle(
              color: Color(0xFF8A724C),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: Color(0xFFB99668), size: 26),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // ---------- SEARCH BAR ----------
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Tìm kiếm cuộc trò chuyện & tin nhắn',
          hintStyle: const TextStyle(
            color: Color(0xFF7C838D),
            fontSize: 16,
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
        // TODO: Navigate to chat detail
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
