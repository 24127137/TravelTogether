/// File: destination_explore_screen.dart
/// Mô tả: Màn hình khám phá địa điểm theo thành phố, giao diện tiếng Việt.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../data/mock_explore_items.dart';
import '../widgets/enter_bar.dart';

class DestinationExploreScreen extends StatelessWidget {
  final String cityId;
  final int? currentIndex;
  final void Function(int)? onTabChange;
  final VoidCallback? onBack;
  final VoidCallback? onBeforeGroup;
  final VoidCallback? onSearchPlace; // Thêm callback
  const DestinationExploreScreen({Key? key, required this.cityId, this.currentIndex, this.onTabChange, this.onBack, this.onBeforeGroup, this.onSearchPlace}) : super(key: key);

  void _triggerSearchCallback() {
    if (onSearchPlace != null) {
      onSearchPlace!();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lọc các địa điểm theo cityId
    final cityItems = mockExploreItems.where((item) => item.cityId == cityId).toList();

    return PopScope(
      canPop: onBack == null, // Cho phép pop nếu không có callback
      onPopInvokedWithResult: (didPop, result) {
        // Khi người dùng vuốt để quay lại, gọi callback onBack giống như nút back
        if (!didPop && onBack != null) {
          onBack!();
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        extendBody: true,
        appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              // Quay về destination detail screen
              if (onBack != null) {
                onBack!();
              }
            },
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: const CircleAvatar(
              backgroundImage: AssetImage('assets/images/avatar.jpg'),
              radius: 18,
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image kéo dài toàn bộ màn hình
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/landmarks.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Nội dung cuộn
          LayoutBuilder(
            builder: (context, constraints) {
              // Responsive scaling dựa trên chiều cao màn hình
              final screenHeight = constraints.maxHeight;

              // Scale factor: baseline 800px = 1.0
              final scaleFactor = (screenHeight / 800).clamp(0.7, 1.0);

              // Tất cả sizes scale theo tỷ lệ
              final topPadding = 100.0 * scaleFactor;
              final searchBarHeight = 74.0 * scaleFactor;
              final searchBarFontSize = 16.0 * scaleFactor;
              final titleFontSize = 16.0 * scaleFactor;
              final cardHeight = 380.0 * scaleFactor;
              final cardWidth = 282.01 * scaleFactor;
              final spacing1 = 12.0 * scaleFactor;
              final spacing2 = 16.0 * scaleFactor;
              final spacing3 = 25.0 * scaleFactor;

              // Tính toán bottom padding để tránh EnterButton cố định
              final bottomPadding = MediaQuery.of(context).padding.bottom +
                                     kBottomNavigationBarHeight +
                                     90.0; // Thêm khoảng trống cho EnterButton

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
                child: Column(
                  children: [
                    SizedBox(height: topPadding),
                    GestureDetector(
                      onTap: _triggerSearchCallback,
                      child: Container(
                        width: double.infinity,
                        height: searchBarHeight,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE2CC),
                          border: Border.all(color: const Color(0xFFB64B12), width: 2),
                          borderRadius: BorderRadius.circular(21),
                        ),
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.symmetric(horizontal: 24 * scaleFactor),
                        child: Text(
                          'search_place'.tr(),
                          style: TextStyle(
                            color: const Color(0xFF3E3322),
                            fontSize: searchBarFontSize,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: spacing1),
                    Text(
                      'featured_places'.tr(),
                      style: TextStyle(
                        color: const Color(0xFFB99668),
                        fontSize: titleFontSize,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: spacing2),
                    SizedBox(
                      height: cardHeight,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: cityItems.length,
                        separatorBuilder: (_, __) => SizedBox(width: 30 * scaleFactor),
                        itemBuilder: (context, index) {
                          final item = cityItems[index];
                          return _buildPlaceCard(
                            item.imageUrl,
                            item.name,
                            '', // Không dùng namePart2
                            item.getSubtitle(context.locale.languageCode), // Dịch subtitle
                            cardWidth,
                            scaleFactor,
                          );
                        },
                      ),
                    ),
                    SizedBox(height: spacing3),
                  ],
                ),
              );
            },
          ),
          // EnterButton cố định ở vị trí giống destination_detail_screen
          Positioned(
            left: 0,
            right: 0,
            bottom: kBottomNavigationBarHeight + 35,
            child: Center(
              child: EnterButton(
                onConfirm: onBeforeGroup ?? () {},
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildPlaceCard(
      String imageUrl,
      String namePart1,
      String namePart2,
      String subtitle,
      double cardWidth,
      double scaleFactor,
      ) {
    return StatefulBuilder(
      builder: (context, setState) {
        final ValueNotifier<bool> isFavorite = ValueNotifier(false);
        return ValueListenableBuilder<bool>(
          valueListenable: isFavorite,
          builder: (context, fav, _) {
            return GestureDetector(
              onTap: () {
                isFavorite.value = !fav;
              },
              child: Container(
                width: cardWidth,
                height: 180 * scaleFactor,
                margin: EdgeInsets.only(right: 8 * scaleFactor),
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.asset(imageUrl, fit: BoxFit.cover),
                      ),
                    ),
                    // Trái tim ở góc phải trên
                    Positioned(
                      right: 16 * scaleFactor,
                      top: 16 * scaleFactor,
                      child: GestureDetector(
                        onTap: () {
                          isFavorite.value = !fav;
                        },
                        child: Container(
                          width: 32 * scaleFactor,
                          height: 32 * scaleFactor,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16 * scaleFactor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.favorite,
                            color: fav ? Colors.red : Colors.black.withValues(alpha: 0.2),
                            size: 22 * scaleFactor,
                          ),
                        ),
                      ),
                    ),
                    // Nội dung tên, subtitle
                    Positioned(
                      left: 20 * scaleFactor,
                      bottom: 20 * scaleFactor,
                      right: 20 * scaleFactor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            namePart1,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16 * scaleFactor,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w600,
                              shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
                            ),
                          ),
                          SizedBox(height: 4 * scaleFactor),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: const Color(0xFFC9C8C8),
                              fontSize: 13 * scaleFactor,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w400,
                              shadows: const [Shadow(color: Colors.black12, blurRadius: 1)],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}