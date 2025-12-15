import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
<<<<<<< HEAD
import 'dart:io'; // === THÊM MỚI: For File ===
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart'; // === THÊM MỚI: For image selection ===
import 'package:supabase_flutter/supabase_flutter.dart'; // === THÊM MỚI: For image upload ===
=======
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
>>>>>>> week10
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
<<<<<<< HEAD
  final ImagePicker _imagePicker = ImagePicker(); // === THÊM MỚI: ImagePicker ===
  List<AiMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isUploading = false; // === THÊM MỚI: Trạng thái upload ảnh ===
  String? _sessionId;

  Map<int, GlobalKey> _messageKeys = {}; // === THÊM MỚI: keys per message for ensureVisible ===
  bool _showScrollToBottom = false; // === THÊM MỚI: show centered button ===
  bool _isAutoScrolling = false; // === THÊM MỚI: flag to avoid reacting to programmatic scroll ===
=======
  final ImagePicker _imagePicker = ImagePicker();
  List<AiMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isUploading = false;
  String? _userId;
  String? _accessToken; //Access token để upload ảnh

  //Biến lưu ảnh đã chọn để preview trước khi gửi
  String? _selectedImageUrl;

  Map<int, GlobalKey> _messageKeys = {};
  bool _showScrollToBottomButton = false;
  bool _isAutoScrolling = false;
>>>>>>> week10

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
<<<<<<< HEAD
        // === SỬA: Thêm delay để đợi keyboard mở hoàn toàn ===
=======
>>>>>>> week10
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _scrollToBottom();
          }
        });
      }
    });

<<<<<<< HEAD
    // === THÊM MỚI: lắng nghe scroll để hiển thị nút scroll-to-bottom ===
=======
    // Lắng nghe scroll để hiển thị nút scroll-to-bottom
>>>>>>> week10
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      final pos = _scrollController.position.pixels;
      final max = _scrollController.position.maxScrollExtent;

      // Nếu cách đáy > 200 show button
      final show = pos < (max - 200);
<<<<<<< HEAD
      if (show != _showScrollToBottom && mounted) {
        setState(() {
          _showScrollToBottom = show;
=======
      if (show != _showScrollToBottomButton && mounted) {
        setState(() {
          _showScrollToBottomButton = show;
>>>>>>> week10
        });
      }
    });
  }

  Future<void> _initializeChat() async {
<<<<<<< HEAD
    // Load session từ SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final savedSessionId = prefs.getString('ai_chat_session_id');
    final savedMessages = prefs.getString('ai_chat_messages');

    if (savedSessionId != null && savedMessages != null) {
      // Có session cũ, load lại
      try {
        final List<dynamic> messagesJson = jsonDecode(savedMessages);
        setState(() {
          _sessionId = savedSessionId;
          _messages = messagesJson.map((m) => AiMessage.fromJson(m)).toList();
          _isLoading = false;
        });
        _scrollToBottom();
      } catch (e) {
        // Nếu lỗi, tạo session mới
        await _createNewSession();
      }
    } else {
      // Chưa có session, tạo mới
      await _createNewSession();
    }
  }

  Future<void> _createNewSession() async {
    try {
      final url = ApiConfig.getUri(ApiConfig.aiNewSession);
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sessionId = data['session_id'];

        // Lưu session_id
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('ai_chat_session_id', sessionId);

        setState(() {
          _sessionId = sessionId;
          _messages = [];
          _isLoading = false;
        });

        print('✅ Created new AI session: $sessionId');
      } else {
        throw Exception('Failed to create AI session');
      }
    } catch (e) {
      print('❌ Error creating AI session: $e');
=======
    try {
      // Lấy user_id và access_token từ SharedPreferences (được lưu khi login/signup)
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final accessToken = prefs.getString('access_token');

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      setState(() {
        _userId = userId;
        _accessToken = accessToken;
      });

      print('🔐 AI Chat initialized with user_id: $userId');
      print('🔐 Access token available: ${accessToken != null}');

      // Lấy lịch sử chat từ backend
      await _loadChatHistory();
    } catch (e) {
      print('❌ Error initializing chat: $e');
>>>>>>> week10
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
<<<<<<< HEAD
          SnackBar(content: Text('ai_chat_error_create_session'.tr())),
=======
          SnackBar(content: Text('Lỗi khởi tạo chat: $e')),
>>>>>>> week10
        );
      }
    }
  }

<<<<<<< HEAD
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sessionId == null || _isSending) return;

    print('🚀 Sending AI message...');
    print('  Session ID: $_sessionId');
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
      final url = ApiConfig.getUri(ApiConfig.aiSend);
      print('  API URL: $url');

      final requestBody = jsonEncode({
        "session_id": _sessionId,
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

        // Lưu lịch sử chat
        await _saveChatHistory();

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
        if (e.toString().contains('Session_id không tồn tại')) {
          errorMessage = 'Session expired. Creating new session...';
          // Auto create new session
          await _createNewSession();
        } else {
          errorMessage = '$errorMessage\n${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = _messages.map((m) => m.toJson()).toList();
    await prefs.setString('ai_chat_messages', jsonEncode(messagesJson));
  }

=======
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
              .map((m) {
                String content = m['content'] ?? '';
                String? imageUrl = m['image_url'];

                // Nếu không có image_url riêng, kiểm tra xem content có chứa URL ảnh không
                if (imageUrl == null || imageUrl.isEmpty) {
                  imageUrl = _extractImageUrlFromContent(content);
                }

                // Nếu tìm được URL ảnh trong content, làm sạch text hiển thị
                String displayText = content;
                if (imageUrl != null) {
                  displayText = _cleanContentWithImageUrl(content);
                }

                return AiMessage(
                  role: m['role'] ?? 'user',
                  text: displayText,
                  time: _formatTime(m['created_at']),
                  imageUrl: imageUrl,
                );
              })
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

  // Helper: Trích xuất URL ảnh từ content
  String? _extractImageUrlFromContent(String content) {
    // Pattern để tìm URL ảnh Supabase trong content
    final supabasePattern = RegExp(
      r'https://[a-zA-Z0-9\-]+\.supabase\.co/storage/v1/object/public/chat_images/[^\s\]\)]+',
      caseSensitive: false,
    );

    final match = supabasePattern.firstMatch(content);
    if (match != null) {
      return match.group(0);
    }

    // Pattern chung cho URL ảnh
    final imageUrlPattern = RegExp(
      r'https?://[^\s\]\)]+\.(jpg|jpeg|png|gif|webp)',
      caseSensitive: false,
    );

    final imageMatch = imageUrlPattern.firstMatch(content);
    if (imageMatch != null) {
      return imageMatch.group(0);
    }

    return null;
  }

  // Helper: Làm sạch content nếu chứa URL ảnh
  String _cleanContentWithImageUrl(String content) {
    // Các pattern text mặc định khi gửi ảnh
    final patternsToRemove = [
      RegExp(r'Hãy xem và phân tích hình ảnh này:\s*https?://[^\s]+', caseSensitive: false),
      RegExp(r'\[Hình ảnh đính kèm:\s*https?://[^\]]+\]', caseSensitive: false),
      RegExp(r'https://[a-zA-Z0-9\-]+\.supabase\.co/storage/v1/object/public/chat_images/[^\s]+'),
    ];

    String cleaned = content;
    for (final pattern in patternsToRemove) {
      cleaned = cleaned.replaceAll(pattern, '').trim();
    }

    // Nếu sau khi clean chỉ còn text trống hoặc chỉ có newlines
    if (cleaned.trim().isEmpty) {
      return '';
    }

    return cleaned.trim();
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


>>>>>>> week10
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
<<<<<<< HEAD
            _showScrollToBottom = false;
=======
            _showScrollToBottomButton = false;
>>>>>>> week10
          });
        }
      }
    });
  }

<<<<<<< HEAD
  // === THÊM MỚI: Hiển thị bottom sheet để chọn nguồn ảnh ===
=======
  //Hiển thị bottom sheet để chọn nguồn ảnh
>>>>>>> week10
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

<<<<<<< HEAD
  // === THÊM MỚI: Chọn và gửi ảnh ===
  Future<void> _pickAndSendImage(ImageSource source) async {
    if (_isUploading || _sessionId == null) return;
=======
  // Upload ảnh lên Supabase Storage (sử dụng Access Token để authenticated)
  Future<String?> _uploadImageToSupabase(File imageFile) async {
    if (_accessToken == null) {
      print('❌ No access token available for upload');
      return null;
    }

    try {
      final fileBytes = await imageFile.readAsBytes();
      final fileName = 'ai_chat_${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split(Platform.pathSeparator).last}';

      final uploadUrl = Uri.parse('${ApiConfig.supabaseUrl}/storage/v1/object/chat_images/$fileName');

      print('📤 Uploading AI chat image to: $uploadUrl');
      print('📤 Using authenticated access token');

      final response = await http.post(
        uploadUrl,
        headers: {
          'Content-Type': 'image/jpeg',
          'apikey': ApiConfig.supabaseAnonKey,
          'Authorization': 'Bearer $_accessToken', // Sử dụng access token của user đã đăng nhập
        },
        body: fileBytes,
      );

      print('📤 Upload status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final publicUrl = '${ApiConfig.supabaseUrl}/storage/v1/object/public/chat_images/$fileName';
        print('✅ AI chat image uploaded: $publicUrl');
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

  // Chọn và gửi ảnh
  Future<void> _pickAndSendImage(ImageSource source) async {
    if (_isUploading || _userId == null) return;

    // Kiểm tra access token
    if (_accessToken == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng đăng nhập lại để gửi ảnh.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }
>>>>>>> week10

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

<<<<<<< HEAD
      // Upload ảnh lên Supabase Storage
      final file = File(pickedFile.path);
      final fileName = 'ai_chat_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final supabase = Supabase.instance.client;

      print('📤 Uploading image to Supabase...');
      await supabase.storage
          .from('chat_images')
          .upload(fileName, file);

      print('✅ Image uploaded: $fileName');

      // Lấy public URL
      final imageUrl = supabase.storage
          .from('chat_images')
          .getPublicUrl(fileName);

      print('🖼️ Image URL: $imageUrl');

      // Gửi tin nhắn ảnh
      await _sendImageMessage(imageUrl);
=======
      // Upload ảnh lên Supabase Storage qua HTTP request (với access token)
      final imageFile = File(pickedFile.path);
      final imageUrl = await _uploadImageToSupabase(imageFile);

      if (imageUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Upload ảnh thất bại. Vui lòng thử lại.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      print('🖼️ Image URL uploaded: $imageUrl');

      // Lưu ảnh để preview, không gửi ngay
      setState(() {
        _selectedImageUrl = imageUrl;
      });

      // Focus vào textfield để user có thể nhập text
      _focusNode.requestFocus();
>>>>>>> week10
    } catch (e) {
      print('❌ Error picking/uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
<<<<<<< HEAD
          SnackBar(content: Text('Lỗi upload ảnh: $e')),
=======
          SnackBar(
            content: Text('Lỗi chọn ảnh: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
>>>>>>> week10
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

<<<<<<< HEAD
  // === THÊM MỚI: Gửi tin nhắn ảnh ===
  Future<void> _sendImageMessage(String imageUrl) async {
    if (_sessionId == null || _isSending) return;

    print('🚀 Sending AI image message...');
    print('  Session ID: $_sessionId');
=======
  //Hủy ảnh đã chọn
  void _clearSelectedImage() {
    setState(() {
      _selectedImageUrl = null;
    });
  }

  // Gửi tin nhắn (có thể kèm ảnh nếu có)
  Future<void> _sendMessageWithOptionalImage() async {
    final text = _controller.text.trim();
    final imageUrl = _selectedImageUrl;

    // Phải có text hoặc ảnh mới được gửi
    if (text.isEmpty && imageUrl == null) return;
    if (_userId == null || _isSending) return;

    print('🚀 Sending AI message...');
    print('  User ID: $_userId');
    print('  Message: $text');
>>>>>>> week10
    print('  Image URL: $imageUrl');

    setState(() {
      _isSending = true;
    });

<<<<<<< HEAD
    // Thêm tin nhắn ảnh của user vào UI
    final userMessage = AiMessage(
      role: 'user',
      text: '[Đã gửi ảnh]',
=======
    // Tạo nội dung hiển thị cho tin nhắn user
    String displayText = text.isNotEmpty ? text : 'Xem hình ảnh này';

    // Thêm tin nhắn user vào UI
    final userMessage = AiMessage(
      role: 'user',
      text: displayText,
>>>>>>> week10
      time: DateFormat('HH:mm').format(DateTime.now()),
      imageUrl: imageUrl,
    );

    setState(() {
      _messages.add(userMessage);
<<<<<<< HEAD
=======
      _controller.clear();
      _selectedImageUrl = null;
>>>>>>> week10
    });

    _scrollToBottom();

<<<<<<< HEAD
    // Gọi API với image_url thay vì message
    try {
      final url = ApiConfig.getUri(ApiConfig.aiSend);
      print('  API URL: $url');

      final requestBody = jsonEncode({
        "session_id": _sessionId,
        "image_url": imageUrl, // Gửi image_url thay vì message
=======
    // Gọi API
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/ai/send?user_id=$_userId');
      print('  API URL: $url');

      // Tạo message text để gửi đến AI
      String messageToAI = text;
      if (imageUrl != null) {
        if (text.isNotEmpty) {
          messageToAI = '$text\n\n[Hình ảnh đính kèm: $imageUrl]';
        } else {
          messageToAI = 'Hãy xem và phân tích hình ảnh này: $imageUrl';
        }
      }

      final requestBody = jsonEncode({
        "message": messageToAI,
>>>>>>> week10
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
<<<<<<< HEAD
        final aiReply = data['reply'];

        // Thêm tin nhắn AI vào UI
        final aiMessage = AiMessage(
          role: 'assistant',
          text: aiReply,
=======
        final aiResponse = data['response'] ?? '';

        print('✅ AI Response: $aiResponse');

        // Thêm response của AI vào UI
        final aiMessage = AiMessage(
          role: 'assistant',
          text: aiResponse,
>>>>>>> week10
          time: DateFormat('HH:mm').format(DateTime.now()),
        );

        setState(() {
          _messages.add(aiMessage);
<<<<<<< HEAD
        });

        _scrollToBottom();
        await _saveChatHistory();
      } else {
        throw Exception('Failed to send AI message: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error sending AI image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ai_chat_error_send'.tr())),
        );
      }
    } finally {
      setState(() {
        _isSending = false;
      });
=======
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
>>>>>>> week10
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

<<<<<<< HEAD
    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('ai_chat_session_id');
      await prefs.remove('ai_chat_messages');

      // Tạo session mới
      await _createNewSession();
=======
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
>>>>>>> week10
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
<<<<<<< HEAD
      resizeToAvoidBottomInset: true, // === SỬA: true để UI resize khi keyboard mở ===
=======
      resizeToAvoidBottomInset: true, // true để UI resize khi keyboard mở
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
<<<<<<< HEAD
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
=======
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            //Preview ảnh đã chọn
                            if (_selectedImageUrl != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEBE3D7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        _selectedImageUrl!,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Container(
                                            width: 60,
                                            height: 60,
                                            color: Colors.grey[300],
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Color(0xFFB99668),
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 60,
                                            height: 60,
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.error, color: Colors.red),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Ảnh đã chọn - Nhập tin nhắn và nhấn gửi',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.red, size: 20),
                                      onPressed: _clearSelectedImage,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ),
                            // Input row
                            Row(
                              children: [
                                // Nút chọn ảnh
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
                                        hintText: _selectedImageUrl != null
                                            ? 'Nhập tin nhắn đi kèm ảnh...'
                                            : 'ai_chat_input_hint'.tr(),
                                        hintStyle:
                                            const TextStyle(color: Colors.black38),
                                        border: InputBorder.none,
                                      ),
                                      onSubmitted: (_) => _sendMessageWithOptionalImage(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Material(
                                  color: (_isSending || (_controller.text.trim().isEmpty && _selectedImageUrl == null))
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
                                    onPressed: _isSending ? null : _sendMessageWithOptionalImage,
                                  ),
                                ),
                              ],
>>>>>>> week10
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

<<<<<<< HEAD
                // === THÊM MỚI: Centered scroll-to-bottom button ===
                if (_showScrollToBottom)
                  Center(
=======
                // Nút scroll-to-bottom ở góc dưới phải (như trong chatbox_screen)
                if (_showScrollToBottomButton)
                  Positioned(
                    bottom: 80,
                    right: 16,
>>>>>>> week10
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

<<<<<<< HEAD
=======
  // Helper to check if text should be shown
  // Ẩn text nếu là tin nhắn ảnh mặc định (không có text đi kèm)
  bool _shouldShowText(String text) {
    if (text.isEmpty) return false;
    // Chỉ ẩn text mặc định cho tin nhắn ảnh không có caption
    if (text == 'Xem hình ảnh này') return false;
    return true;
  }

>>>>>>> week10
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
<<<<<<< HEAD
                  // === THÊM MỚI: Hiển thị ảnh nếu có ===
=======
                  //Hiển thị ảnh nếu có
>>>>>>> week10
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
<<<<<<< HEAD
                    if (message.text.isNotEmpty && message.text != '[Đã gửi ảnh]')
                      const SizedBox(height: 8),
                  ],
                  // Hiển thị text (nếu không phải "[Đã gửi ảnh]")
                  if (message.text.isNotEmpty && message.text != '[Đã gửi ảnh]')
=======
                    // Thêm spacing nếu có text cần hiển thị
                    if (_shouldShowText(message.text))
                      const SizedBox(height: 8),
                  ],
                  // Hiển thị text (nếu không phải tin nhắn ảnh với text mặc định)
                  if (_shouldShowText(message.text))
>>>>>>> week10
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

