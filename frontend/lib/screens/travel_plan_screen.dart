// file: lib/screens/travel_plan_screen.dart

import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../data/mock_destinations.dart'; // Import để lấy ảnh đại diện thành phố
import 'map_route_screen.dart'; // Import để navigate
import 'dart:ui'; // Để dùng ImageFilter nếu cần làm mờ

class TravelPlanScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const TravelPlanScreen({super.key, this.onBack});

  @override
  State<TravelPlanScreen> createState() => _TravelPlanScreenState();
}

class _TravelPlanScreenState extends State<TravelPlanScreen> {
  final UserService _userService = UserService();

  // List chứa các thành phố có trong itinerary của user
  // Cấu trúc: { "name": "Đà Nẵng", "image": "assets/...", "count": "3 địa điểm" }
  List<Map<String, dynamic>> _savedCities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserItinerary();
  }

  Future<void> _loadUserItinerary() async {
    setState(() => _isLoading = true);
    try {
      final token = await AuthService.getValidAccessToken();
      if (token == null) throw Exception("Vui lòng đăng nhập");

      final profile = await _userService.getUserProfile();
      if (profile == null) throw Exception("Lỗi tải thông tin");

      final itinerary = profile['itinerary'];

      // Logic gom nhóm địa điểm theo thành phố
      Map<String, int> cityCounts = {};

      if (itinerary != null && itinerary is Map) {
        itinerary.forEach((key, value) {
          String strKey = key.toString();

          // Format: "Hà Nội_1", "Đà Nẵng_2", ...
          // Lấy tên thành phố từ phần trước dấu "_"
          if (strKey.contains('_')) {
            String cityName = strKey.split('_')[0];

            if (cityName.isNotEmpty) {
              cityCounts[cityName] = (cityCounts[cityName] ?? 0) + 1;
            }
          }
        });
      }

      // Chuyển Map thành List để hiển thị
      List<Map<String, dynamic>> tempCities = [];

      for (var entry in cityCounts.entries) {
        String cityName = entry.key;
        int count = entry.value;

        // Tìm ảnh đại diện cho thành phố từ mock data
        String imageUrl = 'assets/images/default_city.jpg'; // Ảnh fallback
        try {
          // Tìm trong mockDestinations xem có thành phố nào trùng tên không
          final mockCity = mockDestinations.firstWhere(
                (d) => d.name.toLowerCase() == cityName.toLowerCase(),
            orElse: () => mockDestinations[0], // Fallback
          );
          imageUrl = mockCity.imagePath;
        } catch (e) {
          // Nếu không tìm thấy thì dùng ảnh default hoặc placeholder online
          imageUrl = "https://placehold.co/600x400/E37547/FFFFFF?text=$cityName";
        }

        tempCities.add({
          "name": cityName,
          "image": imageUrl,
          "count": count,
        });
      }

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
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFFB64B12)))
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
                    Row(
                      children: [
                        const Icon(Icons.place, size: 14, color: Color(0xFFE37547)),
                        const SizedBox(width: 4),
                        Text(
                          "${city['count']} địa điểm",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
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