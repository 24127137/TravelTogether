<<<<<<< HEAD
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/destination.dart';
import '../data/mock_destinations.dart';
import '../screens/destination_explore_screen.dart';
import '../widgets/enter_bar.dart'; // Import thêm
=======
/// File: destination_detail_screen.dart


import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/destination.dart';
import '../data/mock_destinations.dart';
import '../screens/destination_explore_screen.dart';
>>>>>>> 9fb9c5b (Add homepage frontend and after that implementation)

class DestinationDetailScreen extends StatelessWidget {
  final Destination? destination;
  final VoidCallback? onBack;
  final VoidCallback? onContinue;
  const DestinationDetailScreen({Key? key, this.destination, this.onBack, this.onContinue}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dest = destination ?? mockDestinations.firstWhere((d) => d.name == 'Đà Lạt');
    final size = MediaQuery.of(context).size;
<<<<<<< HEAD
    final double imageHeight = size.height * 0.55;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF7B4A22),
      body: SafeArea(
        child: SizedBox.expand(
          child: Stack(
            children: [
              // Ảnh nền
=======

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
>>>>>>> 9fb9c5b (Add homepage frontend and after that implementation)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Image.asset(
                  dest.imagePath,
                  width: size.width,
                  height: imageHeight,
<<<<<<< HEAD
                  fit: BoxFit.cover,
                ),
              ),

              // Hiệu ứng mờ
=======
                  fit: BoxFit.cover, // giữ tỉ lệ, ưu tiên cover nhưng giới hạn chiều cao
                ),
              ),

              // 2️⃣ Hiệu ứng mờ vùng dưới ảnh (blur + gradient)
>>>>>>> 9fb9c5b (Add homepage frontend and after that implementation)
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

<<<<<<< HEAD
              // Nút Quay lại
=======
              // 3️⃣ Nút Quay lại (ở SafeArea)
>>>>>>> 9fb9c5b (Add homepage frontend and after that implementation)
              Positioned(
                top: 12,
                left: 12,
                child: CircleAvatar(
<<<<<<< HEAD
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
=======
                  backgroundColor: Colors.black45,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
>>>>>>> 9fb9c5b (Add homepage frontend and after that implementation)
                    onPressed: onBack ?? () => Navigator.of(context).pop(),
                  ),
                ),
              ),

<<<<<<< HEAD
              // Nội dung
=======
              // 4️⃣ Nội dung nổi trên hiệu ứng mờ (chữ không bị mờ)
>>>>>>> 9fb9c5b (Add homepage frontend and after that implementation)
              Positioned(
                left: 16,
                right: 16,
                bottom: 0,
                child: Container(
<<<<<<< HEAD
=======
                  // Tăng padding bottom để chừa chỗ cho nút ở dưới
>>>>>>> 9fb9c5b (Add homepage frontend and after that implementation)
                  padding: const EdgeInsets.only(bottom: 100, top: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
<<<<<<< HEAD
=======
                      // Tiêu đề
>>>>>>> 9fb9c5b (Add homepage frontend and after that implementation)
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
<<<<<<< HEAD
=======

                      // Phụ đề (sử dụng trường 'province' từ model)
>>>>>>> 9fb9c5b (Add homepage frontend and after that implementation)
                      Text(
                        dest.province,
                        style: const TextStyle(
                          color: Color(0xFFF7F3E8),
                          fontSize: 18,
                          fontFamily: 'Jaro',
                        ),
                      ),
                      const SizedBox(height: 18),
<<<<<<< HEAD
                      const SizedBox(height: 20),
                      Text(
                        'description'.tr(),
                        style: const TextStyle(
=======

                      // Tags removed as requested
                      const SizedBox(height: 20),

                      // Mô tả
                      const Text(
                        'Mô tả',
                        style: TextStyle(
>>>>>>> 9fb9c5b (Add homepage frontend and after that implementation)
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
<<<<<<< HEAD
                        dest.getDescription(context.locale.languageCode),
=======
                        dest.description,
>>>>>>> 9fb9c5b (Add homepage frontend and after that implementation)
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

<<<<<<< HEAD
              // EnterButton thay thế nút cũ
=======
              // 5️⃣ Nút chuyển tiếp sang Destination_Explore_Screen
>>>>>>> 9fb9c5b (Add homepage frontend and after that implementation)
              Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: Center(
<<<<<<< HEAD
                  child: EnterButton(
                    onConfirm: onContinue ?? () {
                      print('DestinationDetail: nút Tiếp tục bấm, cityId=${dest.cityId}');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DestinationExploreScreen(cityId: dest.cityId),
                        ),
                      );
                    },
                  ),

                ),
              ),

=======
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
>>>>>>> 9fb9c5b (Add homepage frontend and after that implementation)
            ],
          ),
        ),
      ),
    );
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> 9fb9c5b (Add homepage frontend and after that implementation)
