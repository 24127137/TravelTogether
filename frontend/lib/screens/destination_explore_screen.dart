import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
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

  // THÊM: Key để quản lý trạng thái của nút EnterButton
  Key _enterButtonKey = UniqueKey();

  String _normalizeName(String name) {
    return name.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  @override
  void initState() {
    super.initState();
    _displayItems = mockExploreItems
        .where((item) => item.cityId == widget.cityId)
        .toList();
    _loadRecommendations();
  }

  // ... (Giữ nguyên các hàm _restoreCityIfNeeded, _loadRecommendations, _getScore, _toggleFavorite) ...
  Future<void> _restoreCityIfNeeded() async {
    if (widget.restoreCityRawName != null) {
      await _userService.updatePreferredCityRaw(widget.restoreCityRawName!);
    }
  }

  Future<void> _loadRecommendations() async {
    if (_hasLoadedOnce && _compatibilityScores.isNotEmpty) {
      return;
    }
    try {
      final recommendations = await _recommendService.getMyRecommendations();
      _compatibilityScores.clear();
      for (var rec in recommendations) {
        String safeName = _normalizeName(rec.locationName);
        _compatibilityScores[safeName] = rec.score;
      }
      List<DestinationExploreItem> sortedItems = List.from(_displayItems);
      sortedItems.sort((a, b) {
        int scoreA = _getScore(a.name);
        int scoreB = _getScore(b.name);
        return scoreB.compareTo(scoreA);
      });
      _hasLoadedOnce = true;
      if (mounted) setState(() { _displayItems = sortedItems; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _getScore(String locationName) {
    String key = _normalizeName(locationName);
    return _compatibilityScores[key] ?? 0;
  }

  void _toggleFavorite(DestinationExploreItem item) async {
    setState(() {
      item.isFavorite = !item.isFavorite;
    });
    await _userService.toggleItineraryItem(item.name, item.isFavorite);
  }

  // ... (Giữ nguyên _handleOpenSearch, _handleBack) ...
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
    if (mounted) {
      setState(() {
        _displayItems = mockExploreItems.where((item) => item.cityId == widget.cityId).toList();
        _displayItems.sort((a, b) {
          int scoreA = _getScore(a.name);
          int scoreB = _getScore(b.name);
          return scoreB.compareTo(scoreA);
        });
      });
    }
  }

  void _handleBack() {
    _restoreCityIfNeeded();
    if (widget.onBack != null) widget.onBack!();
    else Navigator.of(context).pop();
  }

  bool _validateSelection() {
    bool hasSelectedPlace = _displayItems.any((item) => item.isFavorite);

    if (!hasSelectedPlace) {
      // Hiện thông báo lỗi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Vui lòng chọn ít nhất một địa điểm!".tr()),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 2),
        ),
      );
      return false; // Báo cho nút biết là thất bại -> Nút sẽ tự thu về
    }

    return true; // Thành công -> Nút sẽ biến thành màu xanh
  }

  // --- SỬA LOGIC NÚT TIẾP TỤC TẠI ĐÂY ---
  void _handleEnter() async {
    // 1. VALIDATION: Kiểm tra xem user đã chọn địa điểm nào chưa (đã thả tim chưa)
    bool hasSelectedPlace = _displayItems.any((item) => item.isFavorite);

    // if (!hasSelectedPlace) {
    //   // Nếu chưa chọn -> Hiện thông báo và KHÔNG chuyển trang
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text("Vui lòng chọn ít nhất một địa điểm để tiếp tục!".tr()),
    //       backgroundColor: Colors.redAccent,
    //       behavior: SnackBarBehavior.floating,
    //       duration: const Duration(seconds: 2),
    //     ),
    //   );
    //   return; // Dừng lại tại đây
    // }

    // 2. Chuyển trang
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BeforeGroup(
          onBack: () {
            Navigator.pop(context);
          },
          onCreateGroup: (destinationName) {
            // Logic tạo nhóm
          },
          onJoinGroup: () {
            // Logic gia nhập
          },
        ),
      ),
    );

    // 3. RESET TRẠNG THÁI NÚT KHI QUAY LẠI
    // Khi lệnh await xong (tức là user quay lại Explore), ta thay đổi Key
    // Điều này ép Flutter hủy nút cũ và vẽ lại nút mới tinh -> Reset mọi hiệu ứng loading/success cũ
    if (mounted) {
      setState(() {
        _enterButtonKey = UniqueKey();
      });
    }

    print("🔙 Đã quay lại Explore Screen. Nút Enter đã được reset.");
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
        // ... (AppBar giữ nguyên) ...
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: _handleBack),
          ),
          actions: const [
            Padding(padding: EdgeInsets.only(right: 16), child: CircleAvatar(backgroundImage: AssetImage('assets/images/avatar.jpg'), radius: 18)),
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ... (Background & List giữ nguyên) ...
            Container(decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/images/landmarks.png'), fit: BoxFit.cover))),
            LayoutBuilder(
              builder: (context, constraints) {
                // ... (Layout giữ nguyên) ...
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

            // --- CẬP NHẬT NÚT ENTER ---
            Positioned(
              left: 0, right: 0, bottom: kBottomNavigationBarHeight + 35,
              child: Center(
                child: EnterButton(
                  // Thêm Key vào đây để Flutter biết khi nào cần vẽ lại mới
                  key: _enterButtonKey,
                  onValidation: _validateSelection,
                  onConfirm: _handleEnter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildPlaceCard giữ nguyên
  Widget _buildPlaceCard(DestinationExploreItem item, double cardWidth, double scaleFactor) {
    // ... code giữ nguyên ...
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