import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../services/auth_service.dart';
import '../config/api_config.dart';
import '../models/message.dart';
import 'member_screen(Host).dart' as host;
import 'member_screen(Member).dart' as member;

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
  final ImagePicker _imagePicker = ImagePicker();
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isUploading = false;
  String? _accessToken;
  String? _currentUserId;
  WebSocketChannel? _channel;
  Map<String, String?> _userAvatars = {};
  String? _myAvatarUrl;
  Map<String, Map<String, dynamic>> _groupMembers = {};
  bool _isAutoScrolling = false;
  String _groupName = '';
  String? _groupImageUrl;

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

    _scrollController.addListener(() {
      if (_isAutoScrolling) return;
      if (_scrollController.hasClients) {
        final currentPosition = _scrollController.position.pixels;
        final maxScroll = _scrollController.position.maxScrollExtent;
        final distanceFromBottom = maxScroll - currentPosition;

        print('📜 Scroll - distance from bottom: ${distanceFromBottom.toStringAsFixed(1)}px');

        if (distanceFromBottom < 50) {
          print('📜 User scrolled near bottom, marking messages as seen...');
          _markAllAsSeen();
        }
      }
    });
  }

  Future<void> _loadAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _currentUserId = prefs.getString('user_id');

    print('🔍 ===== SHARED PREFERENCES DEBUG =====');
    print('🔍 All keys: ${prefs.getKeys()}');
    print('🔍 Access Token exists: ${_accessToken != null}');
    print('🔍 Current User ID: "$_currentUserId"');
    print('🔍 ====================================');

    if (_accessToken != null) {
      await _loadMyProfile();
      await _loadGroupMembers();
      await _loadChatHistory();
      _connectWebSocket();
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('chat_error_no_token'.tr())),
      );
    }
  }

  bool _isSenderMe(String? senderId) {
    if (senderId == null || _currentUserId == null) return false;
    return senderId.toString().trim() == _currentUserId!.toString().trim();
  }

  Future<void> _loadMyProfile() async {
    if (_accessToken == null) return;

    try {
      final url = ApiConfig.getUri(ApiConfig.userProfile);
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_accessToken",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _myAvatarUrl = data['avatar_url'] as String?;
        });
        print('✅ My avatar loaded: $_myAvatarUrl');
      }
    } catch (e) {
      print('❌ Error loading my profile: $e');
    }
  }

  Future<void> _loadGroupMembers() async {
    if (_accessToken == null) return;

    try {
      final url = ApiConfig.getUri(ApiConfig.myGroup);
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_accessToken",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> members = data['members'] ?? [];

        for (var member in members) {
          final profileUuid = member['profile_uuid'] as String?;
          final avatarUrl = member['avatar_url'] as String?;
          if (profileUuid != null) {
            _groupMembers[profileUuid] = member;
            _userAvatars[profileUuid] = avatarUrl;
          }
        }

        print('✅ Group members loaded: ${_groupMembers.length} members');
        print('✅ User avatars: $_userAvatars');
      }
    } catch (e) {
      print('❌ Error loading group members: $e');
    }
  }

  void _markAllAsSeen() {
    if (_messages.isEmpty) return;

    bool hasUnseen = false;
    int unseenCount = 0;
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (!_messages[i].isSeen && !_messages[i].isUser) {
        hasUnseen = true;
        unseenCount++;
      }
    }

    print('👁️ _markAllAsSeen called - hasUnseen: $hasUnseen, unseenCount: $unseenCount');

    if (!hasUnseen) return;

    setState(() {
      _messages = _messages.map((msg) {
        if (!msg.isUser && !msg.isSeen) {
          print('✅ Marking message as SEEN: "${msg.message}"');
          return Message(
            sender: msg.sender,
            message: msg.message,
            time: msg.time,
            isOnline: msg.isOnline,
            isUser: msg.isUser,
            imageUrl: msg.imageUrl,
            messageType: msg.messageType,
            senderAvatarUrl: msg.senderAvatarUrl,
            isSeen: true,
          );
        }
        return msg;
      }).toList();
    });
  }

  Future<String?> _fetchUserAvatar(String userId) async {
    if (_accessToken == null) return null;

    if (_userAvatars.containsKey(userId)) {
      return _userAvatars[userId];
    }

    if (_groupMembers.containsKey(userId)) {
      final avatarUrl = _groupMembers[userId]!['avatar_url'] as String?;
      _userAvatars[userId] = avatarUrl;
      return avatarUrl;
    }

    _userAvatars[userId] = null;
    return null;
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

        final Set<String> senderIds = {};
        for (var msg in data) {
          final senderId = msg['sender_id']?.toString();
          if (senderId != null && senderId.isNotEmpty && senderId != _currentUserId) {
            senderIds.add(senderId);
          }
        }

        await Future.wait(
          senderIds.map((id) => _fetchUserAvatar(id))
        );

        setState(() {
          _messages = data.map((msg) {
            final createdAtUtc = DateTime.parse(msg['created_at']);
            final createdAtLocal = createdAtUtc.toLocal();
            final timeStr = DateFormat('HH:mm').format(createdAtLocal);
            final senderId = msg['sender_id'] ?? '';

            print('\n🔍 ===== MESSAGE DEBUG =====');
            print('🔍 Current User ID: "$_currentUserId"');
            print('🔍 Sender ID: "$senderId"');
            print('🔍 isSenderMe? ${_isSenderMe(senderId)}');
            print('🔍 Message content: "${msg['content']}"');

            final isUser = _isSenderMe(senderId);

            print('🔍 Result isUser: $isUser');
            print('🔍 Will display on: ${isUser ? "RIGHT (bên phải)" : "LEFT (bên trái)"}');
            print('🔍 =========================\n');

            final senderAvatarUrl = isUser ? null : _userAvatars[senderId];

            return Message(
              sender: senderId,
              message: msg['content'] ?? '',
              time: timeStr,
              isOnline: true,
              isUser: isUser,
              imageUrl: msg['image_url'],
              messageType: msg['message_type'] ?? 'text',
              senderAvatarUrl: senderAvatarUrl,
              isSeen: isUser,
            );
          }).toList();
          _isLoading = false;
        });

        if (data.isNotEmpty) {
          final lastMessageId = data.last['id']?.toString();
          if (lastMessageId != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('last_seen_message_id', lastMessageId);
            print('💾 Saved last_seen_message_id: $lastMessageId');
          }
        }

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

  void _connectWebSocket() {
    if (_accessToken == null) return;

    try {
      final wsUrl = '${ApiConfig.chatWebSocket}?token=$_accessToken';
      print('🔌 Connecting to WebSocket: $wsUrl');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        (message) {
          print('📥 WebSocket received: $message');
          _handleWebSocketMessage(message);
        },
        onError: (error) {
          print('❌ WebSocket error: $error');
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              _connectWebSocket();
            }
          });
        },
        onDone: () {
          print('🔌 WebSocket connection closed');
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              _connectWebSocket();
            }
          });
        },
      );
    } catch (e) {
      print('❌ Error connecting WebSocket: $e');
    }
  }

  Future<void> _handleWebSocketMessage(dynamic message) async {
    try {
      final data = jsonDecode(message);

      if (data.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'])),
        );
        return;
      }

      final createdAtUtc = DateTime.parse(data['created_at']);
      final createdAtLocal = createdAtUtc.toLocal();
      final timeStr = DateFormat('HH:mm').format(createdAtLocal);
      final senderId = data['sender_id'] ?? '';
      final isUser = _isSenderMe(senderId);

      if (!isUser && !_userAvatars.containsKey(senderId)) {
        _fetchUserAvatar(senderId);
      }

      final senderAvatarUrl = isUser ? null : _userAvatars[senderId];

      final newMessage = Message(
        sender: senderId,
        message: data['content'] ?? '',
        time: timeStr,
        isOnline: true,
        isUser: isUser,
        imageUrl: data['image_url'],
        messageType: data['message_type'] ?? 'text',
        senderAvatarUrl: senderAvatarUrl,
        isSeen: isUser,
      );

      print('📬 NEW MESSAGE - isUser: $isUser, isSeen: ${newMessage.isSeen}, content: "${newMessage.message}"');

      setState(() {
        _messages.add(newMessage);
      });

      final messageId = data['id']?.toString();
      if (messageId != null && _scrollController.hasClients) {
        final currentPosition = _scrollController.position.pixels;
        final maxScroll = _scrollController.position.maxScrollExtent;

        if (maxScroll - currentPosition < 200) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('last_seen_message_id', messageId);
          print('💾 Saved last_seen_message_id from WebSocket: $messageId');
        }
      }

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (_scrollController.hasClients) {
          final currentPosition = _scrollController.position.pixels;
          final maxScroll = _scrollController.position.maxScrollExtent;

          if (maxScroll - currentPosition < 200) {
            try {
              _isAutoScrolling = true;
              await _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
              );
            } finally {
              _isAutoScrolling = false;
            }
          }
        }
      });
    } catch (e) {
      print('❌ Error handling WebSocket message: $e');
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _channel == null) return;

    try {
      _channel!.sink.add(jsonEncode({
        "message_type": "text",
        "content": text,
      }));

      _controller.clear();

      print('📤 Message sent via WebSocket');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'chat_error_send'.tr()}: $e')),
      );
    }
  }

  Future<void> _showImageSourceSelection() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Color(0xFFB99668)),
                  title: const Text('Chụp ảnh'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndSendImage(source: ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Color(0xFFB99668)),
                  title: const Text('Chọn từ thư viện'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndSendImage(source: ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String?> _uploadImageToSupabase(File imageFile) async {
    try {
      final fileBytes = await imageFile.readAsBytes();
      const supabaseUrl = ApiConfig.supabaseUrl;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';

      final uploadUrl = Uri.parse('$supabaseUrl/storage/v1/object/chat_images/$fileName');

      print('📤 Uploading image to: $uploadUrl');

      final response = await http.post(
        uploadUrl,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'image/jpeg',
          'apikey': ApiConfig.supabaseAnonKey,
        },
        body: fileBytes,
      );

      print('📤 Upload status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final publicUrl = '$supabaseUrl/storage/v1/object/public/chat_images/$fileName';
        print('✅ Image uploaded: $publicUrl');
        return publicUrl;
      } else {
        print('❌ Upload failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Upload error: $e');
      return null;
    }
  }

  Future<void> _pickAndSendImage({ImageSource source = ImageSource.gallery}) async {
    if (_channel == null) return;

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploading = true;
      });

      final imageFile = File(pickedFile.path);
      final imageUrl = await _uploadImageToSupabase(imageFile);

      if (imageUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Upload ảnh thất bại')),
          );
        }
        return;
      }

      _channel!.sink.add(jsonEncode({
        "message_type": "image",
        "image_url": imageUrl,
      }));

      print('📤 Image message sent via WebSocket');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi gửi ảnh: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _navigateToMembersScreen() async {
    _accessToken = await AuthService.getValidAccessToken();

    try {
      final groupUrl = ApiConfig.getUri(ApiConfig.myGroup);
      final groupResponse = await http.get(
        groupUrl,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_accessToken",
        },
      );

      if (groupResponse.statusCode != 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lỗi load thông tin nhóm')),
          );
        }
        return;
      }

      final groupData = jsonDecode(utf8.decode(groupResponse.bodyBytes));
      
      final groupName = groupData['name']?.toString() ?? 'Unknown Group';
      final currentMembers = groupData['member_count'] as int? ?? 0;
      final maxMembers = groupData['max_members'] as int? ?? 0;

      String? currentUserRole;
      final List<dynamic> membersList = groupData['members'] ?? [];
      
      for (var memberData in membersList) {
        final profileUuid = memberData['profile_uuid']?.toString();
        if (profileUuid == _currentUserId) {
          currentUserRole = memberData['role']?.toString();
          print('✅ Found current user role: $currentUserRole');
          break;
        }
      }

      final List<host.Member> ownerMembers = [];
      final List<member.Member> memberMembers = [];
      for (var memberData in membersList) {
        try {
          final profileUuid = memberData['profile_uuid']?.toString();
          final fullname = memberData['fullname']?.toString();
          final email = memberData['email']?.toString();
          final avatarUrl = memberData['avatar_url']?.toString();

          if (profileUuid == null || profileUuid.isEmpty) {
            continue;
          }

          if (currentUserRole?.toLowerCase() == 'owner') {
            ownerMembers.add(host.Member(
              id: profileUuid,
              name: fullname ?? 'Unknown',
              email: email ?? 'no-email@example.com',
              avatarUrl: avatarUrl,
            ));
          } else {
            memberMembers.add(member.Member(
              id: profileUuid,
              name: fullname ?? 'Unknown',
              email: email ?? 'no-email@example.com',
              avatarUrl: avatarUrl ?? '',
            ));
          }
        } catch (e) {
          print('⚠️ Error parsing member: $e');
          continue; 
        }
      }

      if (mounted) {
        if (currentUserRole?.toLowerCase() == 'owner') {
          print('🚀 Navigating to MemberScreenHost (Owner)');
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => host.MemberScreenHost(
                groupName: groupName,
                currentMembers: currentMembers,
                maxMembers: maxMembers,
                members: ownerMembers,
              ),
            ),
          );
        } else {
          print('🚀 Navigating to MemberScreenMember (Member)');
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => member.MemberScreenMember(
                groupName: groupName,
                currentMembers: currentMembers,
                maxMembers: maxMembers,
                members: memberMembers,
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error loading members: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi load thành viên: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _channel?.sink.close(status.normalClosure);
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
              _groupName.isNotEmpty ? _groupName : 'chat_title'.tr(),
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
            onPressed: _navigateToMembersScreen,
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
          const double inputBarHeight = 56.0;
          return Stack(
            children: [
              Column(
                children: [
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
                                  return _MessageBubble(
                                    message: m,
                                    senderAvatarUrl: m.senderAvatarUrl,
                                    currentUserId: _currentUserId,
                                  );
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

              Positioned(
                left: 0,
                right: 0,
                bottom: bottomInset,
                child: SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    color: Colors.white,
                    child: Row(
                      children: [
                        Material(
                          color: const Color(0xFFB99668),
                          shape: const CircleBorder(),
                          child: IconButton(
                            icon: _isUploading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add_photo_alternate, color: Colors.white),
                            onPressed: _isUploading ? null : _showImageSourceSelection,
                          ),
                        ),
                        const SizedBox(width: 8),
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
  final String? senderAvatarUrl;
  final String? currentUserId;

  const _MessageBubble({
    Key? key,
    required this.message,
    this.senderAvatarUrl,
    this.currentUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isUser = (currentUserId != null && currentUserId!.isNotEmpty)
        ? (message.sender.toString().trim().toLowerCase() == currentUserId!.toString().trim().toLowerCase())
        : message.isUser;
    final bubbleColor = isUser ? const Color(0xFF8A724C) : const Color(0xFFB99668);
    final textColor = Colors.white;
    final showAvatar = !isUser;
    print('🖼️ MessageBubble - isUser: $isUser, isSeen: ${message.isSeen}, sender: ${message.sender}, content: "${message.message}"');
    print('🖼️ Should show BOLD: ${!isUser && !message.isSeen}');
    print('🖼️ Should show avatar: $showAvatar, avatarUrl: $senderAvatarUrl');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (showAvatar) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFD9CBB3),
                backgroundImage: senderAvatarUrl != null && senderAvatarUrl!.isNotEmpty
                    ? NetworkImage(senderAvatarUrl!)
                    : null,
                child: senderAvatarUrl == null || senderAvatarUrl!.isEmpty
                    ? const Icon(Icons.person, size: 24, color: Colors.white)
                    : null,
              ),
            ),
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
                  if (message.messageType == 'image' && message.imageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        message.imageUrl!,
                        fit: BoxFit.cover,
                        width: MediaQuery.of(context).size.width * 0.6,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: MediaQuery.of(context).size.width * 0.6,
                            height: 200,
                            color: Colors.grey[300],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                                color: bubbleColor,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: MediaQuery.of(context).size.width * 0.6,
                            height: 200,
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                    if (message.message.isNotEmpty) const SizedBox(height: 8),
                  ],
                  if (message.message.isNotEmpty)
                    Text(
                      message.message,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: !isUser && !message.isSeen
                          ? FontWeight.bold
                          : FontWeight.normal,
                      ),
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
        ],
      ),
    );
  }
}

class PendingRequest {
  final String id;
  final String name;
  final String email;
  final DateTime requestedAt;
  final double rating;
  final List<String> keywords;
  
  PendingRequest({
    required this.id,
    required this.name,
    required this.email,
    required this.requestedAt,
    this.rating = 0.0,
    this.keywords = const [],
  });
}