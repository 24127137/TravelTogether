/// File: destination_detail_screen.dart


import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/destination.dart';
import '../data/mock_destinations.dart';
import '../screens/destination_explore_screen.dart';

class DestinationDetailScreen extends StatelessWidget {
  final Destination? destination;
  final VoidCallback? onBack;
  final VoidCallback? onContinue;
  const DestinationDetailScreen({Key? key, this.destination, this.onBack, this.onContinue}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dest = destination ?? mockDestinations.firstWhere((d) => d.name == 'Đà Lạt');
    final size = MediaQuery.of(context).size;

    // Chiều cao ảnh chiếm khoảng 55% màn hình — tránh phóng to quá gây vỡ ảnh
    final double imageHeight = size.height * 0.55;

    return Scaffold(
      // Khi màn hình con cần ảnh nền full-screen, cho phép nội dung kéo dài xuống dưới
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF7B4A22),
      body: SafeArea(
        // SafeArea để tránh che phần status bar; nhưng nội dung vẫn full-screen
        child: SizedBox.expand(
          child: Stack(
            children: [
              // 1️⃣ Ảnh nền (đặt ở top, vừa đủ rộng)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Image.asset(
                  dest.imagePath,
                  width: size.width,
                  height: imageHeight,
                  fit: BoxFit.cover, // giữ tỉ lệ, ưu tiên cover nhưng giới hạn chiều cao
                ),
              ),

              // 2️⃣ Hiệu ứng mờ vùng dưới ảnh (blur + gradient)
              Positioned(
                left: 0,
                right: 0,
                top: imageHeight - 50,
                bottom: 0,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withAlpha((0.15 * 255).toInt()),
                            const Color(0xFF7B4A22).withAlpha((0.95 * 255).toInt()),
                            const Color(0xFF7B4A22),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 3️⃣ Nút Quay lại (ở SafeArea)
              Positioned(
                top: 12,
                left: 12,
                child: CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: onBack ?? () => Navigator.of(context).pop(),
                  ),
                ),
              ),

              // 4️⃣ Nội dung nổi trên hiệu ứng mờ (chữ không bị mờ)
              Positioned(
                left: 16,
                right: 16,
                bottom: 0,
                child: Container(
                  // Tăng padding bottom để chừa chỗ cho nút ở dưới
                  padding: const EdgeInsets.only(bottom: 100, top: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tiêu đề
                      Text(
                        dest.name,
                        style: const TextStyle(
                          color: Color(0xFFDCC9A7),
                          fontSize: 48,
                          fontFamily: 'Jaro',
                          fontWeight: FontWeight.w400,
                          shadows: [
                            Shadow(
                              blurRadius: 8,
                              color: Colors.black54,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Phụ đề (sử dụng trường 'province' từ model)
                      Text(
                        dest.province,
                        style: const TextStyle(
                          color: Color(0xFFF7F3E8),
                          fontSize: 18,
                          fontFamily: 'Jaro',
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Tags removed as requested
                      const SizedBox(height: 20),

                      // Mô tả
                      const Text(
                        'Mô tả',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dest.description,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontFamily: 'Poppins',
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 5️⃣ Nút chuyển tiếp sang Destination_Explore_Screen
              Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: Center(
                  child: SizedBox(
                    width: 216,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(35),
                        ),
                        backgroundColor: const Color(0xFFA15C20),
                        elevation: 0,
                      ),
                      onPressed: onContinue ?? () {
                        // Debug log
                        // ignore: avoid_print
                        print('DestinationDetail: nút Tiếp tục bấm, cityId=${dest.cityId}');
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
                            builder: (_) => DestinationExploreScreen(cityId: dest.cityId),
                          ));
                        });
                      },
                      child: const Text(
                        'Tiếp tục',
                        style: TextStyle(
                          color: Color(0xFFF7F3E8),
                          fontSize: 16,
                          fontFamily: 'Climate Crisis',
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
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
