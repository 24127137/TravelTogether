// File: custom_bottom_nav_bar.dart (ĐÃ SỬA)

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

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
      // Padding Bottom để chừa khoảng trống cho Safe Area (notch/home bar)
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom > 0 ? 10 : 0),
      height: 90 + MediaQuery.of(context).padding.bottom, // Tăng chiều cao để chứa Safe Area
      decoration: BoxDecoration(
        color: const Color(0xFFEDE2CC),
        // Ensure the bottom bar is rectangular (no rounded corners)
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.zero,
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 100,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Index phải khớp với vị trí trong List<Widget> _screens ở MainAppScreen
          _buildNavItem(context, Icons.home, 'Trang chủ', 0),
          _buildNavItem(context, Icons.notifications_none, 'Thông báo', 1, hasBadge: true), // Thêm hasBadge
          _buildNavItem(context, Icons.message_outlined, 'Tin nhắn', 2),
          _buildNavItem(context, Icons.person_outline, 'Cá nhân', 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context,
      IconData icon,
      String label,
      int index,
      {bool hasBadge = false} // Thêm tham số tùy chọn cho chấm tròn
      ) {
    final isSelected = index == currentIndex;
    // Đảm bảo màu sắc khớp với thiết kế gốc
    final color = isSelected ? const Color(0xFF5E3714) : const Color(0xFF868B91);

    return Expanded( // Dùng Expanded để căn đều khoảng cách tốt hơn
      child: InkWell(
        onTap: () => onTap(index), // Gọi callback onTap
        // Remove rounded tap shape -> use a rectangular (non-rounded) ink response
        borderRadius: BorderRadius.zero,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none, // Cho phép chấm tròn nằm ngoài Icon
              children: [
                Icon(icon, color: color),
                // Chấm tròn (Badge/Notification Dot)
                if (hasBadge)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const ShapeDecoration(
                        color: Colors.red, // Màu đỏ cho notification
                        shape: OvalBorder(),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
            const SizedBox(height: 4),
            // Thanh nhỏ màu nâu phía dưới tab đang chọn (theo thiết kế gốc)
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
      ),
    );
  }
}