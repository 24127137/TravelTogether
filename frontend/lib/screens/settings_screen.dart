/// File: settings_screen.dart
<<<<<<< HEAD
/// Mô tả: Màn hình cài đặt với giao diện tiếng Việt

=======
>>>>>>> week10
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'information_screen.dart';
import 'reputation_screen.dart';
<<<<<<< HEAD
import 'feedback_screen.dart';
import 'password_changing.dart';
import 'security.dart';
import 'emergency_pin.dart';
import '../services/auth_service.dart';
<<<<<<< HEAD
import 'onboarding.dart';
=======
import 'welcome.dart';
>>>>>>> 3ee7efe (done all groupapis)
import 'list_group_feedback.dart';
// Networking and storage
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
=======
import 'password_changing.dart';
import 'change_pin_screen.dart';
import 'emergency_pin.dart';
import 'security_setup_screen.dart';
import '../services/auth_service.dart';
import '../services/security_service.dart';
import 'welcome.dart';
import 'list_group_feedback.dart';
import 'first_of_all.dart';
import 'main_app_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
>>>>>>> week10
import '../config/api_config.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback? onProfileTap;
<<<<<<< HEAD
  final Map<String, dynamic>? cachedData; // === THÊM MỚI: Cached profile data ===
=======
  final Map<String, dynamic>? cachedData;
>>>>>>> week10

  const SettingsScreen({
    Key? key,
    required this.onBack,
    this.onProfileTap,
<<<<<<< HEAD
    this.cachedData, // === THÊM MỚI ===
=======
    this.cachedData,
>>>>>>> week10
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
<<<<<<< HEAD
  // State để chuyển đổi giữa "Phản hồi nhóm" và "Uy tín"
  bool _showGroupFeedback = true;
  
  // State cho dropdown Bảo mật
  bool _isSecurityExpanded = false;

  // Profile fields (loaded from GET /users/me)
=======
  bool _showGroupFeedback = true;
  bool _isSecurityExpanded = false;

>>>>>>> week10
  String _profileFullname = 'User';
  String _profileEmail = '';
  String? _profileAvatarUrl;
  String? _accessToken;

<<<<<<< HEAD
<<<<<<< HEAD
  // === THÊM MỚI: Loading state ===
  bool _isLoading = false;

=======
>>>>>>> 3ee7efe (done all groupapis)
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

<<<<<<< HEAD
  // === THÊM MỚI: Helper function để navigate với loading ===
  Future<void> _navigateWithLoading(Widget destination) async {
    setState(() => _isLoading = true);

    // Delay nhỏ để hiển thị loading (giống như đang load data)
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProfile() async {
    // === THÊM MỚI: Sử dụng cached data nếu có ===
    if (widget.cachedData != null) {
      setState(() {
        final data = widget.cachedData!;
        _profileFullname = (data['fullname'] as String?)?.trim() ?? (data['email'] as String?) ?? 'User';
        _profileEmail = (data['email'] as String?) ?? '';
        final avatar = (data['avatar_url'] as String?);
        _profileAvatarUrl = (avatar != null && avatar.isNotEmpty) ? avatar : null;
      });
      debugPrint('✅ Profile loaded from cache');
      return;
    }

    // === Fallback: Load từ API nếu không có cache ===
=======
  Future<void> _loadProfile() async {
>>>>>>> 3ee7efe (done all groupapis)
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('access_token');
      if (_accessToken == null) return;

=======
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadToken();
    _loadProfile();
  }

  Future<void> _loadToken() async {
    _accessToken = await AuthService.getValidAccessToken();
  }

  Future<void> _loadProfile() async {
    if (widget.cachedData != null) {
      final data = widget.cachedData!;
      setState(() {
        _profileFullname = (data['fullname'] as String?)?.trim() ?? (data['email'] as String?) ?? 'User';
        _profileEmail = data['email'] as String? ?? '';
        final avatar = data['avatar_url'] as String?;
        _profileAvatarUrl = (avatar != null && avatar.isNotEmpty) ? avatar : null;
      });
      return;
    }

    try {
>>>>>>> week10
      final uri = ApiConfig.getUri(ApiConfig.userProfile);
      final resp = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_accessToken',
      });

      if (resp.statusCode == 200) {
        final data = jsonDecode(utf8.decode(resp.bodyBytes));
        setState(() {
          _profileFullname = (data['fullname'] as String?)?.trim() ?? (data['email'] as String?) ?? 'User';
<<<<<<< HEAD
          _profileEmail = (data['email'] as String?) ?? '';
          final avatar = (data['avatar_url'] as String?);
          _profileAvatarUrl = (avatar != null && avatar.isNotEmpty) ? avatar : null;
        });
      } else {
<<<<<<< HEAD
=======
        // optional: print status for debugging
>>>>>>> 3ee7efe (done all groupapis)
        debugPrint('Failed to load profile: ${resp.statusCode}');
=======
          _profileEmail = data['email'] as String? ?? '';
          final avatar = data['avatar_url'] as String?;
          _profileAvatarUrl = (avatar != null && avatar.isNotEmpty) ? avatar : null;
        });
>>>>>>> week10
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

<<<<<<< HEAD
=======
  Future<void> _navigateWithLoading(Widget destination) async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => destination,
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: animation.drive(Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeInOut))),
            child: child,
          );
        },
      ),
    );

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handlePinNavigation() async {
    setState(() => _isLoading = true);
    try {
      final status = await SecurityApiService.getSecurityStatus();
      setState(() => _isLoading = false);

      if (status.needsSetup) {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const SecuritySetupScreen()));
      } else {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePinScreen()));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${'error'.tr()}: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _handleEmergencyPinNavigation() async {
    setState(() => _isLoading = true);
    try {
      final status = await SecurityApiService.getSecurityStatus();
      setState(() => _isLoading = false);

      if (status.needsSetup) {
        _showSetupRequiredDialog();
      } else {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyPinInfoScreen()));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${'error'.tr()}: $e'), backgroundColor: Colors.red));
    }
  }

  void _showSetupRequiredDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFEDE2CC),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('setup_pin_first_title'.tr(), style: const TextStyle(color: Color(0xFFA15C20), fontWeight: FontWeight.bold, fontFamily: 'Alumni Sans')),
        content: Text('setup_pin_first_desc'.tr(), style: const TextStyle(fontFamily: 'Alegreya')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('close'.tr(), style: const TextStyle(color: Color(0xFF666666), fontFamily: 'Alegreya'))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handlePinNavigation();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB64B12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('setup_now'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Alegreya')),
          ),
        ],
      ),
    );
  }

>>>>>>> week10
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
<<<<<<< HEAD
            image: DecorationImage(
              image: AssetImage('assets/images/Settings.png'),
              fit: BoxFit.cover,
            ),
=======
            image: DecorationImage(image: AssetImage('assets/images/Settings.png'), fit: BoxFit.cover),
>>>>>>> week10
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
<<<<<<< HEAD
            // Responsive scaling dựa trên chiều cao màn hình
            final screenHeight = constraints.maxHeight;

            // Scale factor: màn hình càng nhỏ, factor càng nhỏ
            // Baseline: 800px = scale 1.0, 600px = scale 0.75
            final scaleFactor = (screenHeight / 800).clamp(0.7, 1.0);

            // Tất cả sizes scale theo tỷ lệ màn hình
            final headerFontSize = 32.0 * scaleFactor;
            final avatarRadius = 35.0 * scaleFactor;
            final userNameSize = 20.0 * scaleFactor;
            final userEmailSize = 14.0 * scaleFactor;
            final verticalSpacing = 20.0 * scaleFactor;
            final tileHeight = 80.0 * scaleFactor;
            final buttonHeight = 55.0 * scaleFactor;
            final headerPadding = 20.0 * scaleFactor;
            final tilePaddingH = 20.0 * scaleFactor;
            final tilePaddingV = 18.0 * scaleFactor;

            return SingleChildScrollView(
              child: Column(
                children: [
                  // Phần header cam
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    padding: EdgeInsets.all(headerPadding),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA15C20).withValues(alpha: 0.85),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Header với nút back và tiêu đề
                        Row(
                          children: [
                            GestureDetector(
                              onTap: widget.onBack,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEDE2CC),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new,
                                  color: Color(0xFF1B1E28),
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Flexible(
                              child: Text(
                                'settings'.tr(),
                                style: TextStyle(
                                  fontSize: headerFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFEDE2CC),
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 30 * scaleFactor),
                        // Phần thông tin người dùng
                        GestureDetector(
                          onTap: () async {
                            if (widget.onProfileTap != null) {
                              setState(() => _isLoading = true);
                              await Future.delayed(const Duration(milliseconds: 300));
                              widget.onProfileTap!();
                              if (mounted) {
                                setState(() => _isLoading = false);
                              }
                            }
                          },
                          child: Row(
                            children: [
                              // Avatar với viền cam
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFFF6B00),
                                    width: 4,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: avatarRadius,
                                  backgroundImage: _profileAvatarUrl != null
                                      ? NetworkImage(_profileAvatarUrl!)
                                      : const AssetImage('assets/images/avatar.jpg') as ImageProvider<Object>,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Thông tin user
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _profileFullname,
                                      style: TextStyle(
                                        fontSize: userNameSize,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFFFFFFF),
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    SizedBox(height: 4 * scaleFactor),
                                    Text(
                                      _profileEmail,
                                      style: TextStyle(
                                        fontSize: userEmailSize,
                                        color: const Color(0xFFEDE2CC),
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Icon mũi tên
                              const Icon(
                                Icons.chevron_right,
                                color: Color(0xFFFFFFFF),
                                size: 30,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20 * scaleFactor),
                      ],
                    ),
                  ),
                  SizedBox(height: verticalSpacing),
                  // Các tùy chọn cài đặt
                  _buildSettingTile(
                    icon: Icons.language,
                    title: context.locale.languageCode == 'en' ? 'english'.tr() : 'vietnamese'.tr(),
                    onTap: () {},
                    onLeftTap: () {
                      context.setLocale(const Locale('vi'));
                    },
                    onRightTap: () {
                      context.setLocale(const Locale('en'));
                    },
                    height: tileHeight,
                    scaleFactor: scaleFactor,
                    paddingH: tilePaddingH,
                    paddingV: tilePaddingV,
                  ),
                  SizedBox(height: verticalSpacing),
                  _buildSettingTile(
                    icon: Icons.chat_bubble_outline,
                    title: _showGroupFeedback ? 'group_feedback'.tr() : 'reputation'.tr(),
                    onTap: () async {
                      // Navigate dựa vào trạng thái hiện tại
                      if (_showGroupFeedback) {
                        // Đang hiển thị "Phản hồi nhóm" → sang FeedbackScreen
<<<<<<< HEAD
                        await _navigateWithLoading(const ListGroupFeedbackScreen());
=======
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => const ListGroupFeedbackScreen(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              const begin = Offset(1.0, 0.0);
                              const end = Offset.zero;
                              const curve = Curves.easeInOut;

                              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                              var offsetAnimation = animation.drive(tween);

                              return SlideTransition(
                                position: offsetAnimation,
                                child: child,
                              );
                            },
                          ),
                        );
>>>>>>> 3ee7efe (done all groupapis)
                      } else {
                        // Đang hiển thị "Uy tín" → sang ReputationScreen
                        await _navigateWithLoading(const ReputationScreen());
                      }
                    },
                    onLeftTap: () {
                      setState(() {
                        _showGroupFeedback = true;
                      });
                    },
                    onRightTap: () {
                      setState(() {
                        _showGroupFeedback = false;
                      });
                    },
                    height: tileHeight,
                    scaleFactor: scaleFactor,
                    paddingH: tilePaddingH,
                    paddingV: tilePaddingV,
                  ),

                  SizedBox(height: verticalSpacing),

                  // security tile
                  _buildSecurityDropdown(
                    height: tileHeight,
                    scaleFactor: scaleFactor,
                    paddingH: tilePaddingH,
                  ),

                  SizedBox(height: verticalSpacing),

                  // About tile
                  _buildSettingTile(
                    icon: Icons.info_outline,
                    title: 'about'.tr(),
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => const InformationScreen(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            const begin = Offset(1.0, 0.0);
                            const end = Offset.zero;
                            const curve = Curves.easeInOut;

                            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                            var offsetAnimation = animation.drive(tween);

                            return SlideTransition(
                              position: offsetAnimation,
                              child: child,
                            );
                          },
                        ),
                      );
                    },
                    onLeftTap: null,
                    onRightTap: null,
                    hideArrows: true,
                    height: tileHeight,
                    scaleFactor: scaleFactor,
                    paddingH: tilePaddingH,
                  ),

                  SizedBox(height: verticalSpacing * 2),
                  
                  // Nút đăng xuất
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20 * scaleFactor),
                    child: SizedBox(
                      width: double.infinity,
                      height: buttonHeight,
                      child: ElevatedButton(
                        onPressed: () async {
                          // Hiển thị dialog xác nhận đăng xuất
                          final shouldLogout = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                backgroundColor: const Color(0xFFEDE2CC),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: Text(
                                  'logout_confirm_title'.tr(),
                                  style: const TextStyle(
                                    color: Color(0xFFA15C20),
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                content: Text(
                                  'logout_confirm_message'.tr(),
                                  style: const TextStyle(
                                    color: Color(0xFF1B1E28),
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: Text(
                                      'cancel'.tr(),
                                      style: const TextStyle(
                                        color: Color(0xFF666666),
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFB64B12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      'logout'.tr(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );

                          // Nếu người dùng xác nhận đăng xuất
                          if (shouldLogout == true && mounted) {
<<<<<<< HEAD
                            // Xóa token và dữ liệu xác thực
                            await AuthService.clearTokens();

                            // Chuyển về màn hình Onboarding và xóa toàn bộ stack
                            if (mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => const OnboardingScreen(),
                                ),
                                (route) => false, // Xóa toàn bộ route stack
                              );
=======
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFB99668),
                                ),
                              ),
                            );

                            try {
                              final accessToken = await AuthService.getValidAccessToken();
                              
                              if (accessToken != null) {
                                final url = ApiConfig.getUri(ApiConfig.authSignout);
                                
                                print('🔄 Calling POST /auth/signout');
                                
                                final response = await http.post(
                                  url,
                                  headers: {
                                    'Content-Type': 'application/json',
                                    'Authorization': 'Bearer $accessToken',
                                  },
                                ).timeout(const Duration(seconds: 10));

                                print('📥 Response status: ${response.statusCode}');
                                print('📥 Response body: ${response.body}');
                              }

                              await AuthService.clearTokens();

                              if (mounted) {
                                // Đóng loading dialog
                                Navigator.of(context).pop();
                                
                                // Chuyển về màn hình Welcome và xóa toàn bộ stack
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (context) => const WelcomeScreen(),
                                  ),
                                  (route) => false, // Xóa toàn bộ route stack
                                );
                              }
                            } catch (e) {
                              print('❌ Error during signout: $e');

                              await AuthService.clearTokens();
                              
                              if (mounted) {
                                Navigator.of(context).pop();

                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (context) => const WelcomeScreen(),
                                  ),
                                  (route) => false,
                                );
                              }
>>>>>>> 3ee7efe (done all groupapis)
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB64B12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 3,
                        ),
                        child: Text(
                          'logout'.tr(),
                          style: TextStyle(
                            fontSize: 18.0 * scaleFactor,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFFFFFF),
                            fontFamily: 'Poppins',
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Padding để tránh bị bottom bar đè lên
                  SizedBox(height: kBottomNavigationBarHeight + 20),
                ],
              ),
            );
          },
        ),
      ),
        ),
        // === THÊM MỚI: Loading overlay ===
        if (_isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB99668)),
              ),
            ),
          ),
=======
                final scaleFactor = (constraints.maxHeight / 800).clamp(0.7, 1.0);
                final headerFontSize = 32.0 * scaleFactor;
                final avatarRadius = 35.0 * scaleFactor;
                final userNameSize = 20.0 * scaleFactor;
                final userEmailSize = 14.0 * scaleFactor;
                final verticalSpacing = 20.0 * scaleFactor;
                final tileHeight = 80.0 * scaleFactor;
                final buttonHeight = 55.0 * scaleFactor;
                final headerPadding = 20.0 * scaleFactor;
                final tilePaddingH = 20.0 * scaleFactor;

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        padding: EdgeInsets.all(headerPadding),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA15C20).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(builder: (_) => MainAppScreen(accessToken: _accessToken ?? "", initialIndex: 0)),
                                      (route) => false,
                                    );
                                  },
                                  child: Container(
                                    width: 40, height: 40,
                                    decoration: const BoxDecoration(color: Color(0xFFEDE2CC), shape: BoxShape.circle),
                                    child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1B1E28), size: 20),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text('settings'.tr(), style: TextStyle(fontSize: headerFontSize, fontWeight: FontWeight.bold, color: const Color(0xFFEDE2CC), fontFamily: 'Alumni Sans')),
                              ],
                            ),
                            SizedBox(height: 30 * scaleFactor),
                            GestureDetector(
                              onTap: widget.onProfileTap != null ? () async {
                                setState(() => _isLoading = true);
                                await Future.delayed(const Duration(milliseconds: 300));
                                widget.onProfileTap!();
                                if (mounted) setState(() => _isLoading = false);
                              } : null,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: avatarRadius,
                                    backgroundImage: _profileAvatarUrl != null
                                        ? NetworkImage(_profileAvatarUrl!)
                                        : const AssetImage('assets/images/avatar.jpg') as ImageProvider,
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(_profileFullname, style: TextStyle(fontSize: userNameSize, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Alegreya')),
                                        SizedBox(height: 4 * scaleFactor),
                                        Text(_profileEmail, style: TextStyle(fontSize: userEmailSize, color: const Color(0xFFEDE2CC), fontFamily: 'Alegreya')),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: Colors.white, size: 30),
                                ],
                              ),
                            ),
                            SizedBox(height: 20 * scaleFactor),
                          ],
                        ),
                      ),

                      SizedBox(height: verticalSpacing),

                      // Ngôn ngữ
                      _buildSettingTile(
                        icon: Icons.language,
                        title: context.locale.languageCode == 'en' ? 'english'.tr() : 'vietnamese'.tr(),
                        onTap: () {},
                        onLeftTap: () => context.setLocale(const Locale('vi')),
                        onRightTap: () => context.setLocale(const Locale('en')),
                        height: tileHeight,
                        scaleFactor: scaleFactor,
                        paddingH: tilePaddingH,
                      ),

                      SizedBox(height: verticalSpacing),

                      // Phản hồi nhóm / Uy tín
                      _buildSettingTile(
                        icon: Icons.chat_bubble_outline,
                        title: _showGroupFeedback ? 'group_feedback'.tr() : 'reputation'.tr(),
                        onTap: () => _showGroupFeedback
                            ? _navigateWithLoading(const ListGroupFeedbackScreen())
                            : _navigateWithLoading(const ReputationScreen()),
                        onLeftTap: () => setState(() => _showGroupFeedback = true),
                        onRightTap: () => setState(() => _showGroupFeedback = false),
                        height: tileHeight,
                        scaleFactor: scaleFactor,
                        paddingH: tilePaddingH,
                      ),

                      SizedBox(height: verticalSpacing),

                      // Bảo mật
                      _buildSecurityDropdown(height: tileHeight, scaleFactor: scaleFactor, paddingH: tilePaddingH),

                      SizedBox(height: verticalSpacing),

                      // About
                      _buildSettingTile(
                        icon: Icons.info_outline,
                        title: 'about'.tr(),
                        onTap: () => Navigator.push(context, PageRouteBuilder(
                          pageBuilder: (_, a, __) => const InformationScreen(),
                          transitionsBuilder: (_, a, __, c) => SlideTransition(
                            position: a.drive(Tween(begin: const Offset(1,0), end: Offset.zero).chain(CurveTween(curve: Curves.easeInOut))),
                            child: c,
                          ),
                        )),
                        hideArrows: true,
                        height: tileHeight,
                        scaleFactor: scaleFactor,
                        paddingH: tilePaddingH,
                      ),

                      SizedBox(height: verticalSpacing * 2),

                      // Đăng xuất
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20 * scaleFactor),
                        child: SizedBox(
                          height: buttonHeight,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  backgroundColor: const Color(0xFFEDE2CC),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  title: Text('logout_confirm_title'.tr(), style: const TextStyle(color: Color(0xFFA15C20), fontWeight: FontWeight.bold)),
                                  content: Text('logout_confirm_message'.tr()),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: Text('cancel'.tr())),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB64B12)),
                                      child: Text('logout'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFB99668)))),
                                );

                                try {
                                  final token = await AuthService.getValidAccessToken();
                                  if (token != null) {
                                    await http.post(ApiConfig.getUri(ApiConfig.authSignout), headers: {'Authorization': 'Bearer $token'});
                                  }
                                  await AuthService.clearTokens();
                                  if (mounted) {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(builder: (_) => const FirstScreen()),
                                      (route) => false,
                                    );
                                  }
                                } catch (e) {
                                  await AuthService.clearTokens();
                                  if (mounted) {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                                      (route) => false,
                                    );
                                  }
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB64B12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              elevation: 3,
                            ),
                            child: Text('logout'.tr(), style: TextStyle(fontSize: 18.0 * scaleFactor, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Poppins')),
                          ),
                        ),
                      ),

                      SizedBox(height: kBottomNavigationBarHeight + 40),
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        // Loading overlay
        if (_isLoading)
          Container(color: Colors.black.withOpacity(0.3), child: const Center(child: CircularProgressIndicator(color: Color(0xFFB99668)))),
>>>>>>> week10
      ],
    );
  }

<<<<<<< HEAD
  Widget _buildSecurityDropdown({
    required double height,
    required double scaleFactor,
    required double paddingH,
  }) {
=======
  Widget _buildSecurityDropdown({required double height, required double scaleFactor, required double paddingH}) {
>>>>>>> week10
    return Column(
      children: [
        Container(
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFDCC9A7).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
<<<<<<< HEAD
            border: Border.all(
              color: const Color(0xFFA15C20),
              width: 2,
            ),
=======
            border: Border.all(color: const Color(0xFFA15C20), width: 2),
>>>>>>> week10
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
<<<<<<< HEAD
              onTap: () {
                setState(() {
                  _isSecurityExpanded = !_isSecurityExpanded;
                });
              },
=======
              onTap: () => setState(() => _isSecurityExpanded = !_isSecurityExpanded),
>>>>>>> week10
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: height * 0.2),
                child: Row(
                  children: [
<<<<<<< HEAD
                    Icon(
                      Icons.shield_outlined,
                      color: const Color(0xFFA15C20),
                      size: height * 0.3,
                    ),
                    SizedBox(width: 12 * scaleFactor),
                    Expanded(
                      child: Text(
                        'security'.tr(),
                        style: TextStyle(
                          fontSize: 17.0 * scaleFactor,
                          color: const Color(0xFFA15C20),
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isSecurityExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: const Color(0xFFA15C20),
                        size: height * 0.35,
                      ),
                    ),
=======
                    Icon(Icons.shield_outlined, color: const Color(0xFFA15C20), size: height * 0.3),
                    SizedBox(width: 12 * scaleFactor),
                    Expanded(
                      child: Text('security'.tr(), style: TextStyle(fontSize: 17.0 * scaleFactor, color: const Color(0xFFA15C20), fontWeight: FontWeight.w500, fontFamily: 'Inter'), textAlign: TextAlign.center),
                    ),
                    AnimatedRotation(turns: _isSecurityExpanded ? 0.5 : 0.0, duration: const Duration(milliseconds: 300), child: Icon(Icons.keyboard_arrow_down, color: const Color(0xFFA15C20), size: height * 0.35)),
>>>>>>> week10
                  ],
                ),
              ),
            ),
          ),
        ),
<<<<<<< HEAD

=======
>>>>>>> week10
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isSecurityExpanded
              ? Column(
                  children: [
<<<<<<< HEAD
                    SizedBox(height: 12 * scaleFactor),
                    Container(
                      height: height * 0.85,
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCC9A7).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: const Color(0xFFA15C20),
                          width: 1.5,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => PasswordChangingScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(15),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: paddingH * 0.8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.lock_outline,
                                  color: const Color(0xFFA15C20),
                                  size: height * 0.25,
                                ),
                                SizedBox(width: 12 * scaleFactor),
                                Text(
                                  'password'.tr(),
                                  style: TextStyle(
                                    fontSize: 15.0 * scaleFactor,
                                    color: const Color(0xFFA15C20),
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12 * scaleFactor),
                    Container(
                      height: height * 0.85,
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCC9A7).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: const Color(0xFFA15C20),
                          width: 1.5,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const OldPinPage()),
                            );
                          },
                          borderRadius: BorderRadius.circular(15),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: paddingH * 0.8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.pin_outlined,
                                  color: const Color(0xFFA15C20),
                                  size: height * 0.25,
                                ),
                                SizedBox(width: 12 * scaleFactor),
                                Text(
                                  'pin_code'.tr(),
                                  style: TextStyle(
                                    fontSize: 15.0 * scaleFactor,
                                    color: const Color(0xFFA15C20),
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                        ),
                      ),
                    ),
                    SizedBox(height: 12 * scaleFactor),
                    Container(
                      height: height * 0.85,
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCC9A7).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: const Color(0xFFA15C20),
                          width: 1.5,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EmergencyPinSetupScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(15),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: paddingH * 0.8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.emergency_outlined,
                                  color: const Color(0xFFA15C20),
                                  size: height * 0.25,
                                ),
                                SizedBox(width: 12 * scaleFactor),
                                Expanded(
                                  child: Text(
                                    'emergency_pin'.tr(),
                                    style: TextStyle(
                                      fontSize: 15.0 * scaleFactor,
                                      color: const Color(0xFFA15C20),
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
=======
                    const SizedBox(height: 12),
                    _buildSecurityOption(icon: Icons.lock_outline, title: 'password'.tr(), onTap: () => _navigateWithLoading(PasswordChangingScreen()), height: height, scaleFactor: scaleFactor, paddingH: paddingH),
                    const SizedBox(height: 12),
                    _buildSecurityOption(icon: Icons.pin_outlined, title: 'pin_code'.tr(), onTap: _handlePinNavigation, height: height, scaleFactor: scaleFactor, paddingH: paddingH),
                    const SizedBox(height: 12),
                    _buildSecurityOption(icon: Icons.emergency_outlined, title: 'emergency_pin'.tr(), onTap: _handleEmergencyPinNavigation, height: height, scaleFactor: scaleFactor, paddingH: paddingH),
>>>>>>> week10
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

<<<<<<< HEAD
=======
  Widget _buildSecurityOption({required IconData icon, required String title, required VoidCallback onTap, required double height, required double scaleFactor, required double paddingH}) {
    return Container(
      height: height * 0.85,
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: const Color(0xFFDCC9A7).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFA15C20), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: paddingH * 0.8),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFFA15C20), size: height * 0.25),
                SizedBox(width: 12 * scaleFactor),
                Expanded(child: Text(title, style: TextStyle(fontSize: 15.0 * scaleFactor, color: const Color(0xFFA15C20), fontWeight: FontWeight.w500, fontFamily: 'Inter'))),
              ],
            ),
          ),
        ),
      ),
    );
  }

>>>>>>> week10
  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    VoidCallback? onLeftTap,
    VoidCallback? onRightTap,
    bool hideArrows = false,
<<<<<<< HEAD
    double height = 80,
    double scaleFactor = 1.0,
    double paddingH = 16,
    double paddingV = 18,
=======
    required double height,
    required double scaleFactor,
    required double paddingH,
>>>>>>> week10
  }) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFDCC9A7).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
<<<<<<< HEAD
        border: Border.all(
          color: const Color(0xFFA15C20),
          width: 2,
        ),
=======
        border: Border.all(color: const Color(0xFFA15C20), width: 2),
>>>>>>> week10
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: height * 0.2),
            child: Row(
              children: [
<<<<<<< HEAD
                Icon(
                  icon,
                  color: const Color(0xFFA15C20),
                  size: height * 0.3,
                ),
                SizedBox(width: 8 * scaleFactor),
                if (!hideArrows)
                  GestureDetector(
                    onTap: onLeftTap,
                    child: Icon(
                      Icons.chevron_left,
                      color: const Color(0xFFA15C20),
                      size: height * 0.3,
                    ),
                  ),
                SizedBox(width: 6 * scaleFactor),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 17.0 * scaleFactor,
                      color: const Color(0xFFA15C20),
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.visible,
                    maxLines: 2,
                  ),
                ),
                SizedBox(width: 6 * scaleFactor),
                if (!hideArrows)
                  GestureDetector(
                    onTap: onRightTap,
                    child: Icon(
                      Icons.chevron_right,
                      color: const Color(0xFFA15C20),
                      size: height * 0.3,
                    ),
                  ),
=======
                Icon(icon, color: const Color(0xFFA15C20), size: height * 0.3),
                SizedBox(width: 8 * scaleFactor),
                if (!hideArrows) GestureDetector(onTap: onLeftTap, child: Icon(Icons.chevron_left, color: const Color(0xFFA15C20), size: height * 0.3)),
                SizedBox(width: 6 * scaleFactor),
                Expanded(
                  child: Text(title, style: TextStyle(fontSize: 17.0 * scaleFactor, color: const Color(0xFFA15C20), fontWeight: FontWeight.w500, fontFamily: 'Inter'), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.visible),
                ),
                SizedBox(width: 6 * scaleFactor),
                if (!hideArrows) GestureDetector(onTap: onRightTap, child: Icon(Icons.chevron_right, color: const Color(0xFFA15C20), size: height * 0.3)),
>>>>>>> week10
              ],
            ),
          ),
        ),
      ),
    );
  }
<<<<<<< HEAD
}

=======
}
>>>>>>> week10
