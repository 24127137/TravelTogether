/// File: settings_screen.dart
/// Mô tả: Màn hình cài đặt với giao diện tiếng Việt

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'information_screen.dart';
import 'reputation_screen.dart';
import 'password_changing.dart';
import 'security.dart';
import 'emergency_pin.dart';
import '../services/auth_service.dart';
import 'welcome.dart';
import 'list_group_feedback.dart';
// Networking and storage
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'first_of_all.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback? onProfileTap;
  final Map<String, dynamic>? cachedData; // === THÊM MỚI: Cached profile data ===

  const SettingsScreen({
    Key? key,
    required this.onBack,
    this.onProfileTap,
    this.cachedData, // === THÊM MỚI ===
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // State để chuyển đổi giữa "Phản hồi nhóm" và "Uy tín"
  bool _showGroupFeedback = true;
  
  // State cho dropdown Bảo mật
  bool _isSecurityExpanded = false;

  // Profile fields (loaded from GET /users/me)
  String _profileFullname = 'User';
  String _profileEmail = '';
  String? _profileAvatarUrl;
  String? _accessToken;

  // === THÊM MỚI: Loading state ===
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

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
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('access_token');
      if (_accessToken == null) return;

      final uri = ApiConfig.getUri(ApiConfig.userProfile);
      final resp = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_accessToken',
      });

      if (resp.statusCode == 200) {
        final data = jsonDecode(utf8.decode(resp.bodyBytes));
        setState(() {
          _profileFullname = (data['fullname'] as String?)?.trim() ?? (data['email'] as String?) ?? 'User';
          _profileEmail = (data['email'] as String?) ?? '';
          final avatar = (data['avatar_url'] as String?);
          _profileAvatarUrl = (avatar != null && avatar.isNotEmpty) ? avatar : null;
        });
      } else {
        debugPrint('Failed to load profile: ${resp.statusCode}');
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/Settings.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
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
                                ),
                                child: CircleAvatar(
                                  radius: avatarRadius,
                                  backgroundImage: _profileAvatarUrl != null
                                      ? NetworkImage(_profileAvatarUrl!)
                                      : const AssetImage('assets/images/avatar.jpg') as ImageProvider<Object>,
                                ),
                              ),
                              const SizedBox(width: 20),
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
                        await _navigateWithLoading(const ListGroupFeedbackScreen());
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
                                    builder: (context) => const FirstScreen(),
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
      ],
    );
  }

  Widget _buildSecurityDropdown({
    required double height,
    required double scaleFactor,
    required double paddingH,
  }) {
    return Column(
      children: [
        Container(
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFDCC9A7).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFA15C20),
              width: 2,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _isSecurityExpanded = !_isSecurityExpanded;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: height * 0.2),
                child: Row(
                  children: [
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
                  ],
                ),
              ),
            ),
          ),
        ),

        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isSecurityExpanded
              ? Column(
                  children: [
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
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    VoidCallback? onLeftTap,
    VoidCallback? onRightTap,
    bool hideArrows = false,
    double height = 80,
    double scaleFactor = 1.0,
    double paddingH = 16,
    double paddingV = 18,
  }) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFDCC9A7).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFA15C20),
          width: 2,
        ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

