<<<<<<< HEAD
import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/group_service.dart';
import '../services/auth_service.dart';
import '../data/mock_explore_items.dart';
=======
// file: lib/screens/travel_plan_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:convert';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../data/mock_destinations.dart';
import 'map_route_screen.dart';
>>>>>>> week10

class TravelPlanScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const TravelPlanScreen({super.key, this.onBack});

  @override
  State<TravelPlanScreen> createState() => _TravelPlanScreenState();
}

class _TravelPlanScreenState extends State<TravelPlanScreen> {
  final UserService _userService = UserService();
<<<<<<< HEAD
  final GroupService _groupService = GroupService();

  List<Map<String, String>> _places = [];
  bool _isLoading = true;
  String? _error;
  bool _isMemberView = false;
=======

  List<Map<String, dynamic>> _savedCities = [];
  bool _isLoading = true;
>>>>>>> week10

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
    _loadTravelPlanData();
  }

  String _findImageUrl(String locationName) {
    String cleanName = locationName.trim().toLowerCase();
    try {
      final item = mockExploreItems.firstWhere(
            (element) {
          String mockName = element.name.trim().toLowerCase();
          return mockName.contains(cleanName) || cleanName.contains(mockName);
        },
      );
      return item.imageUrl;
    } catch (e) {
      return "https://placehold.co/300x200/B64B12/FFFFFF?text=${Uri.encodeComponent(locationName)}";
    }
  }

  Future<void> _loadTravelPlanData() async {
    try {
      if (_places.isEmpty && mounted) setState(() { _isLoading = true; _error = null; });

      final token = await AuthService.getValidAccessToken();
      if (token == null) throw Exception("Vui lòng đăng nhập");

      final profile = await _userService.getUserProfile();
      if (profile == null) throw Exception("Không lấy được thông tin cá nhân");

<<<<<<< HEAD
      dynamic itineraryData; // Dữ liệu sẽ hiển thị
      _isMemberView = false; // Mặc định là xem cá nhân

      // === LOGIC MỚI: CHECK STATUS TRƯỚC ===
      bool useGroupPlan = false;

      // Kiểm tra xem user có dính dáng tới nhóm nào không (Host hoặc Member)
      List owned = profile['owned_groups'] ?? [];
      List joined = profile['joined_groups'] ?? [];

      if (owned.isNotEmpty || joined.isNotEmpty) {
        // Có nhóm -> Gọi API check trạng thái nhóm
        try {
          final groupDetail = await _groupService.getMyGroupDetail(token);

          if (groupDetail != null) {
            String status = groupDetail['status'] ?? 'closed';
            int groupId = groupDetail['id'];

            print("🔍 Trạng thái nhóm (ID $groupId): $status");

            if (status == 'open') {
              // TRƯỜNG HỢP 1: NHÓM ĐANG HOẠT ĐỘNG (OPEN)
              // Dù là Host hay Member -> Lấy Group Plan
              print("✅ Nhóm OPEN -> Load Group Plan");

              final groupPlan = await _groupService.getGroupPlanById(token, groupId);
              if (groupPlan != null) {
                itineraryData = groupPlan['itinerary'];
                useGroupPlan = true;
                _isMemberView = true; // Đánh dấu là đang xem view nhóm
              }
            } else {
              // TRƯỜNG HỢP 2: NHÓM EXPIRED HOẶC CLOSED
              print("⚠️ Nhóm $status -> Quay về Personal Plan");
              useGroupPlan = false;
            }
          }
        } catch (e) {
          print("❌ Lỗi check nhóm: $e -> Quay về Personal Plan");
        }
      }

      // TRƯỜNG HỢP 3: KHÔNG DÙNG GROUP PLAN (Solo / Expired / Closed)
      if (!useGroupPlan) {
        print("👤 Load Personal Itinerary (Theo Preferred City)");
        itineraryData = profile['itinerary'];
        _isMemberView = false;
      }

      // --- XỬ LÝ HIỂN THỊ (PARSE DATA) ---
      List<String> rawNames = [];

      // Lấy tên thành phố hiện tại để lọc (Chỉ dùng khi xem cá nhân)
      String currentCity = profile['preferred_city'] ?? "";
      String prefix = "${currentCity}_";

      if (itineraryData != null) {
        if (itineraryData is Map) {
          // Sort key để hiển thị đúng thứ tự
          var sortedKeys = itineraryData.keys.toList()..sort();

          for (var key in sortedKeys) {
            String strKey = key.toString();

            if (useGroupPlan) {
              // Nếu đang xem Group Plan: Lấy HẾT (vì plan nhóm là duy nhất)
              if (itineraryData[key] != null) rawNames.add(itineraryData[key].toString());
            } else {
              // Nếu đang xem Cá nhân: Chỉ lấy item thuộc CITY hiện tại
              // (Logic lọc theo prefix như đã thống nhất)
              if (strKey.startsWith(prefix)) {
=======
      dynamic itineraryData;

      List owned = profile['owned_groups'] ?? [];
      List joined = profile['joined_groups'] ?? [];

      if (owned.isNotEmpty) {
        print("👤 User là HOST");
        _isMemberView = false;
        itineraryData = profile['itinerary'];
      }
      else if (joined.isNotEmpty) {
        print("👥 User là MEMBER -> Dùng kế hoạch 'Lách luật'");
        _isMemberView = true;

        // --- SỬA ĐOẠN NÀY: LẤY ID NHÓM RỒI GỌI API PUBLIC ---
        try {
          // 1. Lấy Group ID từ thông tin profile
          var firstGroup = joined[0]; // {"group_id": 123, "name": "..."}
          int groupId = firstGroup['group_id'];

          // 2. Gọi API Public (Cái API không bị lỗi 500)
          final groupPlan = await _groupService.getGroupPlanById(token, groupId);

          if (groupPlan != null) {
            itineraryData = groupPlan['itinerary'];
          }
        } catch (e) {
          print("⚠️ Lỗi lấy plan: $e");
          // Fallback nếu không lấy được
          itineraryData = profile['itinerary'];
        }
        // -----------------------------------------------------
      }
      else {
        print("👤 User SOLO");
        _isMemberView = false;
        itineraryData = profile['itinerary'];
      }

      // 2. Xử lý dữ liệu hiển thị (Safe Parsing)
      List<String> rawNames = [];

      if (itineraryData != null) {
        if (itineraryData is Map) {
          if (itineraryData.containsKey('places') && itineraryData['places'] is List) {
            var listPlaces = itineraryData['places'] as List;
            rawNames = listPlaces.map((e) => e.toString()).toList();
          } else {
            // Sort theo key "1", "2"...
            var sortedKeys = itineraryData.keys.toList()
              ..sort((a, b) {
                int? iA = int.tryParse(a.toString());
                int? iB = int.tryParse(b.toString());
                if (iA != null && iB != null) return iA.compareTo(iB);
                return a.toString().compareTo(b.toString());
              });

            for (var key in sortedKeys) {
              if (itineraryData[key] != null) {
>>>>>>> 3ee7efe (done all groupapis)
                rawNames.add(itineraryData[key].toString());
              }
            }
          }
        }
        else if (itineraryData is List) {
<<<<<<< HEAD
          // Fallback cho trường hợp dữ liệu cũ dạng List
=======
>>>>>>> 3ee7efe (done all groupapis)
          rawNames = (itineraryData as List).map((e) => e.toString()).toList();
        }
      }

<<<<<<< HEAD

      // Map tên sang ảnh (giữ nguyên logic cũ)
=======
      // Map tên sang ảnh
>>>>>>> 3ee7efe (done all groupapis)
      List<Map<String, String>> newPlaces = rawNames.map((name) {
        String imagePath = _findImageUrl(name);
        return {
          "name": name,
          "image": imagePath,
          "isLocal": imagePath.startsWith('assets/') ? 'true' : 'false'
        };
      }).toList();

      if (mounted) {
        setState(() {
          _places = newPlaces;
          _isLoading = false;
        });
      }

    } catch (e) {
<<<<<<< HEAD
      print("❌ Lỗi load plan tổng: $e");
=======
      print("❌ Lỗi load plan: $e");
>>>>>>> 3ee7efe (done all groupapis)
      if (mounted) setState(() { _error = 'Lỗi: $e'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _TravelPlanContent(
      onBack: widget.onBack,
      places: _places,
      isLoading: _isLoading,
      error: _error,
      onRefresh: _loadTravelPlanData,
      isMemberView: _isMemberView,
    );
  }
}

// ... (Phần _TravelPlanContent và _PlaceCard giữ nguyên như cũ) ...
// Copy lại phần UI từ code trước của tôi để đảm bảo không thiếu sót
class _TravelPlanContent extends StatelessWidget {
  final VoidCallback? onBack;
  final List<Map<String, String>> places;
  final bool isLoading;
  final String? error;
  final Future<void> Function()? onRefresh;
  final bool isMemberView;

  const _TravelPlanContent({
    this.onBack,
    required this.places,
    required this.isLoading,
    this.error,
    this.onRefresh,
    this.isMemberView = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = constraints.maxHeight;
          final scaleFactor = (screenHeight / 800).clamp(0.7, 1.0);

          final horizontalPadding = 16.0 * scaleFactor;
          final topOffset = MediaQuery.of(context).padding.top + 32.0 * scaleFactor;
          final bottomOffset = 80.0 * scaleFactor;
          final spacing = 12.0 * scaleFactor;
          final backButtonSize = 44.0 * scaleFactor;
          final iconSize = 24.0 * scaleFactor;

          return SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/travel_plan.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: const Color(0xFF12202F)),
                  ),
                ),

                Positioned(
                  top: topOffset,
                  left: horizontalPadding,
                  right: horizontalPadding,
                  bottom: bottomOffset,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.40),
                      border: Border.all(color: Colors.black, width: 2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(spacing),
                      child: _buildContent(scaleFactor, spacing),
                    ),
                  ),
                ),

                Positioned(
                  top: 16 * scaleFactor,
                  left: 16 * scaleFactor,
                  child: GestureDetector(
                    onTap: () {
                      if (onBack != null) {
                        onBack!();
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Container(
                      width: backButtonSize,
                      height: backButtonSize,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.black,
                        size: iconSize,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(double scaleFactor, double spacing) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 64 * scaleFactor),
            SizedBox(height: 16 * scaleFactor),
            Text(error!, style: TextStyle(color: Colors.white, fontSize: 16 * scaleFactor), textAlign: TextAlign.center),
            SizedBox(height: 16 * scaleFactor),
            ElevatedButton(
                onPressed: () {
                  if (onRefresh != null) onRefresh!();
                },
                child: Text('Thử lại', style: TextStyle(fontSize: 14 * scaleFactor))
            ),
          ],
        ),
      );
    }

    if (places.isEmpty) {
      return Center(
        child: RefreshIndicator(
          onRefresh: () async {
            if (onRefresh != null) await onRefresh!();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: 100 * scaleFactor),
              Icon(Icons.explore_off, color: Colors.white, size: 64 * scaleFactor),
              SizedBox(height: 16 * scaleFactor),
              Center(child: Text('Chưa có kế hoạch du lịch nào', style: TextStyle(color: Colors.white, fontSize: 18 * scaleFactor, fontWeight: FontWeight.w600))),
              SizedBox(height: 8 * scaleFactor),
              Center(child: Text('Hãy tạo hoặc tham gia một nhóm để bắt đầu', style: TextStyle(color: Colors.white70, fontSize: 14 * scaleFactor), textAlign: TextAlign.center)),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (onRefresh != null) await onRefresh!();
      },
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: 0.72,
        ),
        itemCount: places.length,
        itemBuilder: (context, index) {
          final place = places[index];
          return _PlaceCard(place: place, scaleFactor: scaleFactor);
        },
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final Map<String, String> place;
  final double scaleFactor;

  const _PlaceCard({required this.place, this.scaleFactor = 1.0});

  @override
  Widget build(BuildContext context) {
    bool isLocal = place['isLocal'] == 'true';
    String imagePath = place['image']!;

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isLocal
                ? Image.asset(
              imagePath,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) => _buildErrorImage(),
            )
                : Image.network(
              imagePath,
              fit: BoxFit.cover,
              width: double.infinity,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(color: Colors.grey[300], child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
              },
              errorBuilder: (_, __, ___) => _buildErrorImage(),
            ),
          ),
        ),
        SizedBox(height: 6 * scaleFactor),
        Text(
          place['name']!,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 14 * scaleFactor, fontWeight: FontWeight.w700),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
=======
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
>>>>>>> week10
        ),
      ],
    );
  }

<<<<<<< HEAD
  Widget _buildErrorImage() {
    return Container(
      color: Colors.grey,
      child: const Icon(Icons.broken_image, color: Colors.white, size: 40),
    );
  }
}
=======
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
          color: const Color(0xFFEFE7DA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFB29079),
            width: 1.5,
          ),
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


>>>>>>> week10
