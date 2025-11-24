import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/message.dart';
import 'member_screen(Host).dart';

//màn hình lúc chat
class ChatboxScreen extends StatefulWidget {
  const ChatboxScreen({Key? key}) : super(key: key);

  @override
  _ChatboxScreenState createState() => _ChatboxScreenState();
}

class _ChatboxScreenState extends State<ChatboxScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  List<Message> _messages = [];
  bool _isLoading = true;
  String? _accessToken;
  String? _currentUserId; // Thêm biến để lưu user_id hiện tại
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadAccessToken();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    // Auto refresh every 3 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _loadChatHistory(silent: true);
    });
  }

  Future<void> _loadAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _currentUserId = prefs.getString('user_id'); // Lấy user_id

    // DEBUG: Kiểm tra SharedPreferences
    print('🔍 ===== SHARED PREFERENCES DEBUG =====');
    print('🔍 All keys: ${prefs.getKeys()}');
    print('🔍 Access Token exists: ${_accessToken != null}');
    print('🔍 User ID: $_currentUserId');
    print('🔍 ====================================');

    if (_accessToken != null) {
      await _loadChatHistory();
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('chat_error_no_token'.tr())),
      );
    }
  }

  Future<void> _loadChatHistory({bool silent = false}) async {
    if (_accessToken == null) return;

    if (!silent) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final url = ApiConfig.getUri(ApiConfig.chatHistory);
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_accessToken",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

        setState(() {
          _messages = data.map((msg) {
            // Parse UTC time và chuyển sang local time
            final createdAtUtc = DateTime.parse(msg['created_at']);
            final createdAtLocal = createdAtUtc.toLocal(); // Chuyển sang giờ địa phương
            final timeStr = DateFormat('HH:mm').format(createdAtLocal);
            final senderId = msg['sender_id'] ?? '';

            // DEBUG: In ra để kiểm tra CHI TIẾT
            print('\n🔍 ===== MESSAGE DEBUG =====');
            print('🔍 Current User ID: "$_currentUserId"');
            print('🔍   - Type: ${_currentUserId.runtimeType}');
            print('🔍   - Length: ${_currentUserId?.length ?? 0}');
            print('🔍 Sender ID: "$senderId"');
            print('🔍   - Type: ${senderId.runtimeType}');
            print('🔍   - Length: ${senderId.length}');
            print('🔍 Are they equal? ${senderId == _currentUserId}');
            print('🔍 Message content: "${msg['content']}"');

            // So sánh sender_id với current user_id để phân biệt tin nhắn
            final isUser = (_currentUserId != null && senderId == _currentUserId);

            print('🔍 Result isUser: $isUser');
            print('🔍 Will display on: ${isUser ? "RIGHT (bên phải)" : "LEFT (bên trái)"}');
            print('🔍 =========================\n');

            return Message(
              sender: senderId,
              message: msg['content'] ?? '',
              time: timeStr,
              isOnline: true,
              isUser: isUser, // Gán đúng giá trị isUser
            );
          }).toList();
          _isLoading = false;
        });

        // Scroll to bottom after loading
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      } else {
        if (!silent) {
          throw Exception('Failed to load chat history: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (!silent) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'chat_error_load'.tr()}: $e')),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _accessToken == null) return;

    final url = ApiConfig.getUri(ApiConfig.chatSend);

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_accessToken",
        },
        body: jsonEncode({
          "content": text,
          "message_type": "text",
        }),
      );

      if (response.statusCode == 200) {
        _controller.clear();
        // Reload chat history to get the new message
        await _loadChatHistory(silent: true);

        // Scroll to bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          }
        });
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'chat_error_send'.tr()}: $e')),
      );
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.removeListener(() {});
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: const Color(0xFFB99668),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'chat_title'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                image: const DecorationImage(
                  image: AssetImage('assets/images/chatbot_icon.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
        toolbarHeight: 100,
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline, color: Colors.white, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MemberScreenHost(
                    groupName: "1 tháng 2 lần",
                    currentMembers: 8,
                    maxMembers: 12,
                    members: [
                      Member(
                        id: "1",
                        name: "Nguyễn Văn An",
                        email: "an.nguyen@gmail.com",
                        avatarUrl: "https://randomuser.me/api/portraits/men/1.jpg",
                      ),
                      Member(
                        id: "2",
                        name: "Trần Thị Bình",
                        email: "binh.tran@gmail.com",
                        avatarUrl: "https://randomuser.me/api/portraits/women/2.jpg",
                      ),
                      Member(
                        id: "3",
                        name: "Lê Hoàng Cường",
                        email: "cuong.le@gmail.com",
                        avatarUrl: "https://randomuser.me/api/portraits/men/3.jpg",
                      ),
                      Member(
                        id: "4",
                        name: "Phạm Minh Đức",
                        email: "duc.pham@gmail.com",
                        avatarUrl: "https://randomuser.me/api/portraits/men/4.jpg",
                      ),
                      Member(
                        id: "5",
                        name: "Hoàng Thị Lan",
                        email: "lan.hoang@gmail.com",
                        avatarUrl: "https://randomuser.me/api/portraits/women/5.jpg",
                      ),
                    ],
                    pendingRequests: [
                      PendingRequest(
                        id: "p1",
                        name: "Vũ Quang Hải",
                        rating: 4.8,
                        keywords: ["Thân thiện", "Đúng giờ", "Vui vẻ"],
                      ),
                      PendingRequest(
                        id: "p2",
                        name: "Đỗ Thị Mai",
                        rating: 4.5,
                        keywords: ["Hòa đồng", "Năng động"],
                      ),
                      PendingRequest(
                        id: "p3",
                        name: "Ngô Văn Nam",
                        rating: 4.2,
                        keywords: ["Lịch sự", "Chăm chỉ", "Tích cực"],
                      ),
                      PendingRequest(
                        id: "p4",
                        name: "Bùi Thị Oanh",
                        rating: 4.7,
                        keywords: ["Nhiệt tình", "Dễ thương"],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFFEBE3D7),
      body: _isLoading
        ? const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF8A724C),
            ),
          )
        : LayoutBuilder(
        builder: (context, constraints) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          const double inputBarHeight = 56.0; // estimated total height for input area
          return Stack(
            children: [
              // Main column with header + list; list bottom padding accounts for inputBarHeight
              Column(
                children: [
                  // White background section with rounded top corners
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEBE3D7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'today'.tr(),
                                style: const TextStyle(color: Colors.black54, fontSize: 12),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              color: Colors.white,
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: EdgeInsets.only(
                                  left: 12,
                                  right: 12,
                                  top: 0,
                                  bottom: inputBarHeight + 8 + bottomInset,
                                ),
                                itemCount: _messages.length,
                                itemBuilder: (context, index) {
                                  final m = _messages[index];
                                  return _MessageBubble(message: m);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Positioned input bar anchored above keyboard
              Positioned(
                left: 0,
                right: 0,
                bottom: bottomInset, // sits immediately above keyboard
                child: SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    color: Colors.white,
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBE3D7),
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                hintText: 'enter_message'.tr(),
                                hintStyle: const TextStyle(color: Colors.black38),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: const Color(0xFFB99668),
                          shape: const CircleBorder(),
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.white),
                            onPressed: _sendMessage,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  const _MessageBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.isUser;
    final bubbleColor = isUser ? const Color(0xFF8A724C) : const Color(0xFFB99668);
    final textColor = isUser ? Colors.white : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Image.asset('assets/images/chatbot_icon.png', width: 40, height: 40),
            )
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(0),
                  bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(20),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha((0.05 * 255).toInt()), blurRadius: 2, offset: const Offset(0, 1))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(color: textColor, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(message.time, style: TextStyle(color: textColor.withAlpha((0.7 * 255).toInt()), fontSize: 11)),
                      const SizedBox(width: 6),
                      Icon(Icons.done_all, size: 14, color: textColor.withAlpha((0.7 * 255).toInt())),
                    ],
                  )
                ],
              ),
            ),
          ),
          if (isUser) ...[
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Image.asset('assets/images/avatar.jpg', width: 40, height: 40),
            )
          ]
        ],
      ),
    );
  }
}