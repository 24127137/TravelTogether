
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../screens/travel_plan_screen.dart';

class KhungCNhN extends StatelessWidget {
  const KhungCNhN({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tileBg = const Color(0xFFDCC9A7);
    final borderColor = const Color(0xFFCD7F32);

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
                  image: AssetImage('assets/images/nen_canhantrang.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Overlayed tiles - positioned near the lower part but inside the screen
            Positioned(
              left: 16,
              right: 16,
              bottom: 40,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  final tileWidth = (availableWidth - 16) / 2;
                  final maxTileHeight = screenSize.height * 0.28;
                  final tileHeight = math.min(209.0, maxTileHeight);

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: tileWidth,
                        height: tileHeight,
                        child: _buildTile(
                          context,
                          'Lộ Trình',
                          tileBg,
                          borderColor,
                              () {
                            // Navigate to travel_plan_screen.dart
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TravelPlanScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: tileWidth,
                        height: tileHeight,
                        child: _buildTile(
                          context,
                          'Tình Trạng',
                          tileBg,
                          borderColor,
                              () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Scaffold(
                                  appBar: AppBar(title: const Text('Tình Trạng')),
                                  body: const Center(child: Text('Trang Tình Trạng')),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(
      BuildContext context,
      String text,
      Color bgColor,
      Color borderColor,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'AlumniSans',
            fontSize: 30,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
