/// File: messages_screen.dart
/// Mô tả: Widget nội dung tin nhắn. Đã dịch sang tiếng Việt.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
// import '../data/mock_messages.dart'; // COMMENTED: Bỏ mock data
import 'chatbox_screen.dart';
import 'ai_chatbot_screen.dart'; // Import AI chatbot screen
//File này là screen tên là <OFFICIAL MESSAGE> trong figma

class MessagesScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final String? accessToken;

  const MessagesScreen({Key? key, this.onBack, this.accessToken}) : super(key: key);

  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<ConversationItem> _conversations = [];
  bool _isLoading = true;
  String? _accessToken;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  // Tự động reload khi quay lại màn hình này
  @override
  void didUpdateWidget(MessagesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadConversations();
  }

  // Hàm xử lý pull-to-refresh
  Future<void> _handleRefresh() async {
    await _loadConversations();
    // Thêm delay nhỏ để animation mượt hơn
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _loadConversations() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');

    List<ConversationItem> conversations = [];

    // 1. LUÔN LUÔN hiển thị AI Chatbot conversation (đứng đầu)
    final aiMessages = prefs.getString('ai_chat_messages');
    String aiLastMessage = 'ai_chat_default_message'.tr(); // Message mặc định
    String aiLastTime = '';

    if (aiMessages != null && aiMessages.isNotEmpty) {
      try {
        final List<dynamic> messagesJson = jsonDecode(aiMessages);
        if (messagesJson.isNotEmpty) {
          final lastMsg = messagesJson.last;
          aiLastTime = lastMsg['time'] ?? '';
          aiLastMessage = lastMsg['text'] ?? aiLastMessage;
        }
      } catch (e) {
        print('Error loading AI chat: $e');
      }
    }

    // LUÔN thêm AI Chatbot vào đầu danh sách
    conversations.add(ConversationItem(
      sender: 'ai_chat_bot_name'.tr(), // "AI Chatbot"
      message: aiLastMessage,
      time: aiLastTime,
      isOnline: true,
      isAiChat: true,
    ));

    // 2. Load Group Chat conversation (nếu có)
    if (_accessToken != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final currentUserId = prefs.getString('user_id');
        final lastSeenMessageId = prefs.getString('last_seen_message_id'); // === THÊM MỚI: Lấy ID tin nhắn cuối đã seen ===

        final url = ApiConfig.getUri(ApiConfig.chatHistory);
        final response = await http.get(
          url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $_accessToken",
          },
        );

        if (response.statusCode == 200) {
          final List<dynamic> messages = jsonDecode(utf8.decode(response.bodyBytes));

          if (messages.isNotEmpty) {
            final lastMsg = messages.last;
            final createdAtUtc = DateTime.parse(lastMsg['created_at']);
            final createdAtLocal = createdAtUtc.toLocal();

            // === THÊM MỚI: Format time - nếu hôm nay hiện giờ, nếu không hiện ngày ===
            final now = DateTime.now();
            final isToday = createdAtLocal.year == now.year &&
                           createdAtLocal.month == now.month &&
                           createdAtLocal.day == now.day;

            final timeStr = isToday
                ? DateFormat('HH:mm').format(createdAtLocal)
                : DateFormat('d \'thg\' M').format(createdAtLocal);

            // === THÊM MỚI: Format message preview ===
            final messageType = lastMsg['message_type'] ?? 'text';
            final senderId = lastMsg['sender_id']?.toString() ?? '';
            final isMyMessage = (currentUserId != null && senderId == currentUserId);

            String messagePreview;
            if (messageType == 'image') {
              messagePreview = isMyMessage ? 'Bạn đã gửi một ảnh' : 'Đã gửi một ảnh';
            } else {
              final content = lastMsg['content'] ?? '';
              messagePreview = isMyMessage ? 'Bạn: $content' : content;
            }

            // === THÊM MỚI: Kiểm tra có tin nhắn chưa seen không ===
            bool hasUnseen = false;
            if (!isMyMessage) {
              // Tin nhắn cuối là của người khác
              final lastMessageId = lastMsg['id']?.toString() ?? '';
              // Nếu ID tin nhắn cuối khác với ID đã seen, hoặc chưa có ID đã seen
              hasUnseen = (lastSeenMessageId == null || lastSeenMessageId != lastMessageId);
            }

            print('📬 Group chat - lastMessageId: ${lastMsg['id']}, lastSeenId: $lastSeenMessageId, hasUnseen: $hasUnseen');

            conversations.add(ConversationItem(
              sender: 'chat_title'.tr(), // "Nhóm chat"
              message: messagePreview,
              time: timeStr,
              isOnline: true,
              isAiChat: false,
              hasUnseenMessages: hasUnseen, // === THÊM MỚI ===
            ));
          }
        }
      } catch (e) {
        print('Error loading group chat: $e');
      }
    }

    setState(() {
      _conversations = conversations;
      _isLoading = false;
    });
  }

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

                      // Messages list với Pull-to-Refresh
                      Expanded(
                        child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFC69A61),
                              ),
                            )
                          : _conversations.isEmpty
                            ? RefreshIndicator(
                                color: const Color(0xFFC69A61),
                                backgroundColor: Colors.white,
                                onRefresh: _handleRefresh,
                                child: SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  child: SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.5,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.chat_bubble_outline,
                                            size: 64,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'chat_no_group'.tr(),
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : RefreshIndicator(
                                color: const Color(0xFFC69A61),
                                backgroundColor: Colors.white,
                                strokeWidth: 3.0,
                                displacement: 40.0,
                                onRefresh: _handleRefresh,
                                child: ListView.separated(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: EdgeInsets.only(top: 0, bottom: 20 * scaleFactor),
                                  itemCount: _conversations.length,
                                  separatorBuilder: (_, __) => SizedBox(height: spacing),
                                  itemBuilder: (context, index) {
                                    final conv = _conversations[index];
                                    return _MessageTile(
                                      sender: conv.sender,
                                      message: conv.message,
                                      time: conv.time,
                                      isOnline: conv.isOnline,
                                      isAiChat: conv.isAiChat, // Pass isAiChat
                                      hasUnseenMessages: conv.hasUnseenMessages, // === THÊM MỚI: Pass unseen status ===
                                      scaleFactor: scaleFactor,
                                    );
                                  },
                                ),
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
  final bool isAiChat; // Thêm parameter
  final bool hasUnseenMessages; // === THÊM MỚI: Có tin nhắn chưa seen không ===
  final double scaleFactor;

  const _MessageTile({
    required this.sender,
    required this.message,
    required this.time,
    required this.isOnline,
    required this.isAiChat, // Thêm required
    this.hasUnseenMessages = false, // === THÊM MỚI ===
    this.scaleFactor = 1.0,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        // Navigate dựa trên isAiChat
        if (isAiChat) {
          // Navigate to AI Chatbot Screen
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AiChatbotScreen(),
            ),
          );
        } else {
          // Navigate to Group Chat Screen
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChatboxScreen(),
            ),
          );
        }

        // Reload conversations khi quay lại
        if (context.mounted) {
          final state = context.findAncestorStateOfType<_MessagesScreenState>();
          state?._loadConversations();
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              // Hiển thị icon khác nhau cho AI Chatbot vs Group Chat
              isAiChat
                ? Container(
                    width: 64 * scaleFactor,
                    height: 64 * scaleFactor,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: const DecorationImage(
                        image: AssetImage('assets/images/chatbot_icon.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                : CircleAvatar(
                    radius: 32 * scaleFactor,
                    backgroundColor: const Color(0xFFD9CBB3),
                    child: Icon(Icons.person, size: 32 * scaleFactor, color: Colors.white),
                  ),
              // Removed the small online indicator dot per request
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
                    fontWeight: hasUnseenMessages ? FontWeight.bold : FontWeight.w600, // === In đậm nếu chưa seen ===
                  ),
                ),
                SizedBox(height: 6 * scaleFactor),
                Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: hasUnseenMessages ? const Color(0xFF1B1E28) : const Color(0xFF7C838D), // === Đổi màu đậm hơn nếu chưa seen ===
                    fontSize: 14 * scaleFactor,
                    fontWeight: hasUnseenMessages ? FontWeight.w600 : FontWeight.normal, // === In đậm nếu chưa seen ===
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

// ---------- CONVERSATION ITEM MODEL ----------
class ConversationItem {
  final String sender;
  final String message;
  final String time;
  final bool isOnline;
  final bool isAiChat; // Thêm flag để phân biệt AI chat vs Group chat
  final bool hasUnseenMessages; // === THÊM MỚI: Có tin nhắn chưa đọc không ===

  ConversationItem({
    required this.sender,
    required this.message,
    required this.time,
    this.isOnline = false,
    this.isAiChat = false, // Default là group chat
    this.hasUnseenMessages = false, // === THÊM MỚI: Mặc định là đã seen ===
  });
}
