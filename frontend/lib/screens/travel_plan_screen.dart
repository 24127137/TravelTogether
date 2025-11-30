import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/group_service.dart';
import '../services/auth_service.dart';
import '../data/mock_explore_items.dart';

class TravelPlanScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const TravelPlanScreen({super.key, this.onBack});

  @override
  State<TravelPlanScreen> createState() => _TravelPlanScreenState();
}

class _TravelPlanScreenState extends State<TravelPlanScreen> {
  final UserService _userService = UserService();
  final GroupService _groupService = GroupService();

  List<Map<String, String>> _places = [];
  bool _isLoading = true;
  String? _error;
  bool _isMemberView = false;

  @override
  void initState() {
    super.initState();
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
                rawNames.add(itineraryData[key].toString());
              }
            }
          }
        }
        else if (itineraryData is List) {
          // Fallback cho trường hợp dữ liệu cũ dạng List
          rawNames = (itineraryData as List).map((e) => e.toString()).toList();
        }
      }


      // Map tên sang ảnh (giữ nguyên logic cũ)
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
      print("❌ Lỗi load plan tổng: $e");
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
        ),
      ],
    );
  }

  Widget _buildErrorImage() {
    return Container(
      color: Colors.grey,
      child: const Icon(Icons.broken_image, color: Colors.white, size: 40),
    );
  }
}