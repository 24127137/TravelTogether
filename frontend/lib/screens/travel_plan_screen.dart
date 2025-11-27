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

  // Hàm trả về Future<void> chuẩn để dùng cho RefreshIndicator
  Future<void> _loadTravelPlanData() async {
    try {
      if (_places.isEmpty && mounted) setState(() { _isLoading = true; _error = null; });

      final token = await AuthService.getValidAccessToken();
      if (token == null) throw Exception("Vui lòng đăng nhập");

      final profile = await _userService.getUserProfile();
      if (profile == null) throw Exception("Không lấy được thông tin cá nhân");

      // 1. Khai báo dynamic để chứa mọi kiểu dữ liệu
      dynamic itineraryData;

      List owned = profile['owned_groups'] ?? [];
      List joined = profile['joined_groups'] ?? [];

      if (owned.isNotEmpty) {
        print("👤 User là HOST");
        _isMemberView = false;
        itineraryData = profile['itinerary'];
      }
      else if (joined.isNotEmpty) {
        print("👥 User là MEMBER");
        _isMemberView = true;

        final groupPlan = await _groupService.getMyGroupPlan(token);
        if (groupPlan != null) {
          itineraryData = groupPlan['itinerary'];
        }
      }
      else {
        print("👤 User SOLO");
        _isMemberView = false;
        itineraryData = profile['itinerary'];
      }

      // 2. Xử lý dữ liệu an toàn (Safe Parsing)
      List<String> rawNames = [];

      if (itineraryData != null) {
        if (itineraryData is Map) {
          // Case Map: {"1": "A", "2": "B"} hoặc {"places": [...]}
          if (itineraryData.containsKey('places') && itineraryData['places'] is List) {
            var listPlaces = itineraryData['places'] as List;
            rawNames = listPlaces.map((e) => e.toString()).toList();
          } else {
            var sortedKeys = itineraryData.keys.toList()
              ..sort((a, b) {
                int? iA = int.tryParse(a.toString());
                int? iB = int.tryParse(b.toString());
                if (iA != null && iB != null) return iA.compareTo(iB);
                return a.toString().compareTo(b.toString());
              });

            for (var key in sortedKeys) {
              if (itineraryData[key] != null) {
                rawNames.add(itineraryData[key].toString());
              }
            }
          }
        }
        else if (itineraryData is List) {
          // SỬA FIX LỖI: Ép kiểu tường minh (as List) để Compiler không hiểu nhầm
          rawNames = (itineraryData as List).map((e) => e.toString()).toList();
        }
      }

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
      print("❌ Lỗi load plan: $e");
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
      onRefresh: _loadTravelPlanData, // Truyền hàm Future vào
      isMemberView: _isMemberView,
    );
  }
}

class _TravelPlanContent extends StatelessWidget {
  final VoidCallback? onBack;
  final List<Map<String, String>> places;
  final bool isLoading;
  final String? error;

  // FIX LỖI VOID: Định nghĩa chính xác kiểu hàm trả về Future
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
                  // Gọi hàm refresh an toàn
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
        // Chỗ này giờ đã hợp lệ vì onRefresh là Future Function
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