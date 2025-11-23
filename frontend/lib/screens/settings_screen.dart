/// File: settings_screen.dart
/// Mô tả: Màn hình cài đặt với giao diện tiếng Việt

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'information_screen.dart';
import 'reputation_screen.dart';
import 'feedback_screen.dart';
import 'password_changing.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback? onProfileTap;

  const SettingsScreen({Key? key, required this.onBack, this.onProfileTap}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // State để chuyển đổi giữa "Phản hồi nhóm" và "Uy tín"
  bool _showGroupFeedback = true;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
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
                              onTap: widget.onProfileTap,
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
                                      backgroundImage: const AssetImage('assets/images/avatar.jpg'),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Thông tin user
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Sir. EUGENE',
                                          style: TextStyle(
                                            fontSize: userNameSize,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFFFFFFFF),
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                        SizedBox(height: 4 * scaleFactor),
                                        Text(
                                          'abc@gmail.com',
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
                        onTap: () {
                          // Navigate dựa vào trạng thái hiện tại
                          if (_showGroupFeedback) {
                            // Đang hiển thị "Phản hồi nhóm" → sang FeedbackScreen
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => const FeedbackScreen(),
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
                          } else {
                            // Đang hiển thị "Uy tín" → sang ReputationScreen
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => const ReputationScreen(),
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

                      SizedBox(height: verticalSpacing),

                      // Change password tile
                      _buildSettingTile(
                        icon: Icons.lock_outline,
                        title: 'change_password'.tr(),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => PasswordChangingScreen()),
                          );
                        },
                        onLeftTap: null,
                        onRightTap: null,
                        hideArrows: true,
                        height: tileHeight,
                        scaleFactor: scaleFactor,
                        paddingH: tilePaddingH,
                      ),

                      const Spacer(),
                      // Nút đăng xuất
                      Padding(
                        padding: EdgeInsets.only(
                          left: 20,
                          right: 20,
                          top: 20 * scaleFactor,
                          bottom: 20 * scaleFactor,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: buttonHeight,
                          child: ElevatedButton(
                            onPressed: () {
                              // Xử lý đăng xuất
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
                ),
              ),
            );
          },
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