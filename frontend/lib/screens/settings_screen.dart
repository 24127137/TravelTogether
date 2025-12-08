/// File: settings_screen.dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'information_screen.dart';
import 'reputation_screen.dart';
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
import '../config/api_config.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback? onProfileTap;
  final Map<String, dynamic>? cachedData;

  const SettingsScreen({
    Key? key,
    required this.onBack,
    this.onProfileTap,
    this.cachedData,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showGroupFeedback = true;
  bool _isSecurityExpanded = false;

  String _profileFullname = 'User';
  String _profileEmail = '';
  String? _profileAvatarUrl;
  String? _accessToken;

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
      final uri = ApiConfig.getUri(ApiConfig.userProfile);
      final resp = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_accessToken',
      });

      if (resp.statusCode == 200) {
        final data = jsonDecode(utf8.decode(resp.bodyBytes));
        setState(() {
          _profileFullname = (data['fullname'] as String?)?.trim() ?? (data['email'] as String?) ?? 'User';
          _profileEmail = data['email'] as String? ?? '';
          final avatar = data['avatar_url'] as String?;
          _profileAvatarUrl = (avatar != null && avatar.isNotEmpty) ? avatar : null;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
    }
  }

  void _showSetupRequiredDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFEDE2CC),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Thiết lập mã PIN bảo mật trước', style: TextStyle(color: Color(0xFFA15C20), fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
        content: Text('Bạn cần thiết lập mã PIN bảo mật trước khi tạo mã PIN khẩn cấp.', style: TextStyle(fontFamily: 'Poppins')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Đóng', style: TextStyle(color: Color(0xFF666666)))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handlePinNavigation();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB64B12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('Thiết lập ngay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(image: AssetImage('assets/images/Settings.png'), fit: BoxFit.cover),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
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
                                Text('settings'.tr(), style: TextStyle(fontSize: headerFontSize, fontWeight: FontWeight.bold, color: const Color(0xFFEDE2CC), fontFamily: 'Poppins')),
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
                                        Text(_profileFullname, style: TextStyle(fontSize: userNameSize, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Poppins')),
                                        SizedBox(height: 4 * scaleFactor),
                                        Text(_profileEmail, style: TextStyle(fontSize: userEmailSize, color: const Color(0xFFEDE2CC), fontFamily: 'Poppins')),
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
      ],
    );
  }

  Widget _buildSecurityDropdown({required double height, required double scaleFactor, required double paddingH}) {
    return Column(
      children: [
        Container(
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFDCC9A7).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFA15C20), width: 2),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _isSecurityExpanded = !_isSecurityExpanded),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: height * 0.2),
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined, color: const Color(0xFFA15C20), size: height * 0.3),
                    SizedBox(width: 12 * scaleFactor),
                    Expanded(
                      child: Text('security'.tr(), style: TextStyle(fontSize: 17.0 * scaleFactor, color: const Color(0xFFA15C20), fontWeight: FontWeight.w500, fontFamily: 'Inter'), textAlign: TextAlign.center),
                    ),
                    AnimatedRotation(turns: _isSecurityExpanded ? 0.5 : 0.0, duration: const Duration(milliseconds: 300), child: Icon(Icons.keyboard_arrow_down, color: const Color(0xFFA15C20), size: height * 0.35)),
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
                    const SizedBox(height: 12),
                    _buildSecurityOption(icon: Icons.lock_outline, title: 'password'.tr(), onTap: () => _navigateWithLoading(PasswordChangingScreen()), height: height, scaleFactor: scaleFactor, paddingH: paddingH),
                    const SizedBox(height: 12),
                    _buildSecurityOption(icon: Icons.pin_outlined, title: 'pin_code'.tr(), onTap: _handlePinNavigation, height: height, scaleFactor: scaleFactor, paddingH: paddingH),
                    const SizedBox(height: 12),
                    _buildSecurityOption(icon: Icons.emergency_outlined, title: 'emergency_pin'.tr(), onTap: _handleEmergencyPinNavigation, height: height, scaleFactor: scaleFactor, paddingH: paddingH),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

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

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    VoidCallback? onLeftTap,
    VoidCallback? onRightTap,
    bool hideArrows = false,
    required double height,
    required double scaleFactor,
    required double paddingH,
  }) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFDCC9A7).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFA15C20), width: 2),
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
                Icon(icon, color: const Color(0xFFA15C20), size: height * 0.3),
                SizedBox(width: 8 * scaleFactor),
                if (!hideArrows) GestureDetector(onTap: onLeftTap, child: Icon(Icons.chevron_left, color: const Color(0xFFA15C20), size: height * 0.3)),
                SizedBox(width: 6 * scaleFactor),
                Expanded(
                  child: Text(title, style: TextStyle(fontSize: 17.0 * scaleFactor, color: const Color(0xFFA15C20), fontWeight: FontWeight.w500, fontFamily: 'Inter'), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.visible),
                ),
                SizedBox(width: 6 * scaleFactor),
                if (!hideArrows) GestureDetector(onTap: onRightTap, child: Icon(Icons.chevron_right, color: const Color(0xFFA15C20), size: height * 0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}