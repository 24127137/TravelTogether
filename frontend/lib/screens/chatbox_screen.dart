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
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
import '../config/api_config.dart';
import '../models/message.dart';
import 'host_member_screen.dart';
=======
import 'package:web_socket_channel/status.dart' as status;
import '../services/auth_service.dart';
import '../config/api_config.dart';
import '../models/message.dart';
import 'member_screen(Host).dart' as host;
import 'member_screen(Member).dart' as member;
>>>>>>> 3ee7efe (done all groupapis)
=======
import 'package:web_socket_channel/status.dart' as status;
import '../services/auth_service.dart';
import '../config/api_config.dart';
import '../models/message.dart';
import 'member_screen(Host).dart' as host;
import 'member_screen(Member).dart' as member;
>>>>>>> 274291d (update)

//màn hình lúc chat
class ChatboxScreen extends StatefulWidget {
  const ChatboxScreen({Key? key}) : super(key: key);

  // === THÊM MỚI: Getter public để notification service có thể check ===
=======
import 'package:web_socket_channel/io.dart';
import '../services/auth_service.dart';
import '../services/chat_system_message_service.dart';
import '../services/chat_cache_service.dart';
import '../config/api_config.dart';
import '../models/message.dart';
import '../widgets/optimized_list_widget.dart';
import 'host_member_screen.dart' as host;
import 'member_screen.dart' as member;
import 'map_route_screen.dart';

//màn hình lúc chat
class ChatboxScreen extends StatefulWidget {
  final Map<String, dynamic>? groupData;
  const ChatboxScreen({Key? key, this.groupData}) : super(key: key);

  // : Getter public để notification service có thể check 
>>>>>>> week10
  static bool get isCurrentlyInChatScreen => _ChatboxScreenState.isInChatScreen;

  @override
  _ChatboxScreenState createState() => _ChatboxScreenState();
}

class _ChatboxScreenState extends State<ChatboxScreen> with WidgetsBindingObserver {
<<<<<<< HEAD
  static bool isInChatScreen = false; // === THÊM MỚI: Track xem có đang ở trong chat screen không ===
=======
  static bool isInChatScreen = false; // : Track xem có đang ở trong chat screen không 
>>>>>>> week10

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
<<<<<<< HEAD
<<<<<<< HEAD
  final ImagePicker _imagePicker = ImagePicker(); // === THÊM MỚI: ImagePicker ===
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isUploading = false; // === THÊM MỚI: Trạng thái upload ===
  String? _accessToken;
  String? _currentUserId; // UUID của user hiện tại (lấy từ SharedPreferences khi login)
  WebSocketChannel? _channel; // === THÊM MỚI: WebSocket channel ===
  Map<String, String?> _userAvatars = {}; // === THÊM MỚI: Cache avatar của users ===
  String? _myAvatarUrl; // === THÊM MỚI: Avatar của mình ===
  Map<String, Map<String, dynamic>> _groupMembers = {}; // === THÊM MỚI: Lưu thông tin members từ group ===
  bool _isAutoScrolling = false; // === THÊM MỚI: Cờ để tránh mark seen khi auto scroll ===
  Map<int, GlobalKey> _messageKeys = {}; // === THÊM MỚI: keys per message for ensureVisible ===
  bool _showScrollToBottomButton = false; // === THÊM MỚI: Hiển thị nút scroll xuống ===
<<<<<<< HEAD
=======
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
>>>>>>> 3ee7efe (done all groupapis)
=======
  String _groupName = ''; // === THÊM MỚI: Tên nhóm ===
  String? _groupImageUrl; // === THÊM MỚI: Ảnh nhóm ===
>>>>>>> 274291d (update)
=======
  final ImagePicker _imagePicker = ImagePicker(); // : ImagePicker 
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isUploading = false; // : Trạng thái upload 
  String? _accessToken;
  String? _currentUserId; // UUID của user hiện tại (lấy từ SharedPreferences khi login)
  String? _groupId;
  WebSocketChannel? _channel; // : WebSocket channel 
  Map<String, String?> _userAvatars = {}; // : Cache avatar của users 
  Map<String, String?> _userNames = {}; // : Cache tên của users 
  String? _myAvatarUrl; // : Avatar của mình 
  String? _groupAvatarUrl; // : Avatar của nhóm 
  String? _groupName; // : Tên nhóm 
  Map<String, Map<String, dynamic>> _groupMembers = {}; // : Lưu thông tin members từ group 
  bool _isAutoScrolling = false; // : Cờ để tránh mark seen khi auto scroll 
  Map<int, GlobalKey> _messageKeys = {}; // : keys per message for ensureVisible 
  bool _showScrollToBottomButton = false; // : Hiển thị nút scroll xuống 
>>>>>>> week10

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
<<<<<<< HEAD
    isInChatScreen = true; // === THÊM MỚI: Đánh dấu đang ở trong chat screen ===
    WidgetsBinding.instance.addObserver(this); // === THÊM MỚI: Lắng nghe lifecycle ===

=======
>>>>>>> 3ee7efe (done all groupapis)
    _loadAccessToken();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        // === SỬA: Thêm delay để đợi keyboard mở hoàn toàn ===
=======
    isInChatScreen = true; // : Đánh dấu đang ở trong chat screen 
    WidgetsBinding.instance.addObserver(this); // : Lắng nghe lifecycle 

    if (widget.groupData != null) {
      _groupId = widget.groupData!['id']?.toString() ??
          widget.groupData!['group_id']?.toString();
    }

    // : Nếu không có groupData, đọc từ SharedPreferences 
    _initGroupId();

    _loadAccessToken();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        //  SỬA: Thêm delay để đợi keyboard mở hoàn toàn 
>>>>>>> week10
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollController.hasClients && mounted) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

<<<<<<< HEAD
<<<<<<< HEAD
    // === SỬA ĐỔI: Lắng nghe scroll để mark messages as seen VÀ hiển thị nút scroll-to-bottom ===
=======
    //  SỬA ĐỔI: Lắng nghe scroll để mark messages as seen VÀ hiển thị nút scroll-to-bottom 
>>>>>>> week10
    _scrollController.addListener(() {
      // Logic hiển thị/ẩn nút scroll-to-bottom
      if (_scrollController.position.pixels < _scrollController.position.maxScrollExtent - 200) {
        if (!_showScrollToBottomButton) {
          setState(() {
            _showScrollToBottomButton = true;
          });
        }
      } else {
        if (_showScrollToBottomButton) {
          setState(() {
            _showScrollToBottomButton = false;
          });
        }
      }

      // If we are auto-scrolling (programmatic), don't trigger seen logic
<<<<<<< HEAD
=======
    _scrollController.addListener(() {
>>>>>>> 3ee7efe (done all groupapis)
=======
>>>>>>> week10
      if (_isAutoScrolling) return;
      if (_scrollController.hasClients) {
        final currentPosition = _scrollController.position.pixels;
        final maxScroll = _scrollController.position.maxScrollExtent;
        final distanceFromBottom = maxScroll - currentPosition;

<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> week10
        // Debug log
        print('📜 Scroll - distance from bottom: ${distanceFromBottom.toStringAsFixed(1)}px');

        // Nếu scroll gần đến cuối (trong vòng 50px), mark tất cả là seen
<<<<<<< HEAD
=======
        print('📜 Scroll - distance from bottom: ${distanceFromBottom.toStringAsFixed(1)}px');

>>>>>>> 3ee7efe (done all groupapis)
=======
>>>>>>> week10
        if (distanceFromBottom < 50) {
          print('📜 User scrolled near bottom, marking messages as seen...');
          _markAllAsSeen();
        }
      }
    });
  }

<<<<<<< HEAD
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
=======
  // : Đọc group_id từ SharedPreferences nếu không có groupData 
  Future<void> _initGroupId() async {
    if (_groupId == null) {
      final prefs = await SharedPreferences.getInstance();
      final cachedGroupId = prefs.getString('cached_group_id');
      if (cachedGroupId != null && cachedGroupId.isNotEmpty) {
        print('📦 Loaded cached_group_id from SharedPreferences: $cachedGroupId');
        setState(() {
          _groupId = cachedGroupId;
        });
>>>>>>> week10
      }
    }
  }

  @override
  void dispose() {
<<<<<<< HEAD
<<<<<<< HEAD
    isInChatScreen = false; // === THÊM MỚI: Đánh dấu đã rời khỏi chat screen ===
    WidgetsBinding.instance.removeObserver(this); // === THÊM MỚI: Xóa lifecycle observer ===

    // === THÊM MỚI: Lưu last_seen_message_id khi rời khỏi màn hình ===
    _saveLastSeenMessage();

    // Đóng WebSocket connection
    _channel?.sink.close(status.normalClosure);

    // Clean up controllers
=======
    _channel?.sink.close(status.normalClosure);
>>>>>>> 3ee7efe (done all groupapis)
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.removeListener(() {});
=======
    isInChatScreen = false; // : Đánh dấu đã rời khỏi chat screen 
    WidgetsBinding.instance.removeObserver(this); // : Xóa lifecycle observer 

    // : Lưu last_seen_message_id khi rời khỏi màn hình 
    _saveLastSeenMessage();

    // Đóng WebSocket connection
    _channel?.sink.close();

    // Clean up controllers
    _controller.dispose();
    _scrollController.dispose();
>>>>>>> week10
    _focusNode.dispose();

    super.dispose();
  }

<<<<<<< HEAD
  // === THÊM MỚI: Lưu ID của tin nhắn cuối cùng khi rời khỏi màn hình ===
  Future<void> _saveLastSeenMessage() async {
    if (_messages.isEmpty) return;

=======
  // : Lưu ID của tin nhắn cuối cùng khi rời khỏi màn hình 
  Future<void> _saveLastSeenMessage() async {
    if (_messages.isEmpty) return;
    if (_groupId == null) return; // Cần groupId để gọi API
>>>>>>> week10

    // Tìm ID của tin nhắn từ server (cần load lại từ history)
    try {
      final prefs = await SharedPreferences.getInstance();
<<<<<<< HEAD
      final url = ApiConfig.getUri(ApiConfig.chatHistory);
=======
      final url = ApiConfig.getUri(ApiConfig.chatHistoryByGroup(_groupId!));
>>>>>>> week10
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
          final lastMessageId = messages.last['id']?.toString();
          if (lastMessageId != null) {
<<<<<<< HEAD
            await prefs.setString('last_seen_message_id', lastMessageId);
            print('💾 Saved last_seen_message_id on dispose: $lastMessageId');
=======
            // Sử dụng key theo group để match với notification_screen
            await prefs.setString('last_seen_message_id_$_groupId', lastMessageId);
            print('💾 Saved last_seen_message_id_$_groupId on dispose: $lastMessageId');
>>>>>>> week10
          }
        }
      }
    } catch (e) {
      print('❌ Error saving last_seen_message_id: $e');
    }
  }

  Future<void> _loadAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _currentUserId = prefs.getString('user_id'); // Lấy user_id (UUID) đã lưu khi login

    // DEBUG: Kiểm tra SharedPreferences
<<<<<<< HEAD
    print('🔍 ===== SHARED PREFERENCES DEBUG =====');
    print('🔍 All keys: ${prefs.getKeys()}');
    print('🔍 Access Token exists: ${_accessToken != null}');
    print('🔍 Current User ID: "$_currentUserId"');
    print('🔍 ====================================');

    if (_accessToken != null) {
      await _loadMyProfile(); // Load avatar của mình
      await _loadGroupMembers(); // === THÊM MỚI: Load members từ group ===
      await _loadChatHistory();
      _connectWebSocket(); // === THÊM MỚI: Kết nối WebSocket sau khi load history ===
=======
    print('🔍 == SHARED PREFERENCES DEBUG ==');
    print('🔍 All keys: ${prefs.getKeys()}');
    print('🔍 Access Token exists: ${_accessToken != null}');
    print('🔍 Current User ID: "$_currentUserId"');
    print('🔍 ');

    if (_accessToken != null) {
      await _loadMyProfile(); // Load avatar của mình
      await _loadGroupMembers(); // : Load members từ group 
      await _loadChatHistory();
      _connectWebSocket(); // : Kết nối WebSocket sau khi load history 
>>>>>>> week10
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('chat_error_no_token'.tr())),
      );
    }
  }

<<<<<<< HEAD
  // === Helper kiểm tra senderId có phải là user hiện tại hay không ===
=======
  //  Helper kiểm tra senderId có phải là user hiện tại hay không 
>>>>>>> week10
  bool _isSenderMe(String? senderId) {
    if (senderId == null || _currentUserId == null) return false;
    // So sánh với currentUserId (đã lưu từ login)
    return senderId.toString().trim() == _currentUserId!.toString().trim();
  }

<<<<<<< HEAD
  // === THÊM MỚI: Format date separator như Messenger ===
=======
  // : Format date separator như Messenger 
>>>>>>> week10
  String? _getDateSeparator(int index) {
    if (index >= _messages.length) return null;

    final currentMsg = _messages[index];

    // Debug log
    print('📅 _getDateSeparator for index $index: createdAt = ${currentMsg.createdAt}');

    if (currentMsg.createdAt == null) {
      print('⚠️ Message at index $index has null createdAt!');
      return null;
    }

    final now = DateTime.now();
    final msgDate = currentMsg.createdAt!;

    print('📅 Current message date: ${msgDate.year}-${msgDate.month}-${msgDate.day} ${DateFormat('HH:mm').format(msgDate)}');

<<<<<<< HEAD
    // === Kiểm tra với tin nhắn TRƯỚC ĐÓ ===
=======
    //  Kiểm tra với tin nhắn TRƯỚC ĐÓ 
>>>>>>> week10
    // Messages được sort từ CŨ → MỚI, nên index 0 = cũ nhất
    bool shouldShowSeparator = false;

    if (index > 0) {
      // Có tin nhắn trước đó, kiểm tra xem có cùng ngày không
      final prevMsg = _messages[index - 1];
      if (prevMsg.createdAt != null) {
        final prevDate = prevMsg.createdAt!;
        print('📅 Previous message date: ${prevDate.year}-${prevDate.month}-${prevDate.day} ${DateFormat('HH:mm').format(prevDate)}');

        // Nếu KHÁC NGÀY với tin nhắn trước → PHẢI hiện separator
        if (msgDate.year != prevDate.year ||
            msgDate.month != prevDate.month ||
            msgDate.day != prevDate.day) {
          print('📅 ⚠️ DIFFERENT day from previous message! MUST show separator!');
          shouldShowSeparator = true;
        } else {
          print('📅 ✅ Same day as previous message, NO separator');
          return null; // Cùng ngày → không hiện separator
        }
      } else {
        // Tin trước không có createdAt, hiện separator cho tin này
        shouldShowSeparator = true;
      }
    } else {
      // Đây là tin nhắn ĐẦU TIÊN (index 0)
      print('📅 This is the FIRST message (index 0)');
      shouldShowSeparator = true; // Tin đầu tiên luôn hiện separator (trừ khi là hôm nay)
    }

<<<<<<< HEAD
    // === Nếu KHÔNG cần hiện separator → return null ===
=======
    //  Nếu KHÔNG cần hiện separator → return null 
>>>>>>> week10
    if (!shouldShowSeparator) {
      return null;
    }

<<<<<<< HEAD
    // === CẦN hiện separator → Format theo ngày ===
=======
    //  CẦN hiện separator → Format theo ngày 
>>>>>>> week10
    print('📅 Today: ${now.year}-${now.month}-${now.day}');

    final isToday = msgDate.year == now.year &&
        msgDate.month == now.month &&
        msgDate.day == now.day;

    print('📅 Is today: $isToday');

    // KHÔNG hiện separator cho hôm nay (theo kiểu Messenger)
    if (isToday) {
      print('📅 Message is today, NO separator (Messenger style)');
      return null;
    }

<<<<<<< HEAD
    // === Hiện separator cho ngày cũ hơn ===
=======
    //  Hiện separator cho ngày cũ hơn 
>>>>>>> week10
    final difference = now.difference(msgDate).inDays;
    print('📅 Difference in days: $difference');

    if (difference < 7 && difference >= 1) {
      // Trong tuần (1-6 ngày trước): "TH 2 LÚC 20:05"
      final weekday = _getVietnameseWeekday(msgDate.weekday);
      final time = DateFormat('HH:mm').format(msgDate);
      final separator = '$weekday LÚC $time';
      print('✅ Separator (this week): $separator');
      return separator;
    }

    // Cũ hơn 7 ngày: "13 THG 11 LÚC 20:05"
    final day = msgDate.day;
    final month = _getVietnameseMonth(msgDate.month);
    final time = DateFormat('HH:mm').format(msgDate);
    final separator = '$day $month LÚC $time';
    print('✅ Separator (older): $separator');
    return separator;
  }

  String _getVietnameseWeekday(int weekday) {
    switch (weekday) {
      case 1: return 'TH 2';
      case 2: return 'TH 3';
      case 3: return 'TH 4';
      case 4: return 'TH 5';
      case 5: return 'TH 6';
      case 6: return 'TH 7';
      case 7: return 'CN';
      default: return '';
    }
  }

  String _getVietnameseMonth(int month) {
    return 'THG $month';
  }

<<<<<<< HEAD
  // === THÊM MỚI: Kiểm tra có nên hiển thị avatar không (Message Grouping) ===
=======
  // : Kiểm tra có nên hiển thị TÊN người gửi không (tin nhắn ĐẦU TIÊN trong nhóm) 
  bool _shouldShowSenderName(int index) {
    if (index >= _messages.length) return false;

    final currentMsg = _messages[index];

    // Tin nhắn của mình không hiển thị tên
    if (_isSenderMe(currentMsg.sender)) return false;

    // Tin nhắn đầu tiên luôn hiển thị tên
    if (index == 0) return true;

    // Kiểm tra tin nhắn trước đó
    final prevMsg = _messages[index - 1];

    // Nếu người gửi khác nhau, hiển thị tên
    if (currentMsg.sender != prevMsg.sender) return true;

    // Nếu cùng người gửi, kiểm tra khoảng thời gian
    if (currentMsg.createdAt != null && prevMsg.createdAt != null) {
      final timeDiff = currentMsg.createdAt!.difference(prevMsg.createdAt!);
      // Nếu cách nhau > 2 phút, hiển thị tên
      if (timeDiff.inMinutes.abs() >= 2) return true;
    }

    // Không hiển thị tên (gộp với tin nhắn trước)
    return false;
  }

  //  Kiểm tra có nên hiển thị AVATAR không (tin nhắn CUỐI CÙNG trong nhóm) 
>>>>>>> week10
  bool _shouldShowAvatar(int index) {
    if (index >= _messages.length) return false;

    final currentMsg = _messages[index];

    // Tin nhắn của mình không hiển thị avatar
    if (_isSenderMe(currentMsg.sender)) return false;

    // Tin nhắn cuối cùng luôn hiển thị avatar
    if (index == _messages.length - 1) return true;

    // Kiểm tra tin nhắn tiếp theo
    final nextMsg = _messages[index + 1];

    // Nếu người gửi khác nhau, hiển thị avatar
    if (currentMsg.sender != nextMsg.sender) return true;

    // Nếu cùng người gửi, kiểm tra khoảng thời gian
    if (currentMsg.createdAt != null && nextMsg.createdAt != null) {
      final timeDiff = nextMsg.createdAt!.difference(currentMsg.createdAt!);
      // Nếu cách nhau > 2 phút, hiển thị avatar
      if (timeDiff.inMinutes >= 2) return true;
    }

    // Không hiển thị avatar (gộp với tin nhắn tiếp theo)
    return false;
  }

<<<<<<< HEAD
  // === THÊM MỚI: Load profile của mình để lấy avatar ===
=======
  // : Load profile của mình để lấy avatar 
>>>>>>> week10
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

<<<<<<< HEAD
  // === THÊM MỚI: Load thông tin members từ group để lấy avatar ===
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

        // === THÊM MỚI: Lưu tên nhóm và ảnh nhóm ===
        setState(() {
          _groupName = data['name']?.toString() ?? '';
          _groupImageUrl = data['image_url']?.toString();
        });

        // Cache avatar theo profile_uuid
        for (var member in members) {
          final profileUuid = member['profile_uuid'] as String?;
          final avatarUrl = member['avatar_url'] as String?;
          if (profileUuid != null) {
            _groupMembers[profileUuid] = member;
            _userAvatars[profileUuid] = avatarUrl;
          }
        }

        print('✅ Group members loaded: ${_groupMembers.length} members');
        print('✅ Group name: $_groupName');
        print('✅ User avatars: $_userAvatars');
      }
    } catch (e) {
      print('❌ Error loading group members: $e');
    }
  }

  // === THÊM MỚI: Mark tất cả tin nhắn là đã seen ===
=======
  Future<void> _loadGroupMembers() async {
    if (_accessToken == null) return;

    if (widget.groupData != null) {
      final group = widget.groupData!;
      final members = group['members'] ?? [];

      setState(() {
        _groupName = group['name']?.toString() ?? 'group_chat_default'.tr();
        _groupAvatarUrl = group['group_image_url']?.toString();
      });

      for (var member in members) {
        final uuid = member['profile_uuid']?.toString();
        final avatar = member['avatar_url']?.toString();
        final fullname = member['fullname']?.toString();
        if (uuid != null && uuid.isNotEmpty) {
          _groupMembers[uuid] = Map<String, dynamic>.from(member);
          _userAvatars[uuid] = avatar;
          _userNames[uuid] = fullname; // : Lưu tên 
        }
      }
      print('✅ Load nhóm thành công từ MessagesScreen: $_groupName');
      return;
    }

    try {
      final response = await http.get(
        ApiConfig.getUri(ApiConfig.myGroup),
        headers: {"Authorization": "Bearer $_accessToken"},
      );

      if (response.statusCode == 200) {
        final dynamic raw = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> list = raw is List ? raw : (raw is Map ? [raw] : []);

        if (list.isEmpty) {
          if (mounted) Navigator.of(context).pop();
          return;
        }

        final group = list[0];
        final members = group['members'] ?? [];

        setState(() {
          _groupName = group['name']?.toString() ?? 'Nhóm chat';
          _groupAvatarUrl = group['group_image_url']?.toString();
        });

        for (var member in members) {
          final uuid = member['profile_uuid']?.toString();
          final avatar = member['avatar_url']?.toString();
          final fullname = member['fullname']?.toString();
          if (uuid != null && uuid.isNotEmpty) {
            _groupMembers[uuid] = Map<String, dynamic>.from(member);
            _userAvatars[uuid] = avatar;
            _userNames[uuid] = fullname; // : Lưu tên 
          }
        }
      }
    } catch (e) {
      print('Load group fallback error: $e');
    }
  }

  // : Mark tất cả tin nhắn là đã seen 
>>>>>>> week10
  void _markAllAsSeen() {
    if (_messages.isEmpty) return;

    // Tìm tin nhắn cuối cùng chưa seen
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

    // Mark tất cả tin nhắn là seen
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
            isSeen: true, // Mark as seen
<<<<<<< HEAD
            createdAt: msg.createdAt, // === THÊM MỚI: Giữ nguyên createdAt ===
=======
            createdAt: msg.createdAt, // : Giữ nguyên createdAt 
>>>>>>> week10
          );
        }
        return msg;
      }).toList();
    });
  }

<<<<<<< HEAD
  // === THÊM MỚI: Load avatar của user khác ===
=======
  // : Load avatar của user khác 
>>>>>>> week10
  Future<String?> _fetchUserAvatar(String userId) async {
    if (_accessToken == null) return null;

    // Check cache trước
    if (_userAvatars.containsKey(userId)) {
      return _userAvatars[userId];
    }

    // Nếu không có trong cache, kiểm tra trong group members
    if (_groupMembers.containsKey(userId)) {
      final avatarUrl = _groupMembers[userId]!['avatar_url'] as String?;
      _userAvatars[userId] = avatarUrl;
      return avatarUrl;
    }

    // Không tìm thấy, trả về null (dùng default avatar)
    _userAvatars[userId] = null;
    return null;
  }

<<<<<<< HEAD
  Future<void> _loadChatHistory({bool silent = false}) async {
    if (_accessToken == null) return;
=======
  // : Helper method để xử lý messages data (dùng cho cả cache và server) 
  Future<void> _processMessagesData(List<dynamic> data) async {
    // Collect unique sender IDs để fetch avatars
    final Set<String> senderIds = {};
    for (var msg in data) {
      final senderId = msg['sender_id']?.toString();
      if (senderId != null && senderId.isNotEmpty && senderId != _currentUserId) {
        senderIds.add(senderId);
      }
    }

    // Fetch avatars for all senders (parallel)
    await Future.wait(senderIds.map((id) => _fetchUserAvatar(id)));

    if (!mounted) return;

    setState(() {
      _messages = data.map((msg) {
        final createdAtUtc = DateTime.parse(msg['created_at']);
        final createdAtLocal = createdAtUtc.toLocal();
        final timeStr = DateFormat('HH:mm').format(createdAtLocal);
        final senderId = msg['sender_id'] ?? '';
        var messageType = msg['message_type'] ?? 'text';
        //  SỬA: Lấy sender_name từ API, nếu không có thì lấy từ _userNames cache 
        var senderName = msg['sender_name']?.toString() ?? _userNames[senderId];
        var content = msg['content'] ?? '';

        // Parse system message từ content prefix
        final parsedSystem = ChatSystemMessageService.parseSystemMessage(content);
        if (parsedSystem != null) {
          messageType = parsedSystem['type']!;
          senderName = parsedSystem['name'];
          content = parsedSystem['display']!;
        }

        final isUser = _isSenderMe(senderId);
        final senderAvatarUrl = isUser ? null : _userAvatars[senderId];

        return Message(
          sender: senderId,
          message: content,
          time: timeStr,
          isOnline: true,
          isUser: isUser,
          imageUrl: msg['image_url'],
          messageType: messageType,
          senderAvatarUrl: senderAvatarUrl,
          isSeen: true,
          createdAt: createdAtLocal,
          senderName: senderName,
        );
      }).toList();
      _isLoading = false;
    });
  }

  Future<void> _loadChatHistory({bool silent = false}) async {
    if (_accessToken == null) return;
    if (_groupId == null) {
      print('❌ Error: groupId is null, cannot load chat history');
      setState(() {
        _isLoading = false;
      });
      return;
    }
>>>>>>> week10

    if (!silent) {
      setState(() {
        _isLoading = true;
      });
    }

<<<<<<< HEAD
    try {
      final url = ApiConfig.getUri(ApiConfig.chatHistory);
=======
    // : Load từ cache trước để hiển thị ngay 
    final cachedMessages = await ChatCacheService.getMessages(_groupId!);
    if (cachedMessages != null && cachedMessages.isNotEmpty) {
      print('⚡ Loading from cache first...');
      await _processMessagesData(cachedMessages);

      // Scroll to bottom ngay sau khi load cache
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }

    //  Load từ server (background) 
    try {
      final url = ApiConfig.getUri(ApiConfig.chatHistoryByGroup(_groupId!));
      print('📡 Loading chat history from server: $url');
>>>>>>> week10
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_accessToken",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

<<<<<<< HEAD
        // === THÊM MỚI: Collect unique sender IDs để fetch avatars ===
        final Set<String> senderIds = {};
        for (var msg in data) {
          final senderId = msg['sender_id']?.toString();
          if (senderId != null && senderId.isNotEmpty && senderId != _currentUserId) {
            senderIds.add(senderId);
          }
        }

        // === THÊM MỚI: Fetch avatars for all senders (parallel) ===
        await Future.wait(
            senderIds.map((id) => _fetchUserAvatar(id))
        );

        setState(() {
          _messages = data.map((msg) {
            // Parse UTC time và chuyển sang local time
            final createdAtUtc = DateTime.parse(msg['created_at']);
            final createdAtLocal = createdAtUtc.toLocal(); // Chuyển sang giờ địa phương
            final timeStr = DateFormat('HH:mm').format(createdAtLocal);
            final senderId = msg['sender_id'] ?? '';

            // === DEBUG: In ra createdAt để kiểm tra ===
            print('\n📅 ===== MESSAGE DATE DEBUG =====');
            print('📅 Message ID: ${msg['id']}');
            print('📅 Created At UTC: ${msg['created_at']}');
            print('📅 Created At Local: $createdAtLocal');
            print('📅 Date: ${createdAtLocal.year}-${createdAtLocal.month}-${createdAtLocal.day}');
            print('📅 Time: $timeStr');
            print('📅 Content: "${msg['content']}"');
            print('📅 ===============================\n');

            // DEBUG: In ra để kiểm tra CHI TIẾT
            print('\n🔍 ===== MESSAGE DEBUG =====');
            print('🔍 Current User ID: "$_currentUserId"');
            print('🔍 Sender ID: "$senderId"');
            print('🔍 isSenderMe? ${_isSenderMe(senderId)}');
            print('🔍 Message content: "${msg['content']}"');

            // So sánh sender_id với current user_id để phân biệt tin nhắn
            final isUser = _isSenderMe(senderId);

            print('🔍 Result isUser: $isUser');
            print('🔍 Will display on: ${isUser ? "RIGHT (bên phải)" : "LEFT (bên trái)"}');
            print('🔍 =========================\n');

            // === THÊM MỚI: Lấy avatar của sender từ cache ===
            final senderAvatarUrl = isUser ? null : _userAvatars[senderId];

            return Message(
              sender: senderId,
              message: msg['content'] ?? '',
              time: timeStr,
              isOnline: true,
              isUser: isUser, // Gán đúng giá trị isUser
              imageUrl: msg['image_url'], // === THÊM MỚI ===
              messageType: msg['message_type'] ?? 'text', // === THÊM MỚI ===
              senderAvatarUrl: senderAvatarUrl, // === THÊM MỚI ===
              isSeen: isUser, // === THÊM MỚI: Tin nhắn của mình luôn seen, tin nhắn người khác chưa seen ===
              createdAt: createdAtLocal, // === THÊM MỚI: Lưu thời gian tạo ===
            );
          }).toList();
          _isLoading = false;
        });

        // === THÊM MỚI: Lưu ID của tin nhắn cuối cùng để mark as seen ===
=======
        //  Lưu vào cache cho lần sau 
        await ChatCacheService.saveMessages(_groupId!, data);

        print('📡 Server returned ${data.length} messages');

        //  Xử lý messages data 
        await _processMessagesData(data);

        //  Lưu ID của tin nhắn cuối cùng để mark as seen 
>>>>>>> week10
        if (data.isNotEmpty) {
          final lastMessageId = data.last['id']?.toString();
          if (lastMessageId != null) {
            final prefs = await SharedPreferences.getInstance();
<<<<<<< HEAD
            await prefs.setString('last_seen_message_id', lastMessageId);
            print('💾 Saved last_seen_message_id: $lastMessageId');
=======
            await prefs.setString('last_seen_message_id_$_groupId', lastMessageId);
            print('💾 Saved last_seen_message_id_$_groupId: $lastMessageId');
>>>>>>> week10
          }
        }

        // Scroll to bottom after loading
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
<<<<<<< HEAD
=======
          _markAllAsSeen();
>>>>>>> week10
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

<<<<<<< HEAD
  // === THÊM MỚI: Kết nối WebSocket ===
  void _connectWebSocket() {
    if (_accessToken == null) return;

    try {
      // Tạo WebSocket URL với token
      final wsUrl = '${ApiConfig.chatWebSocket}?token=$_accessToken';
      print('🔌 Connecting to WebSocket: $wsUrl');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
=======
  // : Kết nối WebSocket 
  void _connectWebSocket() {
    if (_accessToken == null) return;
    if (_groupId == null) {
      print('❌ Error: groupId is null, cannot connect WebSocket');
      return;
    }

    try {
      // Tạo WebSocket URL với group_id
      final wsUrl = ApiConfig.chatWebSocketByGroup(_groupId!);
      print('🔌 Connecting to WebSocket: $wsUrl');

      // Sử dụng IOWebSocketChannel để gửi headers
      _channel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );
>>>>>>> week10

      // Lắng nghe tin nhắn từ server
      _channel!.stream.listen(
            (message) {
          print('📥 WebSocket received: $message');
          _handleWebSocketMessage(message);
        },
        onError: (error) {
          print('❌ WebSocket error: $error');
          // Tự động reconnect sau 3 giây
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              _connectWebSocket();
            }
          });
        },
        onDone: () {
          print('🔌 WebSocket connection closed');
          // Tự động reconnect sau 3 giây
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

<<<<<<< HEAD
  // === THÊM MỚI: Xử lý tin nhắn nhận từ WebSocket ===
=======
  // : Xử lý tin nhắn nhận từ WebSocket 
>>>>>>> week10
  Future<void> _handleWebSocketMessage(dynamic message) async {
    try {
      final data = jsonDecode(message);

      // Nếu là error message
      if (data.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'])),
        );
        return;
      }

      // Parse tin nhắn mới
      final createdAtUtc = DateTime.parse(data['created_at']);
      final createdAtLocal = createdAtUtc.toLocal();
      final timeStr = DateFormat('HH:mm').format(createdAtLocal);
      final senderId = data['sender_id'] ?? '';
<<<<<<< HEAD
      final isUser = _isSenderMe(senderId);

      // Fetch avatar nếu là người khác
      if (!isUser && !_userAvatars.containsKey(senderId)) {
        _fetchUserAvatar(senderId);
      }

      final senderAvatarUrl = isUser ? null : _userAvatars[senderId];

      final newMessage = Message(
        sender: senderId,
        message: data['content'] ?? '',
=======
      var messageType = data['message_type'] ?? 'text';
      //  SỬA: Lấy sender_name từ WebSocket, nếu không có thì lấy từ _userNames cache 
      var senderName = data['sender_name']?.toString() ?? _userNames[senderId];
      var content = data['content'] ?? '';
      final isUser = _isSenderMe(senderId);

      // : Parse system message từ content prefix 
      final parsedSystem = ChatSystemMessageService.parseSystemMessage(content);
      if (parsedSystem != null) {
        messageType = parsedSystem['type']!;
        senderName = parsedSystem['name'];
        content = parsedSystem['display']!;
        print('🔔 WebSocket: Parsed system message: type=$messageType, name=$senderName, display=$content');
      }

      // : Xử lý system message (leave_group, kick_member) 
      final isSystemMessage = messageType == 'system' ||
                              messageType == 'leave_group' ||
                              messageType == 'join_group' ||
                              messageType == 'kick_member';

      // Fetch avatar nếu là người khác và không phải system message
      if (!isUser && !isSystemMessage && !_userAvatars.containsKey(senderId)) {
        _fetchUserAvatar(senderId);
      }

      // Lấy avatar CÁ NHÂN của người gửi (không phải group avatar)
      final senderAvatarUrl = isUser ? null : _userAvatars[senderId];

      print('🖼️ WebSocket Avatar Debug: isUser=$isUser, senderId=$senderId, senderAvatar=$senderAvatarUrl, messageType=$messageType');

      //  SỬA: Kiểm tra xem user đang ở cuối chat không để quyết định isSeen 
      bool shouldMarkSeen = isUser || isSystemMessage; // System message luôn seen
      if (!isUser && !isSystemMessage) {
        if (_scrollController.hasClients) {
          final currentPosition = _scrollController.position.pixels;
          final maxScroll = _scrollController.position.maxScrollExtent;
          // Nếu user đang ở gần cuối chat, mark seen ngay lập tức
          if (maxScroll - currentPosition < 200) {
            shouldMarkSeen = true;
          }
        } else {
          // Nếu scroll controller chưa có client (chat mới load), mark seen luôn
          shouldMarkSeen = true;
        }
      }

      final newMessage = Message(
        sender: senderId,
        message: content,
>>>>>>> week10
        time: timeStr,
        isOnline: true,
        isUser: isUser,
        imageUrl: data['image_url'],
<<<<<<< HEAD
        messageType: data['message_type'] ?? 'text',
        senderAvatarUrl: senderAvatarUrl,
        isSeen: isUser, // === THÊM MỚI: Tin nhắn của mình luôn seen, tin nhắn người khác chưa seen ===
        createdAt: createdAtLocal, // === THÊM MỚI: Lưu thời gian tạo ===
      );

      // === DEBUG: Kiểm tra trạng thái isSeen ===
      print('📬 NEW MESSAGE - isUser: $isUser, isSeen: ${newMessage.isSeen}, content: "${newMessage.message}"');
=======
        messageType: messageType,
        senderAvatarUrl: senderAvatarUrl,
        isSeen: shouldMarkSeen, // Mark seen nếu user đang xem
        createdAt: createdAtLocal,
        senderName: senderName, // : Truyền tên người gửi 
      );

      print('📬 NEW MESSAGE - content: "${newMessage.message}"');
>>>>>>> week10

      // Thêm vào danh sách và update UI
      setState(() {
        _messages.add(newMessage);
      });

<<<<<<< HEAD
      // === THÊM MỚI: Lưu ID tin nhắn cuối cùng nếu đang ở cuối chat ===
=======
      // : Cập nhật cache với tin nhắn mới 
      if (_groupId != null) {
        await ChatCacheService.addMessage(_groupId!, data);
      }

      // : Lưu ID tin nhắn cuối cùng nếu đang ở cuối chat 
>>>>>>> week10
      final messageId = data['id']?.toString();
      if (messageId != null && _scrollController.hasClients) {
        final currentPosition = _scrollController.position.pixels;
        final maxScroll = _scrollController.position.maxScrollExtent;

        // Nếu đang ở gần cuối (user đang xem), save last seen message ID
        if (maxScroll - currentPosition < 200) {
          final prefs = await SharedPreferences.getInstance();
<<<<<<< HEAD
          await prefs.setString('last_seen_message_id', messageId);
          print('💾 Saved last_seen_message_id from WebSocket: $messageId');
        }
      }

      // === SỬA: Chỉ scroll to bottom, KHÔNG tự động mark seen ===
=======
          // Sử dụng key theo group để match với notification_screen
          await prefs.setString('last_seen_message_id_$_groupId', messageId);
          print('💾 Saved last_seen_message_id_$_groupId from WebSocket: $messageId');
        }
      }

      //  SỬA: Chỉ scroll to bottom, KHÔNG tự động mark seen 
>>>>>>> week10
      // User sẽ phải scroll xuống để mark seen
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (_scrollController.hasClients) {
          // Không scroll nếu user đang ở phía trên (đang xem tin cũ)
          final currentPosition = _scrollController.position.pixels;
          final maxScroll = _scrollController.position.maxScrollExtent;

          // Chỉ auto-scroll nếu đang ở gần cuối (trong vòng 200px)
          if (maxScroll - currentPosition < 200) {
            try {
              _isAutoScrolling = true;
              await _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
              );
            } finally {
              // đảm bảo cờ được reset dù animate thành công hay bị lỗi
              _isAutoScrolling = false;
            }
          }
        }
      });
    } catch (e) {
      print('❌ Error handling WebSocket message: $e');
    }
  }

<<<<<<< HEAD
  // === SỬA ĐỔI: Gửi tin nhắn qua WebSocket thay vì HTTP POST ===
=======
  //  SỬA ĐỔI: Gửi tin nhắn qua WebSocket thay vì HTTP POST 
>>>>>>> week10
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _channel == null) return;

    try {
      // Gửi tin nhắn qua WebSocket
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

<<<<<<< HEAD
  // === THÊM MỚI: Hiển thị bottom sheet để chọn nguồn ảnh ===
=======
  // : Hiển thị bottom sheet để chọn nguồn ảnh 
>>>>>>> week10
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
<<<<<<< HEAD
                  title: const Text('Chụp ảnh'),
=======
                  title: Text('take_photo'.tr()),
>>>>>>> week10
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndSendImage(source: ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Color(0xFFB99668)),
<<<<<<< HEAD
                  title: const Text('Chọn từ thư viện'),
=======
                  title: Text('choose_from_gallery'.tr()),
>>>>>>> week10
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

<<<<<<< HEAD
  // === THÊM MỚI (GĐ 13): Upload ảnh lên Supabase Storage ===
=======
  //  (GĐ 13): Upload ảnh lên Supabase Storage 
>>>>>>> week10
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

<<<<<<< HEAD
  // === THÊM MỚI (GĐ 13): Chọn và gửi ảnh ===
=======
  //  (GĐ 13): Chọn và gửi ảnh 
>>>>>>> week10
  Future<void> _pickAndSendImage({ImageSource source = ImageSource.gallery}) async {
    if (_channel == null) return;

    try {
      // Chọn ảnh từ gallery hoặc camera
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) return; // User cancelled

      setState(() {
        _isUploading = true;
      });

      // Upload ảnh lên Supabase
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

      // Gửi tin nhắn ảnh qua WebSocket
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

<<<<<<< HEAD
  // === THÊM MỚI: Navigate to members screen based on user role ===
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
=======
  Future<void> _navigateToMembersScreen() async {
    _accessToken = await AuthService.getValidAccessToken();

    if (_groupId == null || _groupId!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi: Không có thông tin nhóm')),
        );
      }
      return;
    }

    if (widget.groupData != null) {
      final groupData = widget.groupData!;
>>>>>>> week10

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
<<<<<<< HEAD
=======

>>>>>>> week10
      for (var memberData in membersList) {
        try {
          final profileUuid = memberData['profile_uuid']?.toString();
          final fullname = memberData['fullname']?.toString();
          final email = memberData['email']?.toString();
          final avatarUrl = memberData['avatar_url']?.toString();

<<<<<<< HEAD
          if (profileUuid == null || profileUuid.isEmpty) {
            continue;
          }
=======
          if (profileUuid == null || profileUuid.isEmpty) continue;
>>>>>>> week10

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
<<<<<<< HEAD
          print('🚀 Navigating to MemberScreenHost (Owner)');
=======
          print('🚀 Navigating to MemberScreenHost with groupId: $_groupId');
>>>>>>> week10
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => host.MemberScreenHost(
<<<<<<< HEAD
=======
                groupId: _groupId!,
>>>>>>> week10
                groupName: groupName,
                currentMembers: currentMembers,
                maxMembers: maxMembers,
                members: ownerMembers,
              ),
            ),
          );
        } else {
<<<<<<< HEAD
          print('🚀 Navigating to MemberScreenMember (Member)');
=======
          print('🚀 Navigating to MemberScreenMember with groupId: $_groupId');
>>>>>>> week10
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => member.MemberScreenMember(
<<<<<<< HEAD
=======
                groupId: _groupId!,
                groupName: groupName,
                currentMembers: currentMembers,
                maxMembers: maxMembers,
                members: memberMembers,
              ),
            ),
          );
        }
      }
      return;
    }

    try {
      final groupUrl = Uri.parse('${ApiConfig.baseUrl}/groups/$_groupId/detail');
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

      final groupData = jsonDecode(utf8.decode(groupResponse.bodyBytes)) as Map<String, dynamic>;
      final groupName = groupData['name']?.toString() ?? 'Unknown Group';
      final currentMembers = groupData['member_count'] as int? ?? 0;
      final maxMembers = groupData['max_members'] as int? ?? 0;

      String? currentUserRole;
      final List<dynamic> membersList = groupData['members'] ?? [];

      for (var memberData in membersList) {
        final profileUuid = memberData['profile_uuid']?.toString();
        if (profileUuid == _currentUserId) {
          currentUserRole = memberData['role']?.toString();
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

          if (profileUuid == null || profileUuid.isEmpty) continue;

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
          continue;
        }
      }

      if (mounted) {
        if (currentUserRole?.toLowerCase() == 'owner') {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => host.MemberScreenHost(
                groupId: _groupId!,
                groupName: groupName,
                currentMembers: currentMembers,
                maxMembers: maxMembers,
                members: ownerMembers,
              ),
            ),
          );
        } else {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => member.MemberScreenMember(
                groupId: _groupId!,
>>>>>>> week10
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

<<<<<<< HEAD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // === SỬA: false để dùng Positioned input bar ===
=======
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, //  SỬA: true để UI resize khi keyboard mở 
>>>>>>> week10
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
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
              'chat_title'.tr(),
=======
              _groupName.isNotEmpty ? _groupName : 'chat_title'.tr(),
>>>>>>> 3ee7efe (done all groupapis)
=======
              _groupName.isNotEmpty ? _groupName : 'chat_title'.tr(),
>>>>>>> 274291d (update)
=======
              _groupName ?? 'chat_title'.tr(),
>>>>>>> week10
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
<<<<<<< HEAD
                image: const DecorationImage(
=======
                image: _groupAvatarUrl != null && _groupAvatarUrl!.isNotEmpty
                    ? DecorationImage(
                  image: NetworkImage(_groupAvatarUrl!),
                  fit: BoxFit.cover,
                )
                    : const DecorationImage(
>>>>>>> week10
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
<<<<<<< HEAD
=======
            icon: const Icon(Icons.map, color: Colors.white, size: 28),
            onPressed: () async {
              String? preferredCity;

              if (widget.groupData != null) {
                preferredCity = widget.groupData!['preferred_city']?.toString();
              }

              else if (_groupId != null && _accessToken != null) {
                try {
                  final groupUrl = Uri.parse('${ApiConfig.baseUrl}/groups/$_groupId/detail');
                  final response = await http.get(
                    groupUrl,
                    headers: {
                      "Content-Type": "application/json",
                      "Authorization": "Bearer $_accessToken",
                    },
                  );

                  if (response.statusCode == 200) {
                    final groupData = jsonDecode(utf8.decode(response.bodyBytes));
                    preferredCity = groupData['preferred_city']?.toString();
                  }
                } catch (e) {
                  print('❌ Error fetching group data: $e');
                }
              }

              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapRouteScreen(
                      cityFilter: preferredCity,
                      groupId: _groupId != null ? int.tryParse(_groupId!) : null,
                    ),
                  ),
                );
              }
            },
            tooltip: 'Xem lộ trình',
          ),
          IconButton(
>>>>>>> week10
            icon: const Icon(Icons.people_outline, color: Colors.white, size: 28),
            onPressed: _navigateToMembersScreen,
          ),
        ],
      ),
      backgroundColor: const Color(0xFFEBE3D7),
      body: _isLoading
<<<<<<< HEAD
        ? const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF8A724C),
            ),
          )
<<<<<<< HEAD
<<<<<<< HEAD
        : Stack( // === SỬA ĐỔI: Sử dụng Stack để chồng nút lên trên danh sách tin nhắn ===
=======
=======
>>>>>>> 274291d (update)
        : LayoutBuilder(
        builder: (context, constraints) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          const double inputBarHeight = 56.0;
          return Stack(
<<<<<<< HEAD
>>>>>>> 3ee7efe (done all groupapis)
=======
>>>>>>> 274291d (update)
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
                          // === BỎ HEADER "HÔM NAY" CỐ ĐỊNH ===
                          // Date separators sẽ được hiển thị động trong ListView
                          Expanded(
                            child: Container(
                              color: Colors.white,
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: EdgeInsets.only(
                                  left: 12,
                                  right: 12,
                                  top: 16,
                                  bottom: inputBarHeight + 8 + bottomInset,
                                ),
                                itemCount: _messages.length,
                                itemBuilder: (context, index) {
                                  final m = _messages[index];
<<<<<<< HEAD
                                  final dateSeparator = _getDateSeparator(index);
                                  final shouldShowAvatar = _shouldShowAvatar(index);

                                  // Ensure we have a GlobalKey for this index
                                  _messageKeys[index] = _messageKeys[index] ?? GlobalKey();
                                  final messageKey = _messageKeys[index]!;

                                  return Column(
                                    children: [
                                      // === THÊM MỚI: Date separator (nếu có) ===
                                      if (dateSeparator != null)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEBE3D7),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              dateSeparator,
                                              style: const TextStyle(
                                                color: Colors.black54,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      // Message bubble wrapped with key and tap handler
                                      GestureDetector(
                                        onTap: () async {
                                          // Focus the input so keyboard opens
                                          _focusNode.requestFocus();

                                          // Wait for keyboard to open
                                          await Future.delayed(const Duration(milliseconds: 350));

                                          // Ensure the tapped message is visible
                                          if (messageKey.currentContext != null) {
                                            try {
                                              await Scrollable.ensureVisible(
                                                messageKey.currentContext!,
                                                duration: const Duration(milliseconds: 300),
                                                alignment: 0.3,
                                                curve: Curves.easeOut,
                                              );
                                            } catch (e) {
                                              // fallback: animate to bottom
                                              if (_scrollController.hasClients) {
                                                _scrollController.animateTo(
                                                  _scrollController.position.maxScrollExtent,
                                                  duration: const Duration(milliseconds: 300),
                                                  curve: Curves.easeOut,
                                                );
                                              }
                                            }
                                          }
                                        },
                                        child: Container(
                                          key: messageKey,
                                          child: _MessageBubble(
                                            message: m,
                                            senderAvatarUrl: m.senderAvatarUrl,
                                            currentUserId: _currentUserId,
                                            shouldShowAvatar: shouldShowAvatar,
                                          ),
                                        ),
                                      ),
                                    ],
=======
                                  return _MessageBubble(
                                    message: m,
                                    senderAvatarUrl: m.senderAvatarUrl,
                                    currentUserId: _currentUserId,
>>>>>>> 3ee7efe (done all groupapis)
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
<<<<<<< HEAD
<<<<<<< HEAD
              // === THÊM MỚI: Nút "Go to latest message" - Positioned ở giữa màn hình, bên phải ===
=======

              // === THÊM MỚI: Input bar positioned at bottom ===
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

              // === THÊM MỚI: Nút "Go to latest message" ===
>>>>>>> 274291d (update)
              if (_showScrollToBottomButton)
                Positioned(
                  right: 16,
                  bottom: 100 + bottomInset,
                  child: Material(
                    color: const Color(0xFFB99668),
                    elevation: 6,
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Đi tới tin nhắn mới nhất',
                      icon: const Icon(Icons.arrow_downward, color: Colors.white),
                      onPressed: _isAutoScrolling
                          ? null
                          : () async {
<<<<<<< HEAD
                              if (!_scrollController.hasClients) return;
                              try {
                                _isAutoScrolling = true;
                                await _scrollController.animateTo(
                                  _scrollController.position.maxScrollExtent,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                );
                              } catch (e) {
                                // ignore
                              } finally {
                                _isAutoScrolling = false;
                                if (mounted) setState(() => _showScrollToBottomButton = false);
                              }
                            },
=======

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
>>>>>>> 3ee7efe (done all groupapis)
=======
                        if (!_scrollController.hasClients) return;
                        try {
                          _isAutoScrolling = true;
                          await _scrollController.animateTo(
                            _scrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        } catch (e) {
                          // ignore
                        } finally {
                          _isAutoScrolling = false;
                          if (mounted) setState(() => _showScrollToBottomButton = false);
                        }
                      },
>>>>>>> 274291d (update)
                    ),
                  ),
                ),
            ],
          );
        },
=======
          ? Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 12,
                itemBuilder: (context, index) {
                  // Tạo variation cho skeleton (xen kẽ trái/phải)
                  final isUser = index % 3 == 0;
                  final widthFactor = 0.4 + (index % 4) * 0.1;
                  return LoadingSkeleton(
                    isUser: isUser,
                    widthFactor: widthFactor,
                  );
                },
              ),
            )
          : Stack( //  SỬA ĐỔI: Sử dụng Stack để chồng nút lên trên danh sách tin nhắn
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
                      //  BỎ HEADER "HÔM NAY" CỐ ĐỊNH 
                      // Date separators sẽ được hiển thị động trong ListView
                      Expanded(
                        child: Container(
                          color: Colors.white,
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.only(
                              left: 12,
                              right: 12,
                              top: 16,
                              bottom: 16,
                            ),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final m = _messages[index];
                              final dateSeparator = _getDateSeparator(index);
                              final shouldShowAvatar = _shouldShowAvatar(index); // Avatar ở cuối nhóm
                              final shouldShowSenderName = _shouldShowSenderName(index); // Tên ở đầu nhóm

                              // Ensure we have a GlobalKey for this index
                              _messageKeys[index] = _messageKeys[index] ?? GlobalKey();
                              final messageKey = _messageKeys[index]!;

                              return Column(
                                children: [
                                  // : Date separator (nếu có) 
                                  if (dateSeparator != null)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEBE3D7),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          dateSeparator,
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  // : Kiểm tra system message (leave_group, join_group) 
                                  if (m.isSystemMessage)
                                    _SystemMessageWidget(message: m)
                                  else
                                  // Message bubble wrapped with key and tap handler
                                  GestureDetector(
                                    onTap: () async {
                                      // Focus the input so keyboard opens
                                      _focusNode.requestFocus();

                                      // Wait for keyboard to open
                                      await Future.delayed(const Duration(milliseconds: 350));

                                      // Ensure the tapped message is visible
                                      if (messageKey.currentContext != null) {
                                        try {
                                          await Scrollable.ensureVisible(
                                            messageKey.currentContext!,
                                            duration: const Duration(milliseconds: 300),
                                            alignment: 0.3, // try to position message above keyboard
                                            curve: Curves.easeOut,
                                          );
                                        } catch (e) {
                                          // fallback: animate to bottom
                                          if (_scrollController.hasClients) {
                                            _scrollController.animateTo(
                                              _scrollController.position.maxScrollExtent,
                                              duration: const Duration(milliseconds: 300),
                                              curve: Curves.easeOut,
                                            );
                                          }
                                        }
                                      }
                                    },
                                    child: Container(
                                      key: messageKey,
                                      child: _MessageBubble(
                                        message: m,
                                        senderAvatarUrl: m.senderAvatarUrl,
                                        currentUserId: _currentUserId,
                                        shouldShowAvatar: shouldShowAvatar, // Avatar ở cuối nhóm
                                        shouldShowSenderName: shouldShowSenderName, // Tên ở đầu nhóm
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ), // ListView.builder
                        ), // Container (color: Colors.white)
                      ), // Expanded
                    ], // children of inner Column
                  ), // Column
                ), // Container (with decoration)
              ), // Expanded

              // Input bar at bottom
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  color: Colors.white,
                  child: Row(
                    children: [
                      // : Nút chọn ảnh - hiện bottom sheet để chọn camera/gallery 
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
                            maxLines: null, //  SỬA: Cho phép nhiều dòng 
                            minLines: 1, //  SỬA: Bắt đầu với 1 dòng 
                            keyboardType: TextInputType.multiline, //  SỬA: Keyboard hỗ trợ multiline 
                            textInputAction: TextInputAction.newline, //  SỬA: Enter để xuống dòng 
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              hintText: 'enter_message'.tr(),
                              hintStyle: const TextStyle(color: Colors.black38),
                              border: InputBorder.none,
                            ),
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
            ],
          ),
          // : Nút "Go to latest message" - Positioned ở giữa màn hình, bên phải 
          if (_showScrollToBottomButton)
            Positioned(
              right: 16, //  Căn bên phải 
              bottom: 100, //  Cách đáy 100px để tránh input bar 
              child: Material(
                color: const Color(0xFFB99668),
                elevation: 6,
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Đi tới tin nhắn mới nhất',
                  icon: const Icon(Icons.arrow_downward, color: Colors.white),
                  onPressed: _isAutoScrolling
                      ? null
                      : () async {
                    if (!_scrollController.hasClients) return;
                    try {
                      _isAutoScrolling = true;
                      await _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    } catch (e) {
                      // ignore
                    } finally {
                      _isAutoScrolling = false;
                      if (mounted) setState(() => _showScrollToBottomButton = false);
                    }
                  },
                ),
              ),
            ),
        ],
>>>>>>> week10
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
<<<<<<< HEAD
<<<<<<< HEAD
  final String? senderAvatarUrl; // === THÊM MỚI: Avatar của người gửi ===
  final String? currentUserId; // === THÊM MỚI: current user id để so sánh chính xác ===
  final bool shouldShowAvatar; // === THÊM MỚI: Có nên hiển thị avatar không (message grouping) ===
=======
  final String? senderAvatarUrl;
  final String? currentUserId;
>>>>>>> 3ee7efe (done all groupapis)
=======
  final String? senderAvatarUrl; // : Avatar của người gửi 
  final String? currentUserId; // : current user id để so sánh chính xác 
  final bool shouldShowAvatar; //  Avatar ở cuối nhóm tin nhắn 
  final bool shouldShowSenderName; //  Tên ở đầu nhóm tin nhắn 
>>>>>>> week10

  const _MessageBubble({
    Key? key,
    required this.message,
    this.senderAvatarUrl,
    this.currentUserId,
<<<<<<< HEAD
<<<<<<< HEAD
    this.shouldShowAvatar = true, // === THÊM MỚI: Mặc định hiển thị avatar ===
=======
>>>>>>> 3ee7efe (done all groupapis)
=======
    this.shouldShowAvatar = true,
    this.shouldShowSenderName = true, // : Mặc định hiển thị tên 
>>>>>>> week10
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
<<<<<<< HEAD
    // Prefer authoritative check using currentUserId if available, otherwise fall back to message.isUser
=======
>>>>>>> 3ee7efe (done all groupapis)
=======
    // Prefer authoritative check using currentUserId if available, otherwise fall back to message.isUser
>>>>>>> week10
    final bool isUser = (currentUserId != null && currentUserId!.isNotEmpty)
        ? (message.sender.toString().trim().toLowerCase() == currentUserId!.toString().trim().toLowerCase())
        : message.isUser;
    final bubbleColor = isUser ? const Color(0xFF8A724C) : const Color(0xFFB99668);
<<<<<<< HEAD
    final textColor = Colors.white;
    final showAvatar = !isUser;
    print('🖼️ MessageBubble - isUser: $isUser, isSeen: ${message.isSeen}, sender: ${message.sender}, content: "${message.message}"');
    print('🖼️ Should show BOLD: ${!isUser && !message.isSeen}');
    print('🖼️ Should show avatar: $showAvatar, avatarUrl: $senderAvatarUrl');

    // === SỬA: Chỉ hiển thị avatar nếu shouldShowAvatar = true ===
=======
    final textColor = isUser ? Colors.white : Colors.white;

    //  SỬA: Chỉ hiển thị avatar nếu shouldShowAvatar = true 
>>>>>>> week10
    final showAvatar = !isUser && shouldShowAvatar;
    print('🖼️ MessageBubble - isUser: $isUser, isSeen: ${message.isSeen}, shouldShowAvatar: $shouldShowAvatar, sender: ${message.sender}, content: "${message.message}"');
    print('🖼️ Should show BOLD: ${!isUser && !message.isSeen}');
    print('🖼️ Should show avatar: $showAvatar, avatarUrl: $senderAvatarUrl');

    return Padding(
      padding: EdgeInsets.only(
<<<<<<< HEAD
        top: 2.0, // === SỬA: Giảm padding top để gộp tin nhắn gần nhau hơn ===
        bottom: shouldShowAvatar ? 6.0 : 2.0, // === SỬA: Padding bottom lớn hơn nếu có avatar (kết thúc nhóm) ===
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
<<<<<<< HEAD
          // === SỬA MỚI: Hiển thị avatar hoặc khoảng trống để canh chỉnh ===
          if (!isUser) ...[
            SizedBox(
              width: 48, // === Chiều rộng cố định cho vùng avatar ===
              child: showAvatar
                  ? Padding(
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
              )
                  : const SizedBox(), // === Khoảng trống để canh chỉnh ===
=======
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
>>>>>>> 3ee7efe (done all groupapis)
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
<<<<<<< HEAD
                  // === THÊM MỚI: Hiển thị ảnh nếu là tin nhắn ảnh ===
=======
>>>>>>> 3ee7efe (done all groupapis)
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
<<<<<<< HEAD
                  // Hiển thị text (nếu có)
=======
>>>>>>> 3ee7efe (done all groupapis)
                  if (message.message.isNotEmpty)
                    Text(
                      message.message,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: !isUser && !message.isSeen
<<<<<<< HEAD
<<<<<<< HEAD
                          ? FontWeight.bold  // === THÊM MỚI: In đậm nếu chưa seen ===
=======
                          ? FontWeight.bold
>>>>>>> 3ee7efe (done all groupapis)
                          : FontWeight.normal,
=======
                            ? FontWeight.bold  // === THÊM MỚI: In đậm nếu chưa seen ===
                            : FontWeight.normal,
>>>>>>> 274291d (update)
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
<<<<<<< HEAD
          // === SỬA MỚI: Không hiển thị avatar cho tin nhắn của mình ===
=======
>>>>>>> 3ee7efe (done all groupapis)
=======
        top: 2.0, //  SỬA: Giảm padding top để gộp tin nhắn gần nhau hơn 
        bottom: shouldShowAvatar ? 6.0 : 2.0, //  SỬA: Padding bottom lớn hơn nếu có avatar (kết thúc nhóm) 
      ),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          //  Hiển thị tên người gửi nếu là tin nhắn ĐẦU TIÊN trong nhóm 
          if (!isUser && shouldShowSenderName && message.senderName != null && message.senderName!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 56.0, bottom: 4.0), // 48 (avatar width) + 8 (spacing)
              child: Text(
                message.senderName!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8A724C),
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              //  SỬA MỚI: Hiển thị avatar hoặc khoảng trống để canh chỉnh 
              if (!isUser) ...[
                SizedBox(
                  width: 48, //  Chiều rộng cố định cho vùng avatar 
                  child: showAvatar
                      ? Padding(
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
                  )
                      : const SizedBox(), //  Khoảng trống để canh chỉnh 
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
                      // : Hiển thị ảnh nếu là tin nhắn ảnh 
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
                      // Hiển thị text (nếu có)
                      if (message.message.isNotEmpty)
                        Text(
                          message.message,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: !isUser && !message.isSeen
                                ? FontWeight.bold  // : In đậm nếu chưa seen 
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
              //  SỬA MỚI: Không hiển thị avatar cho tin nhắn của mình 
            ],
          ),
>>>>>>> week10
        ],
      ),
    );
  }
}
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
=======

=======

// === THÊM MỚI: PendingRequest class for member screen compatibility ===
>>>>>>> 274291d (update)
class PendingRequest {
  final String id;
  final String name;
  final String email;
  final DateTime requestedAt;
  final double rating;
  final List<String> keywords;
<<<<<<< HEAD
  
=======

>>>>>>> 274291d (update)
  PendingRequest({
    required this.id,
    required this.name,
    required this.email,
    required this.requestedAt,
    this.rating = 0.0,
    this.keywords = const [],
  });
}
<<<<<<< HEAD
>>>>>>> 3ee7efe (done all groupapis)
=======
>>>>>>> 274291d (update)
=======

// : Widget hiển thị system message (rời nhóm, tham gia nhóm, bị kick) 
class _SystemMessageWidget extends StatelessWidget {
  final Message message;

  const _SystemMessageWidget({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // message.message đã được parse thành display text (ví dụ: "hellomoi đã rời khỏi nhóm")
    String displayText = message.message;
    IconData icon = Icons.info_outline;
    Color bgColor = const Color(0xFFEBE3D7);
    Color textColor = Colors.black54;

    switch (message.messageType) {
      case 'leave_group':
        icon = Icons.exit_to_app;
        bgColor = const Color(0xFFFFF3E0); // Màu cam nhạt
        textColor = Colors.orange.shade700;
        break;
      case 'join_group':
        icon = Icons.person_add;
        bgColor = const Color(0xFFE8F5E9); // Màu xanh lá nhạt
        textColor = Colors.green.shade700;
        break;
      case 'kick_member':
        icon = Icons.person_remove;
        bgColor = const Color(0xFFFFEBEE); // Màu đỏ nhạt
        textColor = Colors.red.shade700;
        break;
      case 'system':
      default:
        // Sử dụng nội dung gốc nếu là system message chung
        if (displayText.isEmpty) displayText = 'Thông báo hệ thống';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13), // 0.05 * 255
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  displayText,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

>>>>>>> week10
