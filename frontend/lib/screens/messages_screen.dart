import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
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
  bool _isLoading = true;
  String? _accessToken;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadConversations();
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
    print('🔍 Bắt đầu load conversations...');
    
    _accessToken = await AuthService.getValidAccessToken();
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('user_id');
    
    print('🔑 Access Token: ${_accessToken != null ? "Có" : "Không"}');
    print('👤 Current User ID: $_currentUserId');

    List<ConversationItem> conversations = [];

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
      } catch (e) {
        print('❌ Error loading AI chat: $e');
      }
    }

    conversations.add(ConversationItem(
      sender: 'ai_chat_bot_name'.tr(),
      message: aiLastMessage,
      time: aiLastTime,
      isOnline: true,
      isAiChat: true,
    ));
    
    print('✅ Đã thêm AI Chat. Tổng conversations: ${conversations.length}');

    if (_accessToken != null) {
      try {
        final myGroupUrl = ApiConfig.getUri(ApiConfig.myGroup);
        print('📡 Đang gọi API: $myGroupUrl');
        
        final response = await http.get(
          myGroupUrl,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $_accessToken",
          },
        );

        print('📥 Response status: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          final dynamic rawData = jsonDecode(utf8.decode(response.bodyBytes));
          print('📦 Raw data type: ${rawData.runtimeType}');
          print('📦 Raw data: $rawData');

          List<dynamic> groupIdList = [];
          if (rawData is List) {
            groupIdList = rawData;
          } else if (rawData is Map<String, dynamic>) {
            groupIdList = rawData['groups'] ?? rawData['group_ids'] ?? rawData['data'] ?? [];
          }

          print('✅ Đã tìm thấy ${groupIdList.length} nhóm: $groupIdList');

          for (var i = 0; i < groupIdList.length; i++) {
            try {
              var idItem = groupIdList[i];
              print('\n🔄 Đang xử lý nhóm ${i + 1}/${groupIdList.length}');
              print('   ID item: $idItem (type: ${idItem.runtimeType})');

              int groupId = 0;
              if (idItem is int) {
                groupId = idItem;
              } else if (idItem is Map<String, dynamic>) {
                groupId = idItem['group_id'] ?? 0;
              } else {
                groupId = int.tryParse(idItem.toString()) ?? 0;
              }
              
              if (groupId == 0) {
                print('   ⚠️ Group ID = 0, bỏ qua');
                continue;
              }
            
            print('   ✓ Group ID hợp lệ: $groupId');

            final detailUri = Uri.parse('${ApiConfig.baseUrl}/groups/$groupId/detail');
            print('   📡 Gọi detail API: $detailUri');
            
            final detailResponse = await http.get(
              detailUri,
              headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer $_accessToken",
              },
            );

            String groupName = 'Nhóm chat';
            String? groupImageUrl;
            Map<String, dynamic> groupDetail = {'id': groupId}; 

            print('   📥 Detail response status: ${detailResponse.statusCode}');
            
            if (detailResponse.statusCode == 200) {
              groupDetail = jsonDecode(utf8.decode(detailResponse.bodyBytes)) as Map<String, dynamic>;
              groupName = groupDetail['name']?.toString() ?? 'Nhóm chat';
              groupImageUrl = groupDetail['group_image_url']?.toString();
              print('   ✓ Tên nhóm: $groupName');
              print('   ✓ Image URL: $groupImageUrl');
            } else {
              print('   ⚠️ Không lấy được detail, dùng tên mặc định');
            }

            final historyUri = Uri.parse('${ApiConfig.baseUrl}/chat/$groupId/history');
            print('   📡 Gọi history API: $historyUri');
            
            final historyResponse = await http.get(
              historyUri,
              headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer $_accessToken",
              },
            );

            String messagePreview = 'Bắt đầu cuộc trò chuyện';
            String timeStr = '';
            bool hasUnseenMessages = false;

            print('   📥 History response status: ${historyResponse.statusCode}');
            
            if (historyResponse.statusCode == 200) {
              final List<dynamic> messages = jsonDecode(utf8.decode(historyResponse.bodyBytes));
              print('   ✓ Số tin nhắn: ${messages.length}');

              if (messages.isNotEmpty) {
                final lastMsg = messages.last as Map<String, dynamic>;
                print('   ✓ Tin nhắn cuối: ${lastMsg['content']}');

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
                    messagePreview = isMyMessage ? 'Bạn: $content' : content;
                  }
                }

                hasUnseenMessages = !isMyMessage;
              }
            } else {
              print('   ⚠️ Không lấy được history');
            }

            print('   ➕ Thêm nhóm vào danh sách');
            conversations.add(ConversationItem(
              sender: groupName,
              message: messagePreview,
              time: timeStr,
              isOnline: true,
              isAiChat: false,
              hasUnseenMessages: hasUnseenMessages,
              groupImageUrl: groupImageUrl,
              groupData: groupDetail,
            ));
            
            print('   ✅ Tổng conversations hiện tại: ${conversations.length}');
            } catch (e, stackTrace) {
              print('   ❌ Lỗi khi xử lý nhóm $i: $e');
              print('   ❌ Stack trace: $stackTrace');
              continue;
            }
          }
          
          print('\n📊 Hoàn thành! Tổng cộng ${conversations.length} conversations (bao gồm AI Chat)');
        } else {
          print('❌ API trả về status code: ${response.statusCode}');
          print('❌ Response body: ${response.body}');
        }
      } catch (e, stackTrace) {
        print('❌ Lỗi load danh sách nhóm: $e');
        print('❌ Stack trace: $stackTrace');
      }
    } else {
      print('⚠️ Không có access token');
    }

    print('\n🎯 Trước khi setState: ${conversations.length} conversations');
    
    setState(() {
      _conversations = conversations;
      _isLoading = false;
    });
    
    print('🎯 Sau setState: $_conversations có ${_conversations.length} items');
    print('🎯 _isLoading = $_isLoading');
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
                            ? const Center(child: CircularProgressIndicator(color: Color(0xFFC69A61)))
                            : _conversations.isEmpty
                                ? RefreshIndicator(
                                    onRefresh: _handleRefresh,
                                    color: const Color(0xFFC69A61),
                                    child: SingleChildScrollView(
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      child: SizedBox(
                                        height: MediaQuery.of(context).size.height * 0.6,
                                        child: Center(
                                          child: Text('no_conversation_yet'.tr(), style: const TextStyle(fontSize: 16, color: Colors.grey)),
                                        ),
                                      ),
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: _handleRefresh,
                                    color: const Color(0xFFC69A61),
                                    child: ListView.separated(
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      itemCount: _conversations.length,
                                      separatorBuilder: (_, __) => SizedBox(height: spacing),
                                      itemBuilder: (context, index) {
                                        final conv = _conversations[index];
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