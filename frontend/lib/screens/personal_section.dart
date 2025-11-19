/// File: personal_section.dart
/// Mô tả: Màn hình cá nhân với mảnh ghép puzzle đẹp mắt

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'travel_plan_screen.dart';

class PersonalSection extends StatelessWidget {
  const PersonalSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return SafeArea(
      child: SizedBox(
        width: screenSize.width,
        height: screenSize.height,
        child: Stack(
          children: [
            // Full-screen background
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

            // 2 mảnh ghép puzzle với hiệu ứng đẹp
            Center(
              child: SizedBox(
                width: screenSize.width * 0.8,
                height: screenSize.height * 0.55,
                child: Stack(
                  children: [
                    // Mảnh ghép trên
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
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TravelPlanScreen(),
                            ),
                          );
                        },
                      ),
                    ),

                    // Mảnh ghép dưới
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
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Scaffold(
                                appBar: AppBar(title: Text('status'.tr())),
                                body: Center(child: Text('status'.tr())),
                              ),
                            ),
                          );
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
              // Pattern decoration (optional)
              Positioned.fill(
                child: CustomPaint(
                  painter: PatternPainter(
                    isTop: isTop,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),

              // Border
              CustomPaint(
                painter: PuzzleBorderPainter(
                  borderColor: borderColor,
                  isTop: isTop,
                ),
              ),

              // Text ở giữa
              Center(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: isTop ? 20 : 35,
                    bottom: isTop ? 35 : 20,
                  ),
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'AlumniSans',
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFF2C2416),
                      shadows: [
                        Shadow(
                          color: Colors.white.withOpacity(0.5),
                          offset: const Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Icon ở góc
              Positioned(
                // Lộ trình (isTop = true): góc phải dưới
                // Tình trạng (isTop = false): góc trái trên
                right: isTop ? 16 : null,
                left: isTop ? null : 16,
                bottom: isTop ? 70 : null,
                top: isTop ? null : 70, // Tránh phần lõm
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
        ),
      ),
    );
  }
}

// Clipper cho mảnh ghép trên (có lồi ở dưới)
class TopPuzzleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final notchRadius = 30.0;
    final cornerRadius = 16.0;

    // Bo góc trên trái
    path.moveTo(cornerRadius, 0);
    path.quadraticBezierTo(0, 0, 0, cornerRadius);
    path.lineTo(0, h - notchRadius * 2 - cornerRadius);

    // Bo góc dưới trái (trước lồi)
    path.quadraticBezierTo(0, h - notchRadius * 2, cornerRadius, h - notchRadius * 2);
    path.lineTo(w * 0.35, h - notchRadius * 2);

    // Lồi hình tròn ở dưới
    path.arcToPoint(
      Offset(w * 0.65, h - notchRadius * 2),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );

    path.lineTo(w - cornerRadius, h - notchRadius * 2);

    // Bo góc dưới phải (sau lồi)
    path.quadraticBezierTo(w, h - notchRadius * 2, w, h - notchRadius * 2 - cornerRadius);
    path.lineTo(w, cornerRadius);

    // Bo góc trên phải
    path.quadraticBezierTo(w, 0, w - cornerRadius, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// Clipper cho mảnh ghép dưới (có lõm ở trên - khớp với lồi của mảnh trên)
class BottomPuzzleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final notchRadius = 30.0;
    final cornerRadius = 16.0;

    // Bắt đầu từ góc trên trái (sau lõm)
    path.moveTo(0, notchRadius * 2 + cornerRadius);
    path.quadraticBezierTo(0, notchRadius * 2, cornerRadius, notchRadius * 2);
    path.lineTo(w * 0.35, notchRadius * 2);

    // Lõm hình tròn ở trên (khớp với lồi của mảnh trên)
    path.arcToPoint(
      Offset(w * 0.65, notchRadius * 2),
      radius: Radius.circular(notchRadius),
      clockwise: false, // Lõm vào trong
      largeArc: false,
    );

    path.lineTo(w - cornerRadius, notchRadius * 2);

    // Bo góc trên phải
    path.quadraticBezierTo(w, notchRadius * 2, w, notchRadius * 2 + cornerRadius);
    path.lineTo(w, h - cornerRadius);

    // Bo góc dưới phải
    path.quadraticBezierTo(w, h, w - cornerRadius, h);
    path.lineTo(cornerRadius, h);

    // Bo góc dưới trái
    path.quadraticBezierTo(0, h, 0, h - cornerRadius);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}


// Painter để vẽ viền cho mảnh ghép
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
      // Viền cho mảnh dưới (có lõm ở trên)
      path.moveTo(0, notchRadius * 2 + cornerRadius);
      path.quadraticBezierTo(0, notchRadius * 2, cornerRadius, notchRadius * 2);
      path.lineTo(w * 0.35, notchRadius * 2);
      path.arcToPoint(
        Offset(w * 0.65, notchRadius * 2),
        radius: Radius.circular(notchRadius),
        clockwise: false,
        largeArc: false,// Lõm vào trong
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

// Painter để vẽ pattern trang trí
class PatternPainter extends CustomPainter {
  final bool isTop;
  final Color color;

  PatternPainter({required this.isTop, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Vẽ các chấm tròn trang trí
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
