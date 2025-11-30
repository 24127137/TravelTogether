// File: custom_bottom_nav_bar.dart (ĐÃ SỬA)

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/notification_service.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

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
            top: 8,
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Tab 0: Home
              Expanded(
                child: _buildNavItemContent(context, Icons.home, 'home', 0),
              ),

              // Tab 1: Notification (Cần lắng nghe trạng thái từ Service)
              Expanded(
                child: ValueListenableBuilder<bool>(
                  // Lắng nghe biến showBadgeNotifier từ Service
                  valueListenable: NotificationService().showBadgeNotifier,
                  builder: (context, showBadge, child) {
                    // Logic: Chỉ hiện badge khi Service báo true VÀ user đang KHÔNG đứng ở tab này
                    final shouldShow = showBadge && (currentIndex != 1);

                    return _buildNavItemContent(
                      context,
                      Icons.notifications_none,
                      'notification',
                      1,
                      hasBadge: shouldShow, // Truyền trạng thái động vào đây
                    );
                  },
                ),
              ),

              // Tab 2: Messages
              Expanded(
                child: _buildNavItemContent(context, Icons.message_outlined, 'messages', 2),
              ),

              // Tab 3: Personal
              Expanded(
                child: _buildNavItemContent(context, Icons.person_outline, 'personal', 3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Đổi tên hàm và bỏ Expanded ra ngoài để dễ tùy biến cho tab Notification
  Widget _buildNavItemContent(
      BuildContext context,
      IconData icon,
      String label,
      int index, {
        bool hasBadge = false,
      }) {
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
              // Chấm tròn đỏ
              if (hasBadge)
                Positioned(
                  top: -2, // Tinh chỉnh vị trí
                  right: -2,
                  child: Container(
                    width: 9, // Kích thước vừa phải
                    height: 9,
                    decoration: BoxDecoration(
                      color: Color(0xFFA82F01),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFEDE2CC), // Viền trùng màu nền để tạo khoảng cách với icon
                        width: 1.5,
                      ),
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