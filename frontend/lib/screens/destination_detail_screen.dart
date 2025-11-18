import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/destination.dart';
import '../data/mock_destinations.dart';
import '../screens/destination_explore_screen.dart';
import '../widgets/enter_bar.dart'; // Import thêm

class DestinationDetailScreen extends StatelessWidget {
  final Destination? destination;
  final VoidCallback? onBack;
  final VoidCallback? onContinue;
  const DestinationDetailScreen({Key? key, this.destination, this.onBack, this.onContinue}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dest = destination ?? mockDestinations.firstWhere((d) => d.name == 'Đà Lạt');
    final size = MediaQuery.of(context).size;
    final double imageHeight = size.height * 0.55;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF7B4A22),
      body: SafeArea(
        child: SizedBox.expand(
          child: Stack(
            children: [
              // Ảnh nền
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Image.asset(
                  dest.imagePath,
                  width: size.width,
                  height: imageHeight,
                  fit: BoxFit.cover,
                ),
              ),

              // Hiệu ứng mờ
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

              // Nút Quay lại
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

              // Nội dung
              Positioned(
                left: 16,
                right: 16,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.only(bottom: 100, top: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                      Text(
                        dest.province,
                        style: const TextStyle(
                          color: Color(0xFFF7F3E8),
                          fontSize: 18,
                          fontFamily: 'Jaro',
                        ),
                      ),
                      const SizedBox(height: 18),
                      const SizedBox(height: 20),
                      Text(
                        'description'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dest.getDescription(context.locale.languageCode),
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

              // EnterButton thay thế nút cũ
              Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: Center(
                  child: EnterButton(
                    onConfirm: onContinue ?? () {
                      print('DestinationDetail: nút Tiếp tục bấm, cityId=${dest.cityId}');
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
                          builder: (_) => DestinationExploreScreen(cityId: dest.cityId),
                        ));
                      });
                    },
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
