import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../data/mock_explore_items.dart';
import '../models/destination_explore_item.dart';
import '../widgets/enter_bar.dart';
import '../services/recommendation_service.dart';
import '../services/user_service.dart';
import 'destination_search_screen.dart';
import 'before_group_screen.dart';

class DestinationExploreScreen extends StatefulWidget {
  final String cityId;
  final String? restoreCityRawName;

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
  bool _hasLoadedOnce = false;
  String? _userAvatar;

  Key _enterButtonKey = UniqueKey();

  // Cache keys
  static const String _cacheKeyPrefix = 'ai_recommendations_';
  static const String _cacheTimestampPrefix = 'ai_recommendations_timestamp_';
  static const Duration _cacheExpiration = Duration(hours: 24); // Cache 24 giờ

  // Hàm chuẩn hóa tên mạnh mẽ hơn (Trim, Lowercase, Xóa khoảng trắng thừa)
  String _normalizeName(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  @override
  void initState() {
    super.initState();
    // 1. Reset trạng thái tim của mock data về false trước khi load để tránh lưu cache sai
    for (var item in mockExploreItems) {
      if (item.cityId == widget.cityId) item.isFavorite = false;
    }

    // 2. Khởi tạo list hiển thị
    _displayItems = mockExploreItems
        .where((item) => item.cityId == widget.cityId)
        .toList();

    // 3. Gọi load dữ liệu
    _loadAllData();
    _loadUserAvatar();
  }

  /// Lấy cache key theo cityId
  String _getCacheKey() => '$_cacheKeyPrefix${widget.cityId}';
  String _getCacheTimestampKey() => '$_cacheTimestampPrefix${widget.cityId}';

  /// Kiểm tra xem cache còn hợp lệ không
  Future<bool> _isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampStr = prefs.getString(_getCacheTimestampKey());
      
      if (timestampStr == null) return false;
      
      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();
      final difference = now.difference(timestamp);
      
      return difference < _cacheExpiration;
    } catch (e) {
      print("⚠️ Lỗi kiểm tra cache: $e");
      return false;
    }
  }

  /// Lưu AI recommendations vào cache
  Future<void> _saveRecommendationsToCache(List<RecommendationOutput> recommendations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert recommendations to JSON
      final Map<String, int> scoresMap = {};
      for (var rec in recommendations) {
        scoresMap[_normalizeName(rec.locationName)] = rec.score;
      }
      
      await prefs.setString(_getCacheKey(), json.encode(scoresMap));
      await prefs.setString(_getCacheTimestampKey(), DateTime.now().toIso8601String());
      
      print("💾 Đã lưu ${scoresMap.length} recommendations vào cache cho city ${widget.cityId}");
    } catch (e) {
      print("⚠️ Lỗi lưu cache: $e");
    }
  }

  /// Load AI recommendations từ cache
  Future<Map<String, int>?> _loadRecommendationsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_getCacheKey());
      
      if (cachedData == null) return null;
      
      final Map<String, dynamic> decoded = json.decode(cachedData);
      final Map<String, int> scores = decoded.map((key, value) => MapEntry(key, value as int));
      
      print("📦 Đã load ${scores.length} recommendations từ cache");
      return scores;
    } catch (e) {
      print("⚠️ Lỗi load cache: $e");
      return null;
    }
  }

  /// Xóa cache (dùng khi cần force refresh)
  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getCacheKey());
      await prefs.remove(_getCacheTimestampKey());
      print("🗑️ Đã xóa cache cho city ${widget.cityId}");
    } catch (e) {
      print("⚠️ Lỗi xóa cache: $e");
    }
  }

  Future<void> _loadAllData({bool forceRefresh = false}) async {
    if (mounted) setState(() => _isLoading = true);

    try {
      print("🚀 [Explore] Bắt đầu load dữ liệu...");

      // 1. Kiểm tra cache trước
      bool shouldUseCache = !forceRefresh && await _isCacheValid();
      List<RecommendationOutput> recommendations = [];
      
      if (shouldUseCache) {
        final cachedScores = await _loadRecommendationsFromCache();
        if (cachedScores != null) {
          print("✅ Sử dụng cache - Không gọi AI API");
          _compatibilityScores = cachedScores;
          
          // Chỉ cần load saved itineraries
          final savedNames = await _userService.getSavedItineraryNames();
          print("📥 Server trả về ${savedNames.length} địa điểm đã lưu");
          
          _syncFavorites(savedNames);
          _sortItems();
          
          _hasLoadedOnce = true;
          
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          return;
        }
      }

      // 2. Nếu không có cache hoặc cache hết hạn, gọi API
      print("🌐 Gọi AI API để lấy recommendations mới");
      final results = await Future.wait([
        _recommendService.getMyRecommendations(), // Index 0
        _userService.getSavedItineraryNames(),    // Index 1
      ]);

      recommendations = results[0] as List<RecommendationOutput>;
      final savedNames = results[1] as List<String>;

      print("📥 AI trả về ${recommendations.length} recommendations");
      print("📥 Server trả về ${savedNames.length} địa điểm đã lưu");

      // 3. Lưu vào cache
      await _saveRecommendationsToCache(recommendations);

      // 4. Xử lý điểm số AI
      _compatibilityScores.clear();
      for (var rec in recommendations) {
        _compatibilityScores[_normalizeName(rec.locationName)] = rec.score;
      }

      // 5. Sync favorites
      _syncFavorites(savedNames);

      // 6. Sắp xếp
      _sortItems();

      _hasLoadedOnce = true;

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("⚠️ Lỗi load data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Đồng bộ trạng thái yêu thích
  void _syncFavorites(List<String> savedNames) {
    int matchCount = 0;
    for (var item in _displayItems) {
      String itemNormal = _normalizeName(item.name);

      bool isSaved = savedNames.any((savedName) {
        String savedNormal = _normalizeName(savedName);
        return savedNormal == itemNormal;
      });

      if (isSaved) {
        item.isFavorite = true;
        matchCount++;
      } else {
        item.isFavorite = false;
      }
    }

    print("✅ Đã đồng bộ xong. Có $matchCount thẻ được tim đỏ.");
  }

  /// Sắp xếp items theo điểm số
  void _sortItems() {
    List<DestinationExploreItem> sortedItems = List.from(_displayItems);
    sortedItems.sort((a, b) {
      int scoreA = _getScore(a.name);
      int scoreB = _getScore(b.name);
      return scoreB.compareTo(scoreA);
    });

    if (mounted) {
      setState(() {
        _displayItems = sortedItems;
      });
    }
  }

  Future<void> _loadUserAvatar() async {
    try {
      final profile = await _userService.getUserProfile();
      if (profile != null && mounted) {
        setState(() {
          _userAvatar = profile['avatar_url'];
        });
      }
    } catch (e) {
      print("Lỗi load avatar: $e");
    }
  }

  Future<void> _restoreCityIfNeeded() async {
    if (widget.restoreCityRawName != null) {
      await _userService.updatePreferredCityRaw(widget.restoreCityRawName!);
    }
  }

  int _getScore(String locationName) {
    String key = _normalizeName(locationName);
    return _compatibilityScores[key] ?? 0;
  }

  void _toggleFavorite(DestinationExploreItem item) async {
    // Optimistic UI Update: Đổi màu ngay lập tức
    setState(() {
      item.isFavorite = !item.isFavorite;
    });
    print("bấm tim: ${item.name} -> ${item.isFavorite}");

    // Gọi API lưu
    bool success = await _userService.toggleItineraryItem(item.name, item.isFavorite);
    if (!success) {
      print("❌ Lỗi lưu Server! Revert UI.");
      // Nếu lỗi thì đổi lại
      setState(() {
        item.isFavorite = !item.isFavorite;
      });
    }
  }

  void _handleOpenSearch() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DestinationSearchScreen(
          cityId: widget.cityId,
          preloadedScores: _compatibilityScores,
        ),
      ),
    );
    // Khi quay lại từ Search, chỉ reload saved items, không gọi lại AI
    _loadAllData(forceRefresh: false);
  }

  void _handleBack() {
    _restoreCityIfNeeded();
    if (widget.onBack != null) widget.onBack!();
    else Navigator.of(context).pop();
  }

  bool _validateSelection() {
    bool hasSelectedPlace = _displayItems.any((item) => item.isFavorite);
    if (!hasSelectedPlace) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Vui lòng chọn ít nhất một địa điểm!".tr()),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 2),
        ),
      );
      return false;
    }
    return true;
  }

  void _handleEnter() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BeforeGroup(
          onBack: () => Navigator.pop(context),
          onCreateGroup: (name) {},
          onJoinGroup: () {},
        ),
      ),
    );
    if (mounted) setState(() { _enterButtonKey = UniqueKey(); });
  }

  /// Hàm để force refresh (có thể gọi từ pull-to-refresh)
  Future<void> _handleRefresh() async {
    await _clearCache();
    await _loadAllData(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
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
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: _handleBack),
          ),
          actions: [
            // Nút refresh (optional - có thể bỏ nếu không cần)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _handleRefresh,
              tooltip: 'Làm mới AI recommendations',
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[300],
                backgroundImage: (_userAvatar != null && _userAvatar!.isNotEmpty)
                    ? NetworkImage(_userAvatar!) as ImageProvider
                    : const AssetImage('assets/images/avatar.jpg'),
              ),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: const Color(0xFFB64B12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/images/landmarks.png'), fit: BoxFit.cover))),
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
                    physics: const AlwaysScrollableScrollPhysics(), // Cho phép pull-to-refresh
                    padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
                    child: Column(
                      children: [
                        SizedBox(height: topPadding),
                        GestureDetector(
                          onTap: _handleOpenSearch,
                          child: Container(
                            width: double.infinity, height: searchBarHeight,
                            decoration: BoxDecoration(color: const Color(0xFFEDE2CC), border: Border.all(color: const Color(0xFFB64B12), width: 2), borderRadius: BorderRadius.circular(21)),
                            alignment: Alignment.centerLeft,
                            padding: EdgeInsets.symmetric(horizontal: 24 * scaleFactor),
                            child: Text('search_place'.tr(), style: TextStyle(color: const Color(0xFF3E3322), fontSize: 16 * scaleFactor, fontFamily: 'Roboto', fontWeight: FontWeight.w500)),
                          ),
                        ),
                        SizedBox(height: 12 * scaleFactor),
                        Text('featured_places'.tr(), style: TextStyle(color: const Color(0xFFB99668), fontSize: 16 * scaleFactor, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                        SizedBox(height: 16 * scaleFactor),

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
                              return _buildPlaceCard(item, cardWidth, scaleFactor);
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
                    key: _enterButtonKey,
                    onValidation: _validateSelection,
                    onConfirm: _handleEnter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceCard(DestinationExploreItem item, double cardWidth, double scaleFactor) {
    final score = _getScore(item.name);
    return GestureDetector(
      onTap: () => _toggleFavorite(item),
      child: Container(
        width: cardWidth,
        height: 180 * scaleFactor,
        decoration: BoxDecoration(color: const Color(0xFFD9D9D9), borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))]),
        child: Stack(
          children: [
            Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(30), child: Image.asset(item.imageUrl, fit: BoxFit.cover))),
            if (score > 0)
              Positioned(
                left: 16 * scaleFactor, top: 16 * scaleFactor,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10 * scaleFactor, vertical: 6 * scaleFactor),
                  decoration: BoxDecoration(color: const Color(0xFFB64B12).withOpacity(0.9), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white, width: 1.5)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.auto_awesome, color: Colors.yellow, size: 14 * scaleFactor), SizedBox(width: 4 * scaleFactor), Text('$score% Hợp', style: TextStyle(color: Colors.white, fontSize: 14 * scaleFactor, fontWeight: FontWeight.bold, fontFamily: 'Roboto'))]),
                ),
              ),
            Positioned(
              right: 16 * scaleFactor, top: 16 * scaleFactor,
              child: GestureDetector(
                onTap: () => _toggleFavorite(item),
                child: Container(
                    width: 32 * scaleFactor, height: 32 * scaleFactor,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16 * scaleFactor)),
                    child: Icon(
                        item.isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: item.isFavorite ? Colors.red : Colors.black.withOpacity(0.2),
                        size: 22 * scaleFactor
                    )
                ),
              ),
            ),
            Positioned(
              left: 20 * scaleFactor, bottom: 20 * scaleFactor, right: 20 * scaleFactor,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.name, style: TextStyle(color: Colors.white, fontSize: 18 * scaleFactor, fontWeight: FontWeight.w700, shadows: const [Shadow(color: Colors.black, blurRadius: 4)]), maxLines: 2, overflow: TextOverflow.ellipsis),
                SizedBox(height: 4 * scaleFactor),
                Text(item.getSubtitle(context.locale.languageCode), style: TextStyle(color: const Color(0xFFDDDDDD), fontSize: 13 * scaleFactor, shadows: const [Shadow(color: Colors.black, blurRadius: 4)]))
              ]),
            ),
          ],
        ),
      ),
    );
  }
}