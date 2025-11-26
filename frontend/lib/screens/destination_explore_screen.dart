import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../data/mock_explore_items.dart';
import '../models/destination_explore_item.dart';
import '../widgets/enter_bar.dart';
import '../services/recommendation_service.dart';
import '../services/user_service.dart';

class DestinationExploreScreen extends StatefulWidget {
  final String cityId;
  final String? restoreCityRawName; // Tên thành phố cũ để restore (nếu user back)

  final int? currentIndex;
  final void Function(int)? onTabChange;
  final VoidCallback? onBack;
  final VoidCallback? onBeforeGroup;
  final VoidCallback? onSearchPlace;

  const DestinationExploreScreen({
    Key? key,
    required this.cityId,
    this.restoreCityRawName,
    this.currentIndex,
    this.onTabChange,
    this.onBack,
    this.onBeforeGroup,
    this.onSearchPlace,
  }) : super(key: key);

  @override
  State<DestinationExploreScreen> createState() => _DestinationExploreScreenState();
}

class _DestinationExploreScreenState extends State<DestinationExploreScreen> {
  final RecommendationService _recommendService = RecommendationService();
  final UserService _userService = UserService();

  List<DestinationExploreItem> _displayItems = [];
  Map<String, int> _compatibilityScores = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Khởi tạo danh sách mặc định trước để tránh màn hình trắng
    _displayItems = mockExploreItems
        .where((item) => item.cityId == widget.cityId)
        .toList();
    _loadRecommendations();
  }

  // Logic restore thành phố cũ khi nhấn Back
  Future<void> _restoreCityIfNeeded() async {
    if (widget.restoreCityRawName != null) {
      print("🔙 [Explore] User back -> Đang khôi phục thành phố về: ${widget.restoreCityRawName}");
      await _userService.updatePreferredCityRaw(widget.restoreCityRawName!);
    }
  }

  Future<void> _loadRecommendations() async {
    try {
      print("🤖 [Explore] Đang gọi AI Recommendation cho city: ${widget.cityId}");

      // Gọi AI
      final recommendations = await _recommendService.getMyRecommendations();

      // Nếu thành công -> Map điểm số
      for (var rec in recommendations) {
        String apiName = rec.locationName.toLowerCase().trim();
        _compatibilityScores[apiName] = rec.score;
      }

      // Sắp xếp lại danh sách local theo điểm AI
      List<DestinationExploreItem> sortedItems = List.from(_displayItems);
      sortedItems.sort((a, b) {
        int scoreA = _getScore(a.name);
        int scoreB = _getScore(b.name);
        return scoreB.compareTo(scoreA); // Cao xếp trên
      });

      if (mounted) {
        setState(() {
          _displayItems = sortedItems;
          _isLoading = false;
        });
      }
      print("✅ [Explore] AI Load thành công: ${recommendations.length} items");

    } catch (e) {
      // QUAN TRỌNG: Nếu lỗi 404 (do thiếu Interests) hoặc lỗi mạng
      print('⚠️ [Explore] AI không khả dụng (Lỗi: $e). Sử dụng danh sách mặc định.');

      // Không throw lỗi, chỉ tắt loading để hiện danh sách mặc định
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  int _getScore(String locationName) {
    String key = locationName.toLowerCase().trim();
    return _compatibilityScores[key] ?? 0;
  }

  void _triggerSearchCallback() {
    if (widget.onSearchPlace != null) {
      widget.onSearchPlace!();
    }
  }

  // Xử lý nút Back
  void _handleBack() {
    // 1. Gọi restore city cũ
    _restoreCityIfNeeded();

    // 2. Thực hiện back
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      Navigator.of(context).pop();
    }
  }

  // Xử lý nút Tiếp tục (Enter) -> Qua màn hình Before Group
  void _handleEnter() {
    // User xác nhận đi tiếp -> KHÔNG restore, giữ nguyên city mới trong DB
    print("🚀 [Explore] User continue -> Giữ nguyên city mới.");
    if (widget.onBeforeGroup != null) {
      widget.onBeforeGroup!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Chặn nút back cứng để xử lý logic restore
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        extendBody: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: _handleBack,
            ),
          ),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: CircleAvatar(
                backgroundImage: AssetImage('assets/images/avatar.jpg'),
                radius: 18,
              ),
            ),
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/landmarks.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final screenHeight = constraints.maxHeight;
                final scaleFactor = (screenHeight / 800).clamp(0.7, 1.0);
                final topPadding = 100.0 * scaleFactor;
                final searchBarHeight = 74.0 * scaleFactor;
                final cardHeight = 380.0 * scaleFactor;
                final cardWidth = 282.01 * scaleFactor;
                final bottomPadding = MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + 90.0;

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
                          decoration: BoxDecoration(color: const Color(0xFFEDE2CC), border: Border.all(color: const Color(0xFFB64B12), width: 2), borderRadius: BorderRadius.circular(21)),
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.symmetric(horizontal: 24 * scaleFactor),
                          child: Text('search_place'.tr(), style: TextStyle(color: const Color(0xFF3E3322), fontSize: 16 * scaleFactor, fontFamily: 'Roboto', fontWeight: FontWeight.w500)),
                        ),
                      ),
                      SizedBox(height: 12 * scaleFactor),
                      Text('featured_places'.tr(), style: TextStyle(color: const Color(0xFFB99668), fontSize: 16 * scaleFactor, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                      SizedBox(height: 16 * scaleFactor),

                      // List View
                      SizedBox(
                        height: cardHeight,
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator(color: Color(0xFFB64B12)))
                            : _displayItems.isEmpty
                            ? const Center(child: Text("Không tìm thấy địa điểm nào", style: TextStyle(color: Colors.white)))
                            : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _displayItems.length,
                          separatorBuilder: (_, __) => SizedBox(width: 30 * scaleFactor),
                          itemBuilder: (context, index) {
                            final item = _displayItems[index];
                            final score = _getScore(item.name);
                            return _buildPlaceCard(
                              item.imageUrl,
                              item.name,
                              item.getSubtitle(context.locale.languageCode),
                              score,
                              cardWidth,
                              scaleFactor,
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 25 * scaleFactor),
                    ],
                  ),
                );
              },
            ),
            Positioned(
              left: 0, right: 0, bottom: kBottomNavigationBarHeight + 35,
              child: Center(
                child: EnterButton(
                  onConfirm: _handleEnter, // Nhấn nút này -> Update thành công
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildPlaceCard giữ nguyên như cũ
  Widget _buildPlaceCard(String imageUrl, String name, String subtitle, int score, double cardWidth, double scaleFactor) {
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
                decoration: BoxDecoration(color: const Color(0xFFD9D9D9), borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))]),
                child: Stack(
                  children: [
                    Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(30), child: Image.asset(imageUrl, fit: BoxFit.cover))),
                    if (score > 0)
                      Positioned(
                        left: 16 * scaleFactor, top: 16 * scaleFactor,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10 * scaleFactor, vertical: 6 * scaleFactor),
                          decoration: BoxDecoration(color: const Color(0xFFB64B12).withOpacity(0.9), borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))], border: Border.all(color: Colors.white, width: 1.5)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.auto_awesome, color: Colors.yellow, size: 14 * scaleFactor), SizedBox(width: 4 * scaleFactor), Text('$score% Hợp', style: TextStyle(color: Colors.white, fontSize: 14 * scaleFactor, fontWeight: FontWeight.bold, fontFamily: 'Roboto'))]),
                        ),
                      ),
                    Positioned(
                      right: 16 * scaleFactor, top: 16 * scaleFactor,
                      child: GestureDetector(
                        onTap: () => isFavorite.value = !fav,
                        child: Container(width: 32 * scaleFactor, height: 32 * scaleFactor, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16 * scaleFactor), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))]), child: Icon(Icons.favorite, color: fav ? Colors.red : Colors.black.withOpacity(0.2), size: 22 * scaleFactor)),
                      ),
                    ),
                    Positioned(
                      left: 20 * scaleFactor, bottom: 20 * scaleFactor, right: 20 * scaleFactor,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: TextStyle(color: Colors.white, fontSize: 18 * scaleFactor, fontFamily: 'Roboto', fontWeight: FontWeight.w700, shadows: const [Shadow(color: Colors.black, blurRadius: 4)]), maxLines: 2, overflow: TextOverflow.ellipsis), SizedBox(height: 4 * scaleFactor), Text(subtitle, style: TextStyle(color: const Color(0xFFDDDDDD), fontSize: 13 * scaleFactor, fontFamily: 'Roboto', fontWeight: FontWeight.w400, shadows: const [Shadow(color: Colors.black, blurRadius: 4)]))]),
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