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

    return Scaffold(
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
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                print('Không thể pop, stack rỗng');
                if (onBack != null) onBack!();
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
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/landmarks.png'), // Đường dẫn hình nền của bạn
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(), // ✅ Không cho phép scroll
          padding: EdgeInsets.fromLTRB(16, 16, 16, kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom + 16),
          child: Column(
            children: [
              const SizedBox(height: 100),
              GestureDetector(
                onTap: _triggerSearchCallback,
                child: Container(
                  width: double.infinity,
                  height: 74,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE2CC),
                    border: Border.all(color: const Color(0xFFB64B12), width: 2),
                    borderRadius: BorderRadius.circular(21),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'search_place'.tr(),
                    style: const TextStyle(
                      color: Color(0xFF3E3322),
                      fontSize: 16,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'featured_places'.tr(),
                style: const TextStyle(
                  color: Color(0xFFB99668),
                  fontSize: 16,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 380,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: cityItems.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 30),
                  itemBuilder: (context, index) {
                    final item = cityItems[index];
                    return _buildPlaceCard(
                      item.imageUrl,
                      item.name,
                      '', // Không dùng namePart2
                      item.getSubtitle(context.locale.languageCode), // Dịch subtitle
                    );
                  },
                ),
              ),
              const SizedBox(height: 25),
              Center(
                child: EnterButton(
                  onConfirm: onBeforeGroup ?? () {},  // ✅ Gọi callback sau khi animation hoàn thành
                ),
              ),
            ],
          ),
        ),
      ),// BottomNavigationBar removed: MainAppScreen provides the persistent BottomNavigationBar
    );
  }

  Widget _buildPlaceCard(
      String imageUrl,
      String namePart1,
      String namePart2,
      String subtitle,
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
                width: 282.01,
                height: 180,
                margin: const EdgeInsets.only(right: 8),
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
                      right: 16,
                      top: 16,
                      child: GestureDetector(
                        onTap: () {
                          isFavorite.value = !fav;
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
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
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    // Nội dung tên, subtitle
                    Positioned(
                      left: 20,
                      bottom: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            namePart1,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w600,
                              shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: Color(0xFFC9C8C8),
                              fontSize: 13,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w400,
                              shadows: [Shadow(color: Colors.black12, blurRadius: 1)],
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