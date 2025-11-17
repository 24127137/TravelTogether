import 'package:flutter/material.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import 'main_app_screen.dart';

class TravelPlanScreen extends StatefulWidget {
  const TravelPlanScreen({super.key});

  @override
  State<TravelPlanScreen> createState() => _TravelPlanScreenState();
}

class _TravelPlanScreenState extends State<TravelPlanScreen> {
  int _currentIndex = 3; // Tab "Cá nhân"

  static const List<Map<String, String>> places = [
    {"image": "https://placehold.co/300x200", "name": "Đỉnh Langbiang"},
    {"image": "https://placehold.co/300x200", "name": "Cao đẳng Sư phạm Đà Lạt"},
    {"image": "https://placehold.co/300x200", "name": "Hồ Xuân Hương"},
    {"image": "https://placehold.co/300x200", "name": "Quảng trường Lâm Viên"},
    {"image": "https://placehold.co/300x200", "name": "Chùa Linh Phước"},
    {"image": "https://placehold.co/300x200", "name": "Nhà thờ Don Bosco"},
    {"image": "https://placehold.co/300x200", "name": "Ga Đà Lạt"},
    {"image": "https://placehold.co/300x200", "name": "Dinh Bảo Đại"},
    {"image": "https://placehold.co/300x200", "name": "Nhà thờ Chánh Tòa"},
    {"image": "https://placehold.co/300x200", "name": "Thiền Viện Trúc Lâm"},
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final horizontalPadding = 16.0;
    final frameHeight = size.height * 0.75;   // giảm bớt để tránh đè vào bottom bar
    const spacing = 12.0;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // NỀN
            Positioned.fill(
              child: Image.asset(
                'assets/images/travel_plan.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: const Color(0xFF12202F)),
              ),
            ),

            // KHUNG NỘI DUNG
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Container(
                  width: double.infinity,
                  height: frameHeight,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.40),
                    border: Border.all(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(spacing),
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: places.length,
                      itemBuilder: (context, index) {
                        final place = places[index];
                        return Column(
                          children: [
                            AspectRatio(
                              aspectRatio: 1, // đảm bảo hình luôn vuông và đều
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  place['image']!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey,
                                    child: const Icon(Icons.broken_image,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              place['name']!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (newIndex) {
          // Quay về MainAppScreen với tab tương ứng
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => MainAppScreen(initialIndex: newIndex),
            ),
            (route) => false,
          );
        },
      ),
    );
  }
}
