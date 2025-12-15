/// File: personal_section.dart
/// Mô tả: Màn hình cá nhân với mảnh ghép puzzle đẹp mắt

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'travel_plan_screen.dart';
import 'group_state_screen.dart';

class PersonalSection extends StatelessWidget {
  final VoidCallback? onGroupStateTap;
  final VoidCallback? onTravelPlanTap;

  const PersonalSection({
    Key? key,
    this.onGroupStateTap,
    this.onTravelPlanTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    final screenSize = MediaQuery.of(context).size;

    return SafeArea(
      child: SizedBox(
        width: screenSize.width,
        height: screenSize.height,
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/canhan.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Center(
              child: SizedBox(
                width: screenSize.width * 0.8,
                height: screenSize.height * 0.55,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: (screenSize.height * 0.55) / 2 + 50,
                      child: _buildEnhancedPuzzlePiece(
                        context,
                        'itinerary'.tr(),
                        Icons.map_outlined,
                        [
                          const Color(0xFFE8D4A2),
                          const Color(0xFFDCC9A7),
                        ],
                        const Color(0xFFCD7F32),
                        isTop: true,
                        textOffset: const Offset(0, -15),
                        onTap: () {
                          onTravelPlanTap?.call();
                        },
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: (screenSize.height * 0.55) / 2 + 50,
                      child: _buildEnhancedPuzzlePiece(
                        context,
                        'status'.tr(),
                        Icons.check_circle_outline,
                        [
                          const Color(0xFFDCC9A7),
                          const Color(0xFFC8B185),
                        ],
                        const Color(0xFFCD7F32),
                        isTop: false,
                        textOffset: const Offset(0, 30),
                        onTap: () {
                          onGroupStateTap?.call();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedPuzzlePiece(
      BuildContext context,
      String text,
      IconData icon,
      List<Color> gradientColors,
      Color borderColor, {
        required bool isTop,
        required VoidCallback onTap,
        Offset textOffset = const Offset(0, 0),
      }) {
    return InkWell(
      onTap: onTap,
      child: ClipPath(
        clipper: isTop ? TopPuzzleClipper() : BottomPuzzleClipper(),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 12,
                offset: Offset(3, 6),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.white24,
                blurRadius: 6,
                offset: Offset(-2, -2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: PatternPainter(
                    isTop: isTop,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              CustomPaint(
                painter: PuzzleBorderPainter(
                  borderColor: borderColor,
                  isTop: isTop,
                ),
              ),

              // --- PHẦN CHỮ (TEXT) ---
              Center(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: isTop ? 20 : 35,
                    bottom: isTop ? 35 : 20,
                  ),
                  // SỬA: Dùng tham số textOffset được truyền vào
                  child: Transform.translate(
                    offset: textOffset,
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'AlumniSans',
                        fontSize: 60,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFF2C2416),
                        shadows: [
                          Shadow(
                            color: Colors.white.withValues(alpha: 0.5), // Sửa lại withValues nếu dùng bản mới, hoặc withOpacity(0.5)
                            offset: const Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // --- PHẦN ICON ---
              Positioned(
                right: isTop ? 16 : null,
                left: isTop ? null : 16,
                bottom: isTop ? 70 : null,
                top: isTop ? null : 70,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 40,
                    color: const Color(0xFF5D4E37),
                  ),
                ),
              ),
            ],
          ),
=======
    // Không dùng SingleChildScrollView để chặn cuộn
    return Stack(
      fit: StackFit.expand, // Ép Stack bung full màn hình, cố định khung
      children: [
        // 1. Ảnh nền (Tràn viền)
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/canhan.png'),
              fit: BoxFit.cover, // Ảnh phủ kín không gian
            ),
          ),
        ),

        // 2. Khu vực nút bấm (Cố định vị trí trên bầu trời)
        Positioned(
          // Dùng tỷ lệ màn hình để định vị thay vì số pixel cứng
          top: MediaQuery.of(context).size.height * 0.15,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min, // Chỉ chiếm diện tích cần thiết
            children: [
              // Thẻ 1: Lộ trình
              _buildLuxuryCard(
                context,
                'itinerary'.tr(),
                Icons.map_outlined,
                    () => onTravelPlanTap?.call(),
              ),

              const SizedBox(height: 20), // Khoảng cách

              // Thẻ 2: Tình trạng
              _buildLuxuryCard(
                context,
                'status'.tr(),
                Icons.check_circle_outline,
                    () => onGroupStateTap?.call(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLuxuryCard(
      BuildContext context,
      String text,
      IconData icon,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Chiều rộng nút bằng 85% màn hình
        width: MediaQuery.of(context).size.width * 0.85,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        decoration: BoxDecoration(
          // MÀU CAM HERMÈS (Có độ trong suốt nhẹ để hòa vào nền)
          color: const Color(0xFFE37547).withOpacity(0.9),

          borderRadius: BorderRadius.circular(16), // Bo góc mềm mại
          border: Border.all(
            color: Colors.white.withOpacity(0.6), // Viền trắng mảnh
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2), // Đổ bóng nhẹ
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon bên trái
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2), // Nền icon mờ
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 20),

            // Chữ ở giữa
            Expanded(
              child: Text(
                text.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Playfair Display', // Font có chân sang trọng (hoặc dùng Roboto nếu chưa có)
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5, // Giãn chữ rộng ra cho "Classy"
                  color: Colors.white,
                ),
              ),
            ),

            // Mũi tên nhỏ bên phải
            Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.7), size: 16),
          ],
>>>>>>> week10
        ),
      ),
    );
  }
}

// Tách các class ra ngoài PersonalSection
class TopPuzzleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final notchRadius = 30.0;
    final cornerRadius = 16.0;

    path.moveTo(cornerRadius, 0);
    path.quadraticBezierTo(0, 0, 0, cornerRadius);
    path.lineTo(0, h - notchRadius * 2 - cornerRadius);
    path.quadraticBezierTo(0, h - notchRadius * 2, cornerRadius, h - notchRadius * 2);
    path.lineTo(w * 0.35, h - notchRadius * 2);
    path.arcToPoint(
      Offset(w * 0.65, h - notchRadius * 2),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    path.lineTo(w - cornerRadius, h - notchRadius * 2);
    path.quadraticBezierTo(w, h - notchRadius * 2, w, h - notchRadius * 2 - cornerRadius);
    path.lineTo(w, cornerRadius);
    path.quadraticBezierTo(w, 0, w - cornerRadius, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class BottomPuzzleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final notchRadius = 30.0;
    final cornerRadius = 16.0;

    path.moveTo(0, notchRadius * 2 + cornerRadius);
    path.quadraticBezierTo(0, notchRadius * 2, cornerRadius, notchRadius * 2);
    path.lineTo(w * 0.35, notchRadius * 2);
    path.arcToPoint(
      Offset(w * 0.65, notchRadius * 2),
      radius: Radius.circular(notchRadius),
      clockwise: false,
      largeArc: false,
    );
    path.lineTo(w - cornerRadius, notchRadius * 2);
    path.quadraticBezierTo(w, notchRadius * 2, w, notchRadius * 2 + cornerRadius);
    path.lineTo(w, h - cornerRadius);
    path.quadraticBezierTo(w, h, w - cornerRadius, h);
    path.lineTo(cornerRadius, h);
    path.quadraticBezierTo(0, h, 0, h - cornerRadius);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class PuzzleBorderPainter extends CustomPainter {
  final Color borderColor;
  final bool isTop;

  PuzzleBorderPainter({required this.borderColor, required this.isTop});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final w = size.width;
    final h = size.height;
    final notchRadius = 30.0;
    final cornerRadius = 16.0;

    final path = Path();

    if (isTop) {
      path.moveTo(cornerRadius, 0);
      path.quadraticBezierTo(0, 0, 0, cornerRadius);
      path.lineTo(0, h - notchRadius * 2 - cornerRadius);
      path.quadraticBezierTo(0, h - notchRadius * 2, cornerRadius, h - notchRadius * 2);
      path.lineTo(w * 0.35, h - notchRadius * 2);
      path.arcToPoint(
        Offset(w * 0.65, h - notchRadius * 2),
        radius: Radius.circular(notchRadius),
        clockwise: false,
      );
      path.lineTo(w - cornerRadius, h - notchRadius * 2);
      path.quadraticBezierTo(w, h - notchRadius * 2, w, h - notchRadius * 2 - cornerRadius);
      path.lineTo(w, cornerRadius);
      path.quadraticBezierTo(w, 0, w - cornerRadius, 0);
      path.close();
    } else {
      path.moveTo(0, notchRadius * 2 + cornerRadius);
      path.quadraticBezierTo(0, notchRadius * 2, cornerRadius, notchRadius * 2);
      path.lineTo(w * 0.35, notchRadius * 2);
      path.arcToPoint(
        Offset(w * 0.65, notchRadius * 2),
        radius: Radius.circular(notchRadius),
        clockwise: false,
        largeArc: false,
      );
      path.lineTo(w - cornerRadius, notchRadius * 2);
      path.quadraticBezierTo(w, notchRadius * 2, w, notchRadius * 2 + cornerRadius);
      path.lineTo(w, h - cornerRadius);
      path.quadraticBezierTo(w, h, w - cornerRadius, h);
      path.lineTo(cornerRadius, h);
      path.quadraticBezierTo(0, h, 0, h - cornerRadius);
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class PatternPainter extends CustomPainter {
  final bool isTop;
  final Color color;

  PatternPainter({required this.isTop, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (var i = 0; i < 5; i++) {
      for (var j = 0; j < 8; j++) {
        final x = size.width * (j / 8) + 20;
        final y = size.height * (i / 5) + 20;
        canvas.drawCircle(Offset(x, y), 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}