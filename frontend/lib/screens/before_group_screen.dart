/// File: before_group_screen.dart
//File này là screen tên là Group or Solo trong figma
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'group_creating.dart';
import 'join_group_screen.dart';

// Chuyển thành StatefulWidget để quản lý trạng thái của icon trái tim
class BeforeGroup extends StatefulWidget {
  final VoidCallback? onBack;
  final Function(String? destinationName)? onCreateGroup;
  final VoidCallback? onJoinGroup;

  const BeforeGroup({
    Key? key,
    this.onBack,
    this.onCreateGroup,
    this.onJoinGroup,
  }) : super(key: key);

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
    print('🟢 _handleCardTap called with: $cardType');
    
    setState(() {
      if (cardType == 'create_group_button'.tr()) {
        _isTaoNhomFav = true;
        print('🟢 Set _isTaoNhomFav = true');
      } else {
        _isGiaNhapFav = true;
        print('🟢 Set _isGiaNhapFav = true');
      }
    });
    
    await Future.delayed(const Duration(milliseconds: 300));
    print('🟡 Delay completed, mounted: $mounted');

    if (!mounted) {
      print('🔴 Widget not mounted!');
      return;
    }

    if (cardType == 'create_group_button'.tr()) {
      print('🔵 Attempting to navigate to GroupCreatingScreen...');
      
      try {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              print('✅ Building GroupCreatingScreen');
              return GroupCreatingScreen(
                destinationName: 'Đà Lạt',
                onBack: () {
                  print('GroupCreatingScreen onBack called');
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
        print('✅ Navigation completed');
      } catch (e, stackTrace) {
        print('❌ Navigation error: $e');
        print('❌ StackTrace: $stackTrace');
      }
    } else {
      print('🔵 Attempting to navigate to JoinGroupScreen...');
      
      try {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              print('✅ Building JoinGroupScreen');
              return JoinGroupScreen(
                onBack: () {
                  print('JoinGroupScreen onBack called');
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
        print('✅ Navigation completed');
      } catch (e, stackTrace) {
        print('❌ Navigation error: $e');
        print('❌ StackTrace: $stackTrace');
      }
    }
    
    // Reset favorite sau khi quay về
    if (mounted) {
      setState(() {
        _isTaoNhomFav = false;
        _isGiaNhapFav = false;
        print('🔄 Reset favorites');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sử dụng Scaffold làm cấu trúc trang cơ bản
    return PopScope(
      canPop: widget.onBack == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && widget.onBack != null) {
          widget.onBack!();
        }
      },
      child: Scaffold(
        // Cho phép body hiển thị đằng sau BottomNavBar (nếu cần) nhưng không vẽ sau AppBar của hệ thống
        extendBody: true,
        // Không dùng Column cố định, dùng Stack để xếp lớp
        body: Stack(
        fit: StackFit.expand, // Đảm bảo Stack lấp đầy màn hình
        children: [
          // Lớp 1: Ảnh nền
          Image.asset(
            'assets/images/group.png',
            fit: BoxFit.cover,
          ),

          // Lớp 2: Nội dung có thể cuộn
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                top: 100,
                left: 20,
                right: 20,
                bottom: kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom + 40,
              ),
              child: Column(
                children: [
                  // Card "Tạo nhóm"
                  // Sắp xếp lệch trái bằng Padding
                  Padding(
                    padding: const EdgeInsets.only(right: 80.0),
                    child: _buildGroupCard(
                      title: 'create_group_button'.tr(),
                      imagePath: 'assets/images/create.jpg',
                      titleColor: const Color(0xFF723B12),
                      isFavorite: _isTaoNhomFav,
                      onTap: () => _handleCardTap('create_group_button'.tr()),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Card "Gia nhập"
                  // Sắp xếp lệch phải bằng Padding
                  Padding(
                    padding: const EdgeInsets.only(left: 80.0),
                    child: _buildGroupCard(
                      title: 'join_button'.tr(),
                      imagePath: 'assets/images/join.jpg',
                      titleColor: const Color(0xFF8A724C),
                      isFavorite: _isGiaNhapFav,
                      onTap: () => _handleCardTap('join_button'.tr()),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Lớp 3: Header cố định
          _buildHeader(),
        ],
      ),
      ),
    );
  }

  /// Widget xây dựng Header (giữ nguyên code Positioned của bạn)
  Widget _buildHeader() {
    // Move header slightly down so top elements are not flush with screen edge
    return Positioned(
      top: 8,
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
                color: const Color(0xFFF0E7D8),
              ),
            ),
            // Back icon only (no circular background). Keep tap area accessible.
            Positioned(
              left: 12,
              top: 22, // nudge the icon down a bit
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  if (widget.onBack != null) {
                    widget.onBack!();
                  } else {
                    Navigator.of(context).maybePop();
                  }
                },
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: Color(0xFF1B1E28),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
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
        height: 295,
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
                    height: 240,
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
            Positioned(
              bottom: 1,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 25,
                    fontFamily: 'Alumni Sans',
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
}