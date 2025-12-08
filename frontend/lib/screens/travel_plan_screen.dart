// file: lib/screens/travel_plan_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:convert';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../data/mock_destinations.dart';
import 'map_route_screen.dart';

class TravelPlanScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const TravelPlanScreen({super.key, this.onBack});

  @override
  State<TravelPlanScreen> createState() => _TravelPlanScreenState();
}

class _TravelPlanScreenState extends State<TravelPlanScreen> {
  final UserService _userService = UserService();

  List<Map<String, dynamic>> _savedCities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserItinerary();
  }

  Future<void> _loadUserItinerary() async {
    // === 1. Load từ cache trước để hiển thị ngay ===
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('travel_plan_cache');

    if (cachedData != null) {
      try {
        final List<dynamic> cached = jsonDecode(cachedData);
        if (mounted && cached.isNotEmpty) {
          setState(() {
            _savedCities = cached.map((e) => Map<String, dynamic>.from(e)).toList();
            _isLoading = false;
          });
        }
      } catch (_) {}
    }

    // === 2. Load từ API (background) ===
    try {
      final token = await AuthService.getValidAccessToken();
      if (token == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final profile = await _userService.getUserProfile();
      if (profile == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final itinerary = profile['itinerary'];

      Map<String, int> cityCounts = {};

      if (itinerary != null && itinerary is Map) {
        itinerary.forEach((key, value) {
          String strKey = key.toString();
          if (strKey.contains('_')) {
            String cityName = strKey.split('_')[0];
            cityCounts[cityName] = (cityCounts[cityName] ?? 0) + 1;
          }
        });
      }

      List<Map<String, dynamic>> tempCities = [];

      for (var entry in cityCounts.entries) {
        String cityName = entry.key;
        int count = entry.value;

        String imageUrl = 'assets/images/default_city.jpg';
        try {
          final mockCity = mockDestinations.firstWhere(
                (d) => d.name.toLowerCase() == cityName.toLowerCase(),
            orElse: () => mockDestinations[0],
          );
          imageUrl = mockCity.imagePath;
        } catch (_) {
          imageUrl = "https://placehold.co/600x400/E37547/FFFFFF?text=$cityName";
        }

        tempCities.add({
          "name": cityName,
          "image": imageUrl,
          "count": count,
        });
      }

      // === 3. Lưu cache cho lần sau ===
      await prefs.setString('travel_plan_cache', jsonEncode(tempCities));

      if (mounted) {
        setState(() {
          _savedCities = tempCities;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading plan: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy kích thước màn hình để căn chỉnh
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. NỀN: HÌNH CÔ GÁI CẦM ỐNG NHÒM
          Image.asset(
            'assets/images/happy.jpg', // Nhớ đổi tên file ảnh của bạn thành tên này
            fit: BoxFit.cover,
          ),

          // 2. KHUNG CHỨA LIST THÀNH PHỐ (Ở phần bầu trời trống phía trên)
          Positioned(
            top: topPadding + 90, // Cách đỉnh một chút
            left: 20,
            right: 20,
            // Chiều cao khung chứa khoảng 50% màn hình để không che mất cô gái
            height: size.height * 0.66,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                // Hiệu ứng kính mờ hoặc màu trắng bán trong suốt
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFB64B12), width: 1.5), // Viền cam đất
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                children: [
                  // Tiêu đề
                  const Text(
                    "KẾ HOẠCH CỦA TÔI",
                    style: TextStyle(
                      fontFamily: 'Alumni Sans',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF7F3E8),
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(height: 2, width: 40, color: const Color(0xFFB64B12)),
                  const SizedBox(height: 16),

                  // Danh sách thành phố
                  Expanded(
                    child: _isLoading
                        ? ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: 4,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => const _CityCardSkeleton(),
                    )
                        : _savedCities.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: _savedCities.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final city = _savedCities[index];
                        return _buildCityCard(city);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. NÚT BACK (Góc trái trên)
          Positioned(
            top: topPadding + 10,
            left: 16,
            child: GestureDetector(
              onTap: widget.onBack ?? () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.map_outlined, size: 48, color: Colors.grey[400]),
        const SizedBox(height: 10),
        Text(
          "Chưa có địa điểm nào được tim.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        const SizedBox(height: 5),
        Text(
          "Hãy khám phá và thả tim các địa điểm bạn thích nhé!",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildCityCard(Map<String, dynamic> city) {
    return GestureDetector(
      onTap: () {
        // NAVIGATE SANG MAP VỚI FILTER LÀ TÊN THÀNH PHỐ
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MapRouteScreen(
              cityFilter: city['name'], // Truyền tên thành phố (VD: Đà Nẵng)
            ),
          ),
        );
      },
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            // Ảnh thành phố (bên trái)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: Image.asset( // Hoặc Image.network tùy dữ liệu
                city['image'],
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_,__,___) => Container(
                  width: 80, height: 80, color: Colors.grey[300],
                  child: const Icon(Icons.location_city, color: Colors.grey),
                ),
              ),
            ),

            // Thông tin (ở giữa)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      city['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3E3322),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Builder(
                      builder: (context) {
                        final countText = 'destinations_count'.tr();
                        return Row(
                          children: [
                            const Icon(Icons.place, size: 14, color: Color(0xFFE37547)),
                            const SizedBox(width: 4),
                            Text(
                              '${city['count']} $countText',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Icon mũi tên (bên phải)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loading cho city card
class _CityCardSkeleton extends StatefulWidget {
  const _CityCardSkeleton();

  @override
  State<_CityCardSkeleton> createState() => _CityCardSkeletonState();
}

class _CityCardSkeletonState extends State<_CityCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Ảnh skeleton
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: const [
                      Color(0xFFE0E0E0),
                      Color(0xFFF5F5F5),
                      Color(0xFFE0E0E0),
                    ],
                    stops: [
                      (_animation.value - 0.3).clamp(0.0, 1.0),
                      _animation.value.clamp(0.0, 1.0),
                      (_animation.value + 0.3).clamp(0.0, 1.0),
                    ],
                  ),
                ),
              ),
              // Content skeleton
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 16,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: const [
                              Color(0xFFE0E0E0),
                              Color(0xFFF5F5F5),
                              Color(0xFFE0E0E0),
                            ],
                            stops: [
                              (_animation.value - 0.3).clamp(0.0, 1.0),
                              _animation.value.clamp(0.0, 1.0),
                              (_animation.value + 0.3).clamp(0.0, 1.0),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 80,
                        height: 12,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: const [
                              Color(0xFFE0E0E0),
                              Color(0xFFF5F5F5),
                              Color(0xFFE0E0E0),
                            ],
                            stops: [
                              (_animation.value - 0.3).clamp(0.0, 1.0),
                              _animation.value.clamp(0.0, 1.0),
                              (_animation.value + 0.3).clamp(0.0, 1.0),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


