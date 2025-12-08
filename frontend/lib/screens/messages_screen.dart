import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/chat_system_message_service.dart';
import '../services/chat_cache_service.dart';
import '../config/api_config.dart';
import 'chatbox_screen.dart';
import 'ai_chatbot_screen.dart';

class MessagesScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const MessagesScreen({Key? key, this.onBack}) : super(key: key);

  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<ConversationItem> _conversations = [];
  List<ConversationItem> _filteredConversations = []; // === THÊM: Danh sách đã lọc ===
  bool _isLoading = true;
  String? _accessToken;
  String? _currentUserId;

  // === THÊM: Search controller ===
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadConversations();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // === THÊM: Xử lý khi search text thay đổi ===
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase().trim();
      _filterConversations();
    });
  }

  // === THÊM: Lọc conversations theo search query ===
  void _filterConversations() {
    if (_searchQuery.isEmpty) {
      _filteredConversations = List.from(_conversations);
    } else {
      _filteredConversations = _conversations.where((conv) {
        final senderMatch = conv.sender.toLowerCase().contains(_searchQuery);
        final messageMatch = conv.message.toLowerCase().contains(_searchQuery);
        return senderMatch || messageMatch;
      }).toList();
    }
  }

  @override
  void didUpdateWidget(MessagesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadConversations();
  }

  Future<void> _handleRefresh() async {
    await _loadConversations();
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _loadConversations() async {
    _accessToken = await AuthService.getValidAccessToken();
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('user_id');

    List<ConversationItem> conversations = [];

    // === 1. Thêm AI Chat (nhanh, từ local) ===
    final aiMessages = prefs.getString('ai_chat_messages');
    String aiLastMessage = 'ai_chat_default_message'.tr();
    String aiLastTime = '';

    if (aiMessages != null && aiMessages.isNotEmpty) {
      try {
        final List<dynamic> messagesJson = jsonDecode(aiMessages);
        if (messagesJson.isNotEmpty) {
          final lastMsg = messagesJson.last;
          aiLastTime = lastMsg['time'] ?? '';
          aiLastMessage = lastMsg['text'] ?? aiLastMessage;
        }
      } catch (_) {}
    }

    conversations.add(ConversationItem(
      sender: 'ai_chat_bot_name'.tr(),
      message: aiLastMessage,
      time: aiLastTime,
      isOnline: true,
      isAiChat: true,
    ));

    if (_accessToken == null) {
      setState(() {
        _conversations = conversations;
        _filterConversations();
        _isLoading = false;
      });
      return;
    }

    // === 2. Lấy danh sách groups ===
    try {
      final response = await http.get(
        ApiConfig.getUri(ApiConfig.myGroup),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_accessToken",
        },
      );

      if (response.statusCode == 200) {
        final dynamic rawData = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> groupIdList = [];
        if (rawData is List) {
          groupIdList = rawData;
        } else if (rawData is Map<String, dynamic>) {
          groupIdList = rawData['groups'] ?? rawData['group_ids'] ?? rawData['data'] ?? [];
        }

        // === 3. Load TẤT CẢ groups SONG SONG ===
        final futures = <Future<ConversationItem?>>[];

        for (var idItem in groupIdList) {
          int groupId = 0;
          if (idItem is int) {
            groupId = idItem;
          } else if (idItem is Map<String, dynamic>) {
            groupId = idItem['group_id'] ?? 0;
          } else {
            groupId = int.tryParse(idItem.toString()) ?? 0;
          }

          if (groupId != 0) {
            futures.add(_loadSingleGroup(groupId, prefs));
          }
        }

        // Chờ tất cả hoàn thành song song
        final results = await Future.wait(futures);

        for (var item in results) {
          if (item != null) {
            conversations.add(item);
          }
        }
      }
    } catch (e) {
      print('❌ Lỗi load danh sách nhóm: $e');
    }

    if (mounted) {
      setState(() {
        _conversations = conversations;
        _filterConversations();
        _isLoading = false;
      });
    }
  }

  /// Load thông tin một group (chạy song song)
  Future<ConversationItem?> _loadSingleGroup(int groupId, SharedPreferences prefs) async {
    try {
      String groupName = 'Nhóm chat';
      String? groupImageUrl;
      Map<String, dynamic> groupDetail = {'id': groupId};
      String messagePreview = 'Bắt đầu cuộc trò chuyện';
      String timeStr = '';
      bool hasUnseenMessages = false;

      // === Gọi detail và history SONG SONG ===
      final detailFuture = http.get(
        Uri.parse('${ApiConfig.baseUrl}/groups/$groupId/detail'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_accessToken",
        },
      );

      // Ưu tiên cache trước
      List<dynamic>? messages = await ChatCacheService.getMessages(groupId.toString());

      final historyFuture = messages == null
          ? http.get(
              Uri.parse('${ApiConfig.baseUrl}/chat/$groupId/history'),
              headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer $_accessToken",
              },
            )
          : Future.value(null);

      // Chờ cả 2 API
      final results = await Future.wait([detailFuture, historyFuture]);

      // Xử lý detail response
      final detailResponse = results[0] as http.Response;
      if (detailResponse.statusCode == 200) {
        groupDetail = jsonDecode(utf8.decode(detailResponse.bodyBytes)) as Map<String, dynamic>;
        groupName = groupDetail['name']?.toString() ?? 'Nhóm chat';
        groupImageUrl = groupDetail['group_image_url']?.toString();
      }

      // Xử lý history response
      if (messages == null && results[1] != null) {
        final historyResponse = results[1] as http.Response;
        if (historyResponse.statusCode == 200) {
          messages = jsonDecode(utf8.decode(historyResponse.bodyBytes));
          // Lưu cache cho lần sau (không await để không block)
          if (messages != null) {
            ChatCacheService.saveMessages(groupId.toString(), messages);
          }
        }
      }

      // Xử lý tin nhắn
      if (messages != null && messages.isNotEmpty) {
        final lastMsg = messages.last as Map<String, dynamic>;

        final createdAt = lastMsg['created_at'];
        if (createdAt != null) {
          final createdAtLocal = DateTime.parse(createdAt.toString()).toLocal();
          final now = DateTime.now();
          final isToday = createdAtLocal.year == now.year &&
              createdAtLocal.month == now.month &&
              createdAtLocal.day == now.day;

          timeStr = isToday
              ? DateFormat('HH:mm').format(createdAtLocal)
              : DateFormat('d \'thg\' M').format(createdAtLocal);
        }

        final messageType = lastMsg['message_type'] ?? 'text';
        final senderId = lastMsg['sender_id']?.toString() ?? '';
        final isMyMessage = senderId == _currentUserId;

        if (messageType == 'image') {
          messagePreview = isMyMessage ? 'Bạn đã gửi một ảnh' : 'Đã gửi một ảnh';
        } else if (messageType == 'video') {
          messagePreview = isMyMessage ? 'Bạn đã gửi một video' : 'Đã gửi một video';
        } else if (messageType == 'file') {
          messagePreview = isMyMessage ? 'Bạn đã gửi một tệp' : 'Đã gửi một tệp';
        } else {
          final content = lastMsg['content']?.toString() ?? '';
          if (content.isNotEmpty) {
            final parsedSystem = ChatSystemMessageService.parseSystemMessage(content);
            if (parsedSystem != null) {
              messagePreview = parsedSystem['display']!;
            } else {
              messagePreview = isMyMessage ? 'Bạn: $content' : content;
            }
          }
        }

        // Kiểm tra unseen
        final lastSeenId = prefs.getString('last_seen_message_id_$groupId');
        if (lastSeenId != null) {
          int lastSeenIndex = -1;
          for (int i = 0; i < messages.length; i++) {
            if (messages[i]['id'].toString() == lastSeenId) {
              lastSeenIndex = i;
              break;
            }
          }

          int unreadCount = 0;
          for (int i = lastSeenIndex + 1; i < messages.length; i++) {
            final msgSenderId = messages[i]['sender_id']?.toString();
            if (msgSenderId != _currentUserId) {
              unreadCount++;
            }
          }
          hasUnseenMessages = unreadCount > 0;
        } else {
          hasUnseenMessages = !isMyMessage;
        }
      }

      return ConversationItem(
        sender: groupName,
        message: messagePreview,
        time: timeStr,
        isOnline: true,
        isAiChat: false,
        hasUnseenMessages: hasUnseenMessages,
        groupImageUrl: groupImageUrl,
        groupData: groupDetail,
      );
    } catch (e) {
      print('❌ Lỗi load group $groupId: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;
            final scaleFactor = (screenHeight / 800).clamp(0.7, 1.0);

            final titleFontSize = 28.0 * scaleFactor;
            final searchBarHeight = 46.0 * scaleFactor;
            final topSpacing = 50.0 * scaleFactor;
            final spacing = 18.0 * scaleFactor;
            final horizontalPadding = 16.0 * scaleFactor;

            return Stack(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: topSpacing),
                      Text(
                        'messages'.tr(),
                        style: TextStyle(
                          color: const Color(0xFFC69A61),
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: spacing),
                      _buildSearchBar(searchBarHeight, scaleFactor),
                      SizedBox(height: spacing),
                      Expanded(
                        child: _isLoading
                            ? ListView.separated(
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: 8,
                                separatorBuilder: (_, __) => SizedBox(height: spacing),
                                itemBuilder: (context, index) => const ConversationSkeletonItem(),
                              )
                            : _filteredConversations.isEmpty
                                ? RefreshIndicator(
                                    onRefresh: _handleRefresh,
                                    color: const Color(0xFFC69A61),
                                    child: SingleChildScrollView(
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      child: SizedBox(
                                        height: MediaQuery.of(context).size.height * 0.6,
                                        child: Center(
                                          child: Text(
                                            _searchQuery.isNotEmpty
                                              ? 'Không tìm thấy cuộc trò chuyện'
                                              : 'no_conversation_yet'.tr(),
                                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: _handleRefresh,
                                    color: const Color(0xFFC69A61),
                                    child: ListView.separated(
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      itemCount: _filteredConversations.length,
                                      separatorBuilder: (_, __) => SizedBox(height: spacing),
                                      itemBuilder: (context, index) {
                                        final conv = _filteredConversations[index];
                                        return _MessageTile(
                                          sender: conv.sender,
                                          message: conv.message,
                                          time: conv.time,
                                          isOnline: conv.isOnline,
                                          isAiChat: conv.isAiChat,
                                          hasUnseenMessages: conv.hasUnseenMessages,
                                          groupImageUrl: conv.groupImageUrl,
                                          scaleFactor: scaleFactor,
                                          groupData: conv.groupData,
                                        );
                                      },
                                    ),
                                  ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar(double height, double scaleFactor) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD4C9B9), width: 1.2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: TextField(
        controller: _searchController, // === THÊM: Controller ===
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.only(top: 16 * scaleFactor, bottom: 8 * scaleFactor),
          hintText: 'search_conversation'.tr(),
          hintStyle: TextStyle(color: const Color(0xFF7C838D), fontSize: 15 * scaleFactor),
          border: InputBorder.none,
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: 12 * scaleFactor, right: 8 * scaleFactor),
            child: Icon(Icons.search, color: const Color(0xFF7C838D), size: 20 * scaleFactor),
          ),
          prefixIconConstraints: BoxConstraints(minWidth: 40 * scaleFactor),
          // === THÊM: Clear button ===
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: const Color(0xFF7C838D), size: 18 * scaleFactor),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
        ),
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  final String sender, message, time;
  final bool isOnline, isAiChat, hasUnseenMessages;
  final String? groupImageUrl;
  final double scaleFactor;
  final Map<String, dynamic>? groupData;

  const _MessageTile({
    required this.sender,
    required this.message,
    required this.time,
    required this.isOnline,
    required this.isAiChat,
    this.hasUnseenMessages = false,
    this.groupImageUrl,
    this.scaleFactor = 1.0,
    this.groupData,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        if (isAiChat) {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AiChatbotScreen()));
        } else {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatboxScreen(groupData: groupData),
            ),
          );
        }

        // Refresh lại danh sách khi quay về
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
              isAiChat
                  ? Container(
                      width: 64 * scaleFactor,
                      height: 64 * scaleFactor,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(image: AssetImage('assets/images/chatbot_icon.png'), fit: BoxFit.cover),
                      ),
                    )
                  : (groupImageUrl != null && groupImageUrl!.isNotEmpty)
                      ? CircleAvatar(radius: 32 * scaleFactor, backgroundImage: NetworkImage(groupImageUrl!))
                      : CircleAvatar(
                          radius: 32 * scaleFactor,
                          backgroundColor: const Color(0xFFD9CBB3),
                          child: Icon(Icons.people, size: 32 * scaleFactor, color: Colors.white),
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
                    fontSize: 17 * scaleFactor,
                    fontWeight: hasUnseenMessages ? FontWeight.bold : FontWeight.w600,
                    color: const Color(0xFF1B1E28),
                  ),
                ),
                SizedBox(height: 6 * scaleFactor),
                Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14 * scaleFactor,
                    color: hasUnseenMessages ? const Color(0xFF1B1E28) : const Color(0xFF7C838D),
                    fontWeight: hasUnseenMessages ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8 * scaleFactor),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(time, style: TextStyle(color: const Color(0xFF7C838D), fontSize: 11 * scaleFactor)),
              SizedBox(height: 6 * scaleFactor),
              if (hasUnseenMessages)
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(color: Color(0xFFB99668), shape: BoxShape.circle),
                )
              else
                Icon(Icons.check, color: const Color(0xFF7C838D), size: 16 * scaleFactor),
            ],
          ),
        ],
      ),
    );
  }
}

class ConversationItem {
  final String sender;
  final String message;
  final String time;
  final bool isOnline;
  final bool isAiChat;
  final bool hasUnseenMessages;
  final String? groupImageUrl;
  final Map<String, dynamic>? groupData; 

  ConversationItem({
    required this.sender,
    required this.message,
    required this.time,
    this.isOnline = false,
    this.isAiChat = false,
    this.hasUnseenMessages = false,
    this.groupImageUrl,
    this.groupData,
  });
}

/// Skeleton loading item cho danh sách conversation
class ConversationSkeletonItem extends StatefulWidget {
  const ConversationSkeletonItem({Key? key}) : super(key: key);

  @override
  State<ConversationSkeletonItem> createState() => _ConversationSkeletonItemState();
}

class _ConversationSkeletonItemState extends State<ConversationSkeletonItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar skeleton
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: const [
                    Color(0xFFE0E0E0),
                    Color(0xFFF5F5F5),
                    Color(0xFFE0E0E0),
                  ],
                  stops: [
                    (_animation.value - 0.3).clamp(0.0, 1.0),
                    _animation.value.clamp(0.0, 1.0),
                    (_animation.value + 0.3).clamp(0.0, 1.0),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title skeleton
                  Container(
                    width: 140,
                    height: 18,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: const [
                          Color(0xFFE0E0E0),
                          Color(0xFFF5F5F5),
                          Color(0xFFE0E0E0),
                        ],
                        stops: [
                          (_animation.value - 0.3).clamp(0.0, 1.0),
                          _animation.value.clamp(0.0, 1.0),
                          (_animation.value + 0.3).clamp(0.0, 1.0),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Subtitle skeleton
                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: const [
                          Color(0xFFE0E0E0),
                          Color(0xFFF5F5F5),
                          Color(0xFFE0E0E0),
                        ],
                        stops: [
                          (_animation.value - 0.3).clamp(0.0, 1.0),
                          _animation.value.clamp(0.0, 1.0),
                          (_animation.value + 0.3).clamp(0.0, 1.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Time skeleton
            Container(
              width: 40,
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: const [
                    Color(0xFFE0E0E0),
                    Color(0xFFF5F5F5),
                    Color(0xFFE0E0E0),
                  ],
                  stops: [
                    (_animation.value - 0.3).clamp(0.0, 1.0),
                    _animation.value.clamp(0.0, 1.0),
                    (_animation.value + 0.3).clamp(0.0, 1.0),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

