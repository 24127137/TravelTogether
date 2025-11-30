// File: custom_bottom_nav_bar.dart (ĐÃ SỬA)

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/notification_service.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  // Thêm callback để báo về widget cha khi tab được chọn
  final ValueChanged<int> onTap;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  // Phương thức chuyển hướng cũ đã bị loại bỏ

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80 + MediaQuery.of(context).padding.bottom,
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEDE2CC),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.1),
              blurRadius: 100,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Padding(
          padding: EdgeInsets.only(
            top: 8, // Dịch icon và text lên trên
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, Icons.home, 'home', 0),
              Expanded(
                child: ValueListenableBuilder<bool>(
                  valueListenable: NotificationService().showBadgeNotifier,
                  builder: (context, showBadge, child) {
                    // Logic: Chỉ hiện badge khi Service báo true VÀ không đang ở tab notification
                    final shouldShow = showBadge && (currentIndex != 1);
                    return _buildNavItemContent(
                        context,
                        Icons.notifications_none,
                        'notification',
                        1,
                        hasBadge: shouldShow
                    );
                  },
                ),
              ),
              _buildNavItem(context, Icons.message_outlined, 'messages', 2),
              _buildNavItem(context, Icons.person_outline, 'personal', 3),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildNavItem(BuildContext context, IconData icon, String label, int index) {
    return Expanded(
      child: _buildNavItemContent(context, icon, label, index, hasBadge: false),
    );
  }

  // Hàm build giao diện thực tế (được tách ra từ _buildNavItem cũ)
  Widget _buildNavItemContent(
      BuildContext context,
      IconData icon,
      String label,
      int index,
      {required bool hasBadge}
      ) {
    final isSelected = index == currentIndex;
    final color = isSelected ? const Color(0xFF5E3714) : const Color(0xFF868B91);

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.zero,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: color),
              // === LOGIC HIỂN THỊ CHẤM ĐỎ ===
              if (hasBadge)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const ShapeDecoration(
                      color: const Color(0xFFBA3D03),
                      shape: OvalBorder(),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label.tr(),
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          if (isSelected)
            Container(
              width: 5,
              height: 5,
              decoration: const ShapeDecoration(
                color: Color(0xFF8A724C),
                shape: OvalBorder(),
              ),
            ),
        ],
      ),
    );
  }
}