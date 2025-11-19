/// File: before_group_screen.dart
//File này là screen tên là Group or Solo trong figma
import 'package:flutter/material.dart';


// Chuyển thành StatefulWidget để quản lý trạng thái của icon trái tim
class BeforeGroup extends StatefulWidget {
  final VoidCallback? onBack;
  const BeforeGroup({Key? key, this.onBack}) : super(key: key);

  @override
  State<BeforeGroup> createState() => _BeforeGroupState();
}

class _BeforeGroupState extends State<BeforeGroup> {
  // Biến trạng thái để theo dõi icon trái tim
  bool _isTaoNhomFav = false;
  bool _isGiaNhapFav = false;

  // Hàm xử lý logic khi nhấn vào card
  // Dùng 'async' để có thể đợi (await) trước khi chuyển trang
  void _handleCardTap(String cardType) async {
    setState(() {
      if (cardType == 'Tạo nhóm') {
        _isTaoNhomFav = true;
      } else {
        _isGiaNhapFav = true;
      }
    });
    await Future.delayed(const Duration(milliseconds: 300));
    if (widget.onBack != null) widget.onBack!();
  }

  @override
  Widget build(BuildContext context) {
    // Sử dụng Scaffold làm cấu trúc trang cơ bản
    return Scaffold(
      // Cho phép body hiển thị đằng sau BottomNavBar (nếu cần) nhưng không vẽ sau AppBar của hệ thống
      extendBody: true,
      // Không dùng Column cố định, dùng Stack để xếp lớp
      body: Stack(
        fit: StackFit.expand, // Đảm bảo Stack lấp đầy màn hình
        children: [
          // Lớp 1: Ảnh nền
          Image.asset(
            'assets/images/danang.jpg',
            fit: BoxFit.cover,
          ),

          // Lớp 2: Nội dung có thể cuộn
          // Sử dụng SingleChildScrollView để tránh lỗi overflow
          SingleChildScrollView(
            padding: EdgeInsets.only(bottom: kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom + 16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  // Thêm khoảng trống để né Header
                  const SizedBox(height: 100),

                  // Card "Tạo nhóm"
                  // Sắp xếp lệch trái bằng Padding
                  Padding(
                    padding: const EdgeInsets.only(right: 80.0),
                    child: _buildGroupCard(
                      title: 'Tạo nhóm',
                      imagePath: 'assets/images/dalat.jpg',
                      titleColor: const Color(0xFF723B12),
                      isFavorite: _isTaoNhomFav,
                      onTap: () => _handleCardTap('Tạo nhóm'),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Card "Gia nhập"
                  // Sắp xếp lệch phải bằng Padding
                  Padding(
                    padding: const EdgeInsets.only(left: 80.0),
                    child: _buildGroupCard(
                      title: 'Gia nhập',
                      imagePath: 'assets/images/phuquoc.jpg',
                      titleColor: const Color(0xFF8A724C),
                      isFavorite: _isGiaNhapFav,
                      onTap: () => _handleCardTap('Gia nhập'),
                    ),
                  ),

                  // Thêm khoảng trống để né BottomNavBar
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),

          // Lớp 3: Header cố định
          _buildHeader(),

          // Lớp 4: (Đã loại bỏ Bottom Navigation Bar để sử dụng bar từ MainAppScreen)
        ],
      ),
    );
  }

  /// Widget xây dựng Header (giữ nguyên code Positioned của bạn)
  Widget _buildHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 70, // Chiều cao của header
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: MediaQuery.of(context).size.width, // Full width
                height: 70,
                color: const Color(0x70DCC9A7),
              ),
            ),
            Positioned(
              left: 72,
              top: 1,
              child: Container(
                width: 100,
                height: 69,
                color: const Color(0xFFF0E7D8),
              ),
            ),
            Positioned(
              left: 15,
              top: 21,
              child: Container(
                width: 53,
                height: 42,
                color: const Color(0xFFF0E7D8),
              ),
            ),
            Positioned(
              left: 312,
              top: 18,
              child: Container(
                width: 88,
                height: 42,
                color: const Color(0xFFF0E7D8),
              ),
            ),
            // Centered header text, moved slightly lower
            Positioned(
              top: 30,
              left: 0,
              right: 0,
              child: const Center(
                child: Text(
                  'Travel together',
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: 'Bangers',
                    color: Colors.black,
                    decoration: TextDecoration.none, // Xóa gạch chân
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget tái sử dụng cho card "Tạo nhóm" và "Gia nhập"
  Widget _buildGroupCard({
    required String title,
    required String imagePath,
    required Color titleColor,
    required bool isFavorite,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 295,
        height: 333,
        decoration: BoxDecoration(
          color: const Color(0xFFEDE2CC),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Stack(
                children: [
                  Container(
                    height: 257,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: AssetImage(imagePath),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
            // Text (đặt ở dưới cùng, nhích xuống để tránh chạm ảnh)
            Positioned(
              bottom: 5,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 35,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Note: Bottom navigation logic is handled by MainAppScreen; this screen only shows content.
}