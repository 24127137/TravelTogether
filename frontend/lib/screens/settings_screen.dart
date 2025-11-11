/// File: settings_screen.dart
/// Mô tả: Màn hình cài đặt với giao diện tiếng Việt

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onBack;

  const SettingsScreen({Key? key, required this.onBack}) : super(key: key);

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
          image: AssetImage('assets/images/halong.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Phần header cam
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: const Color(0xFFA15C20).withValues(alpha: 0.85),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
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
                            color: Color(0xFFA15C20),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Color(0xFFFFFFFF),
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'settings'.tr(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEDE2CC),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  // Phần thông tin người dùng (KHÔNG có box màu be bao quanh)
                  Row(
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
                        child: const CircleAvatar(
                          radius: 35,
                          backgroundImage: AssetImage('assets/images/avatar.jpg'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Thông tin user
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sir. EUGENE',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFFFFFF),
                                fontFamily: 'Poppins',
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'abc@gmail.com',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFFEDE2CC),
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
                  const SizedBox(height: 20),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Các tùy chọn cài đặt
            _buildSettingTile(
              icon: Icons.language,
              title: context.locale.languageCode == 'en' ? 'english'.tr() : 'vietnamese'.tr(),
              onTap: () {},
              onLeftTap: () {
                // Bấm < = chuyển về tiếng Việt
                context.setLocale(const Locale('vi'));
              },
              onRightTap: () {
                // Bấm > = chuyển sang tiếng Anh
                context.setLocale(const Locale('en'));
              },
            ),
            const SizedBox(height: 12),
            _buildSettingTile(
              icon: Icons.chat_bubble_outline,
              title: _showGroupFeedback ? 'group_feedback'.tr() : 'reputation'.tr(),
              onTap: () {},
              onLeftTap: () {
                // Bấm < = quay lại "Phản hồi nhóm"
                setState(() {
                  _showGroupFeedback = true;
                });
              },
              onRightTap: () {
                // Bấm > = chuyển sang "Uy tín"
                setState(() {
                  _showGroupFeedback = false;
                });
              },
            ),
            const SizedBox(height: 12),
            _buildSettingTile(
              icon: Icons.info_outline,
              title: 'about'.tr(),
              onTap: () {},
              onLeftTap: null,
              onRightTap: null,
              hideArrows: true,
            ),
            const Spacer(),
            // Nút đăng xuất
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: SizedBox(
                width: double.infinity,
                height: 55,
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFFFFF),
                      fontFamily: 'Poppins',
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
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
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE2CC).withValues(alpha: 0.9),
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: const Color(0xFFA15C20),
                  size: 26,
                ),
                const SizedBox(width: 12),
                if (!hideArrows)
                  GestureDetector(
                    onTap: onLeftTap,
                    child: const Icon(
                      Icons.chevron_left,
                      color: Color(0xFFA15C20),
                      size: 26,
                    ),
                  ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    color: Color(0xFFA15C20),
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (!hideArrows)
                  GestureDetector(
                    onTap: onRightTap,
                    child: const Icon(
                      Icons.chevron_right,
                      color: Color(0xFFA15C20),
                      size: 26,
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


