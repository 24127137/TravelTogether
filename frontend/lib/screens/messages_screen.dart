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
      // Don't resize the scaffold when the keyboard appears; let the keyboard overlay content
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF7F7F7), // Thêm màu nền cho đẹp hơn
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive scaling dựa trên chiều cao màn hình
            final screenHeight = constraints.maxHeight;
            final scaleFactor = (screenHeight / 800).clamp(0.7, 1.0);

            final titleFontSize = 28.0 * scaleFactor;
            final searchBarHeight = 46.0 * scaleFactor;
            final topSpacing = 50.0 * scaleFactor;
            final spacing = 18.0 * scaleFactor;
            final horizontalPadding = 16.0 * scaleFactor;

            return Stack(
              children: [
                // Main content column (padded to leave room for floating avatar)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: topSpacing), // space for floating avatar

                      // Title (left-aligned, larger and gold)
                      Text(
                        'messages'.tr(),
                        style: TextStyle(
                          color: const Color(0xFFC69A61), // gold-ish
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Poppins',
                        ),
                      ),

                      SizedBox(height: spacing),

                      // Search bar styled like design
                      _buildSearchBar(searchBarHeight, scaleFactor),

                      SizedBox(height: spacing),

                      // Messages list
                      Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.only(top: 0, bottom: 20 * scaleFactor),
                          itemCount: mockMessages.length,
                          separatorBuilder: (_, __) => SizedBox(height: spacing),
                          itemBuilder: (context, index) {
                            final m = mockMessages[index];
                            return _MessageTile(
                              sender: m.sender,
                              message: m.message,
                              time: m.time,
                              isOnline: m.isOnline == true,
                              scaleFactor: scaleFactor,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // avatar removed per request
              ],
            );
          },
        ),
      ),
    );
  }

  // ---------- SEARCH BAR ----------
  Widget _buildSearchBar(double height, double scaleFactor) {
    return Padding(
      padding: const EdgeInsets.only(left: 0, right: 0),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD4C9B9), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: TextField(
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            // nudge hint down slightly: increase top padding and reduce bottom
            contentPadding: EdgeInsets.only(top: 16 * scaleFactor, bottom: 8 * scaleFactor, left: 0, right: 0),
            hintText: 'search_conversation'.tr(),
            hintStyle: TextStyle(color: const Color(0xFF7C838D), fontSize: 15 * scaleFactor),
            border: InputBorder.none,
            // keep the search icon and place the hint next to it
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: 12 * scaleFactor, right: 8 * scaleFactor),
              child: Icon(Icons.search, color: const Color(0xFF7C838D), size: 20 * scaleFactor),
            ),
            prefixIconConstraints: BoxConstraints(minWidth: 40 * scaleFactor, minHeight: 24 * scaleFactor),
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
  final double scaleFactor;

  const _MessageTile({
    required this.sender,
    required this.message,
    required this.time,
    required this.isOnline,
    this.scaleFactor = 1.0,
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
              CircleAvatar(
                radius: 32 * scaleFactor,
                backgroundColor: const Color(0xFFD9CBB3),
                child: Icon(Icons.person, size: 32 * scaleFactor, color: Colors.white),
              ),
              if (isOnline)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 14 * scaleFactor,
                    height: 14 * scaleFactor,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD336),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 16 * scaleFactor),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sender,
                  style: TextStyle(
                    color: const Color(0xFF1B1E28),
                    fontSize: 17 * scaleFactor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6 * scaleFactor),
                Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF7C838D),
                    fontSize: 14 * scaleFactor,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8 * scaleFactor),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: TextStyle(
                  color: const Color(0xFF7C838D),
                  fontSize: 11 * scaleFactor,
                ),
              ),
              SizedBox(height: 6 * scaleFactor),
              Icon(Icons.check, color: const Color(0xFF7C838D), size: 16 * scaleFactor),
            ],
          ),
        ],
      ),
    );
  }
}