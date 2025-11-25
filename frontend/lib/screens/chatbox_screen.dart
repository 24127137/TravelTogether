import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
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
  final ImagePicker _imagePicker = ImagePicker(); // === THÊM MỚI: ImagePicker ===
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isUploading = false; // === THÊM MỚI: Trạng thái upload ===
  String? _accessToken;
  String? _currentUserId; // UUID của user hiện tại (lấy từ SharedPreferences khi login)
  Timer? _refreshTimer;
  Map<String, String?> _userAvatars = {}; // === THÊM MỚI: Cache avatar của users ===
  String? _myAvatarUrl; // === THÊM MỚI: Avatar của mình ===

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
    _currentUserId = prefs.getString('user_id'); // Lấy user_id (UUID) đã lưu khi login

    // DEBUG: Kiểm tra SharedPreferences
    print('🔍 ===== SHARED PREFERENCES DEBUG =====');
    print('🔍 All keys: ${prefs.getKeys()}');
    print('🔍 Access Token exists: ${_accessToken != null}');
    print('🔍 Current User ID: "$_currentUserId"');
    print('🔍 ====================================');

    if (_accessToken != null) {
      await _loadMyProfile(); // Load avatar của mình
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

  // === Helper kiểm tra senderId có phải là user hiện tại hay không ===
  bool _isSenderMe(String? senderId) {
    if (senderId == null || _currentUserId == null) return false;
    // So sánh với currentUserId (đã lưu từ login)
    return senderId.toString().trim() == _currentUserId!.toString().trim();
  }

  // === THÊM MỚI: Load profile của mình để lấy avatar ===
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

  // === THÊM MỚI: Load avatar của user khác ===
  Future<String?> _fetchUserAvatar(String userId) async {
    if (_accessToken == null) return null;

    // Check cache trước
    if (_userAvatars.containsKey(userId)) {
      return _userAvatars[userId];
    }

    try {
      // TODO: Cần API để lấy profile của user khác theo ID
      // Tạm thời cache null, sẽ dùng default avatar
      _userAvatars[userId] = null;
      return null;
    } catch (e) {
      print('❌ Error fetching user avatar: $e');
      _userAvatars[userId] = null;
      return null;
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

  // === THÊM MỚI: Hiển thị bottom sheet để chọn nguồn ảnh ===
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

  // === THÊM MỚI (GĐ 13): Upload ảnh lên Supabase Storage ===
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

  // === THÊM MỚI (GĐ 13): Chọn và gửi ảnh ===
  Future<void> _pickAndSendImage({ImageSource source = ImageSource.gallery}) async {
    if (_accessToken == null) return;

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

      // Gửi tin nhắn ảnh
      final url = ApiConfig.getUri(ApiConfig.chatSend);
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_accessToken",
        },
        body: jsonEncode({
          "message_type": "image",
          "image_url": imageUrl,
        }),
      );

      if (response.statusCode == 200) {
        // Reload chat history
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
        throw Exception('Failed to send image: ${response.statusCode}');
      }
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
                                  return _MessageBubble(
                                    message: m,
                                    senderAvatarUrl: m.senderAvatarUrl,
                                    currentUserId: _currentUserId, // pass current user id so widget can decide
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
                        // === THÊM MỚI: Nút chọn ảnh - hiện bottom sheet để chọn camera/gallery ===
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
  final String? senderAvatarUrl; // === THÊM MỚI: Avatar của người gửi ===
  final String? currentUserId; // === THÊM MỚI: current user id để so sánh chính xác ===

  const _MessageBubble({
    Key? key,
    required this.message,
    this.senderAvatarUrl,
    this.currentUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Prefer authoritative check using currentUserId if available, otherwise fall back to message.isUser
    final bool isUser = (currentUserId != null && currentUserId!.isNotEmpty)
        ? (message.sender.toString().trim().toLowerCase() == currentUserId!.toString().trim().toLowerCase())
        : message.isUser;
    final bubbleColor = isUser ? const Color(0xFF8A724C) : const Color(0xFFB99668);
    final textColor = isUser ? Colors.white : Colors.white;

    // === DEBUG: Kiểm tra avatar hiển thị ===
    final showAvatar = !isUser; // avatar if message not from current user
    print('🖼️ MessageBubble - isUser: $isUser, sender: ${message.sender}, avatarUrl: $senderAvatarUrl, currentUserId: $currentUserId');
    print('🖼️ Should show avatar: $showAvatar');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // === SỬA MỚI: Chỉ hiện avatar cho người khác (không phải mình) ===
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
                  // === THÊM MỚI: Hiển thị ảnh nếu là tin nhắn ảnh ===
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
          // === SỬA MỚI: Không hiển thị avatar cho tin nhắn của mình ===
        ],
      ),
    );
  }
}
