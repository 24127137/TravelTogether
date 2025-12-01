import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/api_config.dart';
import '../models/ai_message.dart';

/// Màn hình chat với AI Chatbot
class AiChatbotScreen extends StatefulWidget {
  const AiChatbotScreen({Key? key}) : super(key: key);

  @override
  _AiChatbotScreenState createState() => _AiChatbotScreenState();
}

class _AiChatbotScreenState extends State<AiChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();
  List<AiMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isUploading = false;
  String? _userId;

  Map<int, GlobalKey> _messageKeys = {};
  bool _showScrollToBottomButton = false;
  bool _isAutoScrolling = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _scrollToBottom();
          }
        });
      }
    });

    // Lắng nghe scroll để hiển thị nút scroll-to-bottom
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      final pos = _scrollController.position.pixels;
      final max = _scrollController.position.maxScrollExtent;

      // Nếu cách đáy > 200 show button
      final show = pos < (max - 200);
      if (show != _showScrollToBottomButton && mounted) {
        setState(() {
          _showScrollToBottomButton = show;
        });
      }
    });
  }

  Future<void> _initializeChat() async {
    try {
      // Lấy user_id từ SharedPreferences (được lưu khi login/signup)
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      setState(() {
        _userId = userId;
      });

      // Lấy lịch sử chat từ backend
      await _loadChatHistory();
    } catch (e) {
      print('❌ Error initializing chat: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khởi tạo chat: $e')),
        );
      }
    }
  }

  Future<void> _loadChatHistory() async {
    if (_userId == null) return;

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/ai/chat-history?user_id=$_userId&limit=50');

      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      print('📜 Loading chat history: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final messages = data['messages'] as List<dynamic>;

        setState(() {
          _messages = messages
              .map((m) => AiMessage(
                    role: m['role'] ?? 'user',
                    text: m['content'] ?? '',
                    time: _formatTime(m['created_at']),
                    imageUrl: m['image_url'],
                  ))
              .toList();
          _isLoading = false;
        });

        print('✅ Loaded ${_messages.length} messages from backend');
        _scrollToBottom();
      } else if (response.statusCode == 404) {
        // Chưa có lịch sử, tạo mới
        setState(() {
          _messages = [];
          _isLoading = false;
        });
        print('✅ No chat history found, starting fresh');
      } else {
        throw Exception('Failed to load chat history: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading chat history: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatTime(String? dateTimeString) {
    if (dateTimeString == null) return '';
    try {
      final dt = DateTime.parse(dateTimeString);
      return DateFormat('HH:mm').format(dt);
    } catch (e) {
      return DateFormat('HH:mm').format(DateTime.now());
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _userId == null || _isSending) return;

    print('🚀 Sending AI message...');
    print('  User ID: $_userId');
    print('  Message: $text');

    setState(() {
      _isSending = true;
    });

    // Thêm tin nhắn user vào UI
    final userMessage = AiMessage(
      role: 'user',
      text: text,
      time: DateFormat('HH:mm').format(DateTime.now()),
    );

    setState(() {
      _messages.add(userMessage);
      _controller.clear();
    });

    _scrollToBottom();

    // Gọi API
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/ai/send?user_id=$_userId');
      print('  API URL: $url');

      final requestBody = jsonEncode({
        "message": text,
      });
      print('  Request body: $requestBody');

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: requestBody,
      );

      print('  Response status: ${response.statusCode}');
      print('  Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final aiResponse = data['response'] ?? '';

        print('✅ AI Response: $aiResponse');

        // Thêm response của AI vào UI
        final aiMessage = AiMessage(
          role: 'assistant',
          text: aiResponse,
          time: DateFormat('HH:mm').format(DateTime.now()),
        );

        setState(() {
          _messages.add(aiMessage);
          _isSending = false;
        });

        _scrollToBottom();
      } else {
        // Parse error response
        String errorDetail = response.body;
        try {
          final errorData = jsonDecode(response.body);
          errorDetail = errorData['detail'] ?? response.body;
        } catch (e) {
          // Keep original body if JSON parse fails
        }

        print('❌ Server error: $errorDetail');
        throw Exception('Server error (${response.statusCode}): $errorDetail');
      }
    } catch (e) {
      print('❌ Error sending AI message: $e');

      // Remove user message if send failed
      setState(() {
        if (_messages.isNotEmpty && _messages.last.role == 'user') {
          _messages.removeLast();
        }
        _isSending = false;
      });

      if (mounted) {
        String errorMessage = 'ai_chat_error_send'.tr();
        errorMessage = '$errorMessage\n${e.toString()}';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }


  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_scrollController.hasClients) return;

      try {
        _isAutoScrolling = true;
        await _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } catch (e) {
        // ignore
      } finally {
        _isAutoScrolling = false;
        if (mounted) {
          setState(() {
            _showScrollToBottomButton = false;
          });
        }
      }
    });
  }

  // === THÊM MỚI: Hiển thị bottom sheet để chọn nguồn ảnh ===
  Future<void> _showImageSourceSelection() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Color(0xFFB99668)),
                  title: const Text('Chọn từ thư viện'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndSendImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Color(0xFFB99668)),
                  title: const Text('Chụp ảnh'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndSendImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Chọn và gửi ảnh
  Future<void> _pickAndSendImage(ImageSource source) async {
    if (_isUploading || _userId == null) return;

    try {
      // Chọn ảnh
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

      // Upload ảnh lên Supabase Storage
      final file = File(pickedFile.path);
      final fileName = 'ai_chat_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final supabase = Supabase.instance.client;

      print('📤 Uploading image to Supabase...');
      print('  Bucket: chat_images');
      print('  File: $fileName');

      try {
        await supabase.storage
            .from('chat_images')
            .upload(fileName, file);

        print('✅ Image uploaded: $fileName');
      } catch (uploadError) {
        print('❌ Upload error: $uploadError');

        // Handle RLS policy errors
        if (uploadError.toString().contains('row-level security') ||
            uploadError.toString().contains('Unauthorized')) {
          throw Exception(
            'Lỗi quyền truy cập bucket. Vui lòng liên hệ admin.\n'
            'Chi tiết: ${uploadError.toString()}'
          );
        }
        rethrow;
      }

      // Lấy public URL
      final imageUrl = supabase.storage
          .from('chat_images')
          .getPublicUrl(fileName);

      print('🖼️ Image URL: $imageUrl');

      // Gửi tin nhắn ảnh
      await _sendImageMessage(imageUrl);
    } catch (e) {
      print('❌ Error picking/uploading image: $e');
      if (mounted) {
        String errorMessage = 'Lỗi upload ảnh';
        if (e.toString().contains('row-level security') ||
            e.toString().contains('Unauthorized')) {
          errorMessage = 'Lỗi quyền truy cập bucket. Hãy kiểm tra cấu hình Supabase.';
        } else if (e.toString().contains('StorageException')) {
          errorMessage = 'Lỗi Storage: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  // Gửi tin nhắn ảnh
  Future<void> _sendImageMessage(String imageUrl) async {
    if (_userId == null || _isSending) return;

    print('🚀 Sending AI image message...');
    print('  User ID: $_userId');
    print('  Image URL: $imageUrl');

    setState(() {
      _isSending = true;
    });

    // Thêm tin nhắn ảnh của user vào UI
    final userMessage = AiMessage(
      role: 'user',
      text: '[Đã gửi ảnh]',
      time: DateFormat('HH:mm').format(DateTime.now()),
      imageUrl: imageUrl,
    );

    setState(() {
      _messages.add(userMessage);
    });

    _scrollToBottom();

    // Gọi API với message (text trống) và image_url
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/ai/send?user_id=$_userId');
      print('  API URL: $url');

      final requestBody = jsonEncode({
        "message": "",
        "image_url": imageUrl,
      });
      print('  Request body: $requestBody');

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: requestBody,
      );

      print('  Response status: ${response.statusCode}');
      print('  Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final aiResponse = data['response'] ?? '';

        // Thêm tin nhắn AI vào UI
        final aiMessage = AiMessage(
          role: 'assistant',
          text: aiResponse,
          time: DateFormat('HH:mm').format(DateTime.now()),
        );

        setState(() {
          _messages.add(aiMessage);
          _isSending = false;
        });

        _scrollToBottom();
      } else {
        throw Exception('Failed to send AI image: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error sending AI image: $e');

      // Remove user message if send failed
      setState(() {
        if (_messages.isNotEmpty && _messages.last.imageUrl == imageUrl) {
          _messages.removeLast();
        }
        _isSending = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi gửi ảnh: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ai_chat_clear_title'.tr()),
        content: Text('ai_chat_clear_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('confirm'.tr()),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true && _userId != null) {
      try {
        final url = Uri.parse('${ApiConfig.baseUrl}/ai/clear-chat?user_id=$_userId');

        final response = await http.delete(
          url,
          headers: {"Content-Type": "application/json"},
        );

        if (response.statusCode == 200) {
          setState(() {
            _messages = [];
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lịch sử chat đã bị xóa')),
            );
          }
        } else {
          throw Exception('Failed to clear chat history');
        }
      } catch (e) {
        print('❌ Error clearing chat: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi xóa lịch sử: $e')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // === SỬA: true để UI resize khi keyboard mở ===
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
              'ai_chat_title'.tr(),
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
            icon: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
            onPressed: _clearHistory,
            tooltip: 'ai_chat_clear_title'.tr(),
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
          : Stack(
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 8.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEBE3D7),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'ai_chat_subtitle'.tr(),
                                  style: const TextStyle(
                                      color: Colors.black54, fontSize: 12),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                color: Colors.white,
                                child: _messages.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Image.asset(
                                              'assets/images/chatbot_icon.png',
                                              width: 80,
                                              height: 80,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'ai_chat_welcome'.tr(),
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey[600],
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.builder(
                                        controller: _scrollController,
                                        padding: const EdgeInsets.only(
                                          left: 12,
                                          right: 12,
                                          top: 0,
                                          bottom: 16,
                                        ),
                                        itemCount: _messages.length,
                                        itemBuilder: (context, index) {
                                          final m = _messages[index];

                                          // Ensure we have a GlobalKey for this index
                                          _messageKeys[index] = _messageKeys[index] ?? GlobalKey();
                                          final messageKey = _messageKeys[index]!;

                                          return GestureDetector(
                                            onTap: () async {
                                              // Focus input to open keyboard
                                              _focusNode.requestFocus();

                                              // Wait for keyboard to open
                                              await Future.delayed(const Duration(milliseconds: 350));

                                              if (messageKey.currentContext != null) {
                                                try {
                                                  await Scrollable.ensureVisible(
                                                    messageKey.currentContext!,
                                                    duration: const Duration(milliseconds: 300),
                                                    alignment: 0.3,
                                                    curve: Curves.easeOut,
                                                  );
                                                } catch (e) {
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
                                              child: _AiMessageBubble(message: m),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Input bar
                    SafeArea(
                      top: false,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 8.0),
                        color: Colors.white,
                        child: Row(
                          children: [
                            // === THÊM MỚI: Nút chọn ảnh ===
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
                                onPressed: (_isUploading || _isSending) ? null : _showImageSourceSelection,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 4.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEBE3D7),
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                                child: TextField(
                                  controller: _controller,
                                  focusNode: _focusNode,
                                  enabled: !_isSending,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16.0, vertical: 8.0),
                                    hintText: 'ai_chat_input_hint'.tr(),
                                    hintStyle:
                                        const TextStyle(color: Colors.black38),
                                    border: InputBorder.none,
                                  ),
                                  onSubmitted: (_) => _sendMessage(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Material(
                              color: _isSending
                                  ? Colors.grey
                                  : const Color(0xFFB99668),
                              shape: const CircleBorder(),
                              child: IconButton(
                                icon: _isSending
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.send, color: Colors.white),
                                onPressed: _isSending ? null : _sendMessage,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Nút scroll-to-bottom ở góc dưới phải (như trong chatbox_screen)
                if (_showScrollToBottomButton)
                  Positioned(
                    bottom: 80,
                    right: 16,
                    child: Material(
                      color: const Color(0xFFB99668),
                      elevation: 6,
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: 'Đi tới tin nhắn mới nhất',
                        icon: const Icon(Icons.arrow_downward, color: Colors.white),
                        onPressed: _isAutoScrolling ? null : _scrollToBottom,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _AiMessageBubble extends StatelessWidget {
  final AiMessage message;
  const _AiMessageBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.isUser;
    final bubbleColor = isUser ? const Color(0xFF8A724C) : const Color(0xFFB99668);
    final textColor = Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Image.asset('assets/images/chatbot_icon.png',
                  width: 40, height: 40),
            )
          ],
          Flexible(
            child: Container(
              constraints:
                  BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft:
                      isUser ? const Radius.circular(20) : const Radius.circular(0),
                  bottomRight:
                      isUser ? const Radius.circular(0) : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withAlpha((0.05 * 255).toInt()),
                      blurRadius: 2,
                      offset: const Offset(0, 1))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // === THÊM MỚI: Hiển thị ảnh nếu có ===
                  if (message.imageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        message.imageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 200,
                            height: 200,
                            color: Colors.grey[300],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 200,
                            height: 200,
                            color: Colors.grey[300],
                            child: const Icon(Icons.error, color: Colors.white),
                          );
                        },
                      ),
                    ),
                    if (message.text.isNotEmpty && message.text != '[Đã gửi ảnh]')
                      const SizedBox(height: 8),
                  ],
                  // Hiển thị text (nếu không phải "[Đã gửi ảnh]")
                  if (message.text.isNotEmpty && message.text != '[Đã gửi ảnh]')
                    Text(
                      message.text,
                      style: TextStyle(color: textColor, fontSize: 16),
                    ),
                  const SizedBox(height: 6),
                  Text(message.time,
                      style: TextStyle(
                          color: textColor.withAlpha((0.7 * 255).toInt()),
                          fontSize: 11)),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child:
                  Image.asset('assets/images/avatar.jpg', width: 40, height: 40),
            )
          ]
        ],
      ),
    );
  }
}

