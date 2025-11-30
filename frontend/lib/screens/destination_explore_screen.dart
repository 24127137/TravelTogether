import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../data/mock_explore_items.dart';
import '../models/destination_explore_item.dart';
import '../widgets/enter_bar.dart';
<<<<<<< HEAD
import '../services/recommendation_service.dart';
import '../services/user_service.dart';
import 'destination_search_screen.dart';
import 'before_group_screen.dart';
=======
import '../config/api_config.dart';
import '../services/auth_service.dart';
>>>>>>> 3ee7efe (done all groupapis)

class DestinationExploreScreen extends StatefulWidget {
  final String cityId;
  final String? restoreCityRawName;

  final int? currentIndex;
  final void Function(int)? onTabChange;
  final VoidCallback? onBack;
  final VoidCallback? onBeforeGroup;
  final VoidCallback? onSearchPlace;

<<<<<<< HEAD
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

=======
>>>>>>> 3ee7efe (done all groupapis)
  @override
  State<DestinationExploreScreen> createState() => _DestinationExploreScreenState();
}

class _DestinationExploreScreenState extends State<DestinationExploreScreen> {
<<<<<<< HEAD
  final RecommendationService _recommendService = RecommendationService();
  final UserService _userService = UserService();

  List<DestinationExploreItem> _displayItems = [];
  Map<String, int> _compatibilityScores = {};
  bool _isLoading = true;
  bool _hasLoadedOnce = false;
  String? _userAvatar;

  Key _enterButtonKey = UniqueKey();

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
=======
  final Set<String> _selectedPlaceNames = {};

  void _triggerSearchCallback() {
    if (widget.onSearchPlace != null) widget.onSearchPlace!();
  }

  Future<void> _handleConfirm() async {
    // Build itinerary map like {"1": "Place A", "2": "Place B"}
    if (_selectedPlaceNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('no_places_selected'.tr())));
      return;
    }

    final itineraryMap = <String, String>{};
    int i = 1;
    for (final name in _selectedPlaceNames) {
      itineraryMap['$i'] = name;
      i++;
    }

    final ok = await _updateItineraryAPI(itineraryMap);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('itinerary_saved'.tr())));
      if (widget.onBeforeGroup != null) widget.onBeforeGroup!();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('save_itinerary_failed'.tr())));
>>>>>>> 3ee7efe (done all groupapis)
    }

    // 2. Khởi tạo list hiển thị
    _displayItems = mockExploreItems
        .where((item) => item.cityId == widget.cityId)
        .toList();

    // 3. Gọi load dữ liệu
    _loadAllData();
    _loadUserAvatar();
  }

  Future<void> _loadAllData() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      print("🚀 [Explore] Bắt đầu load dữ liệu...");

      final results = await Future.wait([
        _recommendService.getMyRecommendations(), // Index 0
        _userService.getSavedItineraryNames(),    // Index 1
      ]);

      final recommendations = results[0] as List<RecommendationOutput>;
      final savedNames = results[1] as List<String>;

      print("📥 Server trả về ${savedNames.length} địa điểm đã lưu: $savedNames");

      // 1. Xử lý điểm số AI
      _compatibilityScores.clear();
      for (var rec in recommendations) {
        _compatibilityScores[_normalizeName(rec.locationName)] = rec.score;
      }

      // 2. Xử lý đồng bộ Tim (Sync Favorites)
      int matchCount = 0;
      for (var item in _displayItems) {
        String itemNormal = _normalizeName(item.name);

        // So sánh tên item với danh sách đã lưu
        bool isSaved = savedNames.any((savedName) {
          String savedNormal = _normalizeName(savedName);
          // Log kiểm tra nếu thấy nghi ngờ
          // if (itemNormal.contains("rồng")) print("So sánh: '$itemNormal' vs '$savedNormal'");
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

      // 3. Sắp xếp lại
      List<DestinationExploreItem> sortedItems = List.from(_displayItems);
      sortedItems.sort((a, b) {
        int scoreA = _getScore(a.name);
        int scoreB = _getScore(b.name);
        return scoreB.compareTo(scoreA);
      });

      _hasLoadedOnce = true;

      if (mounted) {
        setState(() {
          _displayItems = sortedItems;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("⚠️ Lỗi load data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserAvatar() async {
    // 1. Thử lấy từ Cache trước cho nhanh
    // (Giả sử HomePage đã lưu vào SharedPreferences key 'user_avatar')
    // Nếu bạn muốn dùng chung cache thì import SharedPreferences
    // final prefs = await SharedPreferences.getInstance();
    // setState(() { _userAvatar = prefs.getString('user_avatar'); });

    // 2. Gọi API lấy mới nhất (để chắc chắn)
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

  // ... (Giữ nguyên các hàm phụ trợ khác: _restoreCityIfNeeded, _getScore...)
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
    // Khi quay lại từ Search, reload lại data để cập nhật tim nếu có thay đổi bên search
    _loadAllData();
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

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
=======
    // Lọc các địa điểm theo cityId
    final cityItems = mockExploreItems.where((item) => item.cityId == widget.cityId).toList();

    return PopScope(
      canPop: widget.onBack == null, // Cho phép pop nếu không có callback
      onPopInvokedWithResult: (didPop, result) {
        // Khi người dùng vuốt để quay lại, gọi callback onBack giống như nút back
        if (!didPop && widget.onBack != null) {
          widget.onBack!();
        }
>>>>>>> 3ee7efe (done all groupapis)
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        extendBody: true,
        appBar: AppBar(
<<<<<<< HEAD
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: _handleBack),
=======
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
              // Quay về destination detail screen
              if (widget.onBack != null) {
                widget.onBack!();
              }
            },
>>>>>>> 3ee7efe (done all groupapis)
          ),
          actions: [ // Bỏ const để dùng biến động
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[300], // Màu nền khi chưa có ảnh
                // LOGIC HIỂN THỊ ẢNH ĐỘNG:
                backgroundImage: (_userAvatar != null && _userAvatar!.isNotEmpty)
                    ? NetworkImage(_userAvatar!) as ImageProvider
                    : const AssetImage('assets/images/avatar.jpg'), // Ảnh mặc định local
              ),
            ),
          ],
        ),
        body: Stack(
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
<<<<<<< HEAD
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
=======
                    ),
                    SizedBox(height: spacing2),
                    SizedBox(
                      height: cardHeight,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: cityItems.length,
                        separatorBuilder: (_, __) => SizedBox(width: 30 * scaleFactor),
                        itemBuilder: (context, index) {
                          final item = cityItems[index];
                          return _buildPlaceCard(
                            item.imageUrl,
                            item.name,
                            '', // Không dùng namePart2
                            item.getSubtitle(context.locale.languageCode), // Dịch subtitle
                            cardWidth,
                            scaleFactor,
                            item.name,
                          );
                        },
                      ),
                    ),
                    SizedBox(height: spacing3),
                  ],
                ),
              );
            },
          ),
          // EnterButton cố định ở vị trí giống destination_detail_screen
          Positioned(
            left: 0,
            right: 0,
            bottom: kBottomNavigationBarHeight + 35,
            child: Center(
              child: EnterButton(
                onConfirm: _handleConfirm,
>>>>>>> 3ee7efe (done all groupapis)
              ),
            ),
          ],
        ),
      ),
    );
  }

<<<<<<< HEAD
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
                      // QUAN TRỌNG: UI phản ánh đúng trạng thái isFavorite
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
=======
  Widget _buildPlaceCard(
      String imageUrl,
      String namePart1,
      String namePart2,
      String subtitle,
      double cardWidth,
      double scaleFactor,
      String placeName,
      ) {
    return StatefulBuilder(
      builder: (context, setState) {
        final isSelected = _selectedPlaceNames.contains(placeName);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (_selectedPlaceNames.contains(placeName)) {
                _selectedPlaceNames.remove(placeName);
              } else {
                _selectedPlaceNames.add(placeName);
              }
            });
          },
          child: Container(
            width: cardWidth,
            height: 180 * scaleFactor,
            margin: EdgeInsets.only(right: 8 * scaleFactor),
            decoration: BoxDecoration(
              color: const Color(0xFFD9D9D9),
              borderRadius: BorderRadius.circular(30),
              border: isSelected ? Border.all(color: const Color(0xFFB99668), width: 3) : null,
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(imageUrl, fit: BoxFit.cover),
                  ),
                ),
                // Heart selection button in corner
                Positioned(
                  right: 16 * scaleFactor,
                  top: 16 * scaleFactor,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_selectedPlaceNames.contains(placeName)) {
                          _selectedPlaceNames.remove(placeName);
                        } else {
                          _selectedPlaceNames.add(placeName);
                        }
                      });
                    },
                    child: Container(
                      width: 32 * scaleFactor,
                      height: 32 * scaleFactor,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16 * scaleFactor),
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
                        color: isSelected ? Colors.red : Colors.black.withValues(alpha: 0.2),
                        size: 22 * scaleFactor,
                      ),
                    ),
                  ),
                ),
                // Nội dung tên, subtitle
                Positioned(
                  left: 20 * scaleFactor,
                  bottom: 20 * scaleFactor,
                  right: 20 * scaleFactor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        namePart1,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16 * scaleFactor,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w600,
                          shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
                        ),
                      ),
                      SizedBox(height: 4 * scaleFactor),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: const Color(0xFFC9C8C8),
                          fontSize: 13 * scaleFactor,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w400,
                          shadows: const [Shadow(color: Colors.black12, blurRadius: 1)],
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
>>>>>>> 3ee7efe (done all groupapis)
    );
  }

  // Update itinerary on user profile
  Future<bool> _updateItineraryAPI(Map<String, String> itinerary) async {
    try {
      final token = await AuthService.getValidAccessToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('session_expired'.tr())));
        return false;
      }

      final url = ApiConfig.getUri(ApiConfig.userProfile);
      // fetch current user data to preserve fields
      final resp = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (resp.statusCode != 200) {
        debugPrint('Failed to fetch user data: ${resp.statusCode} ${resp.body}');
        return false;
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;

      final body = {
        'fullname': data['fullname'] ?? '',
        'email': data['email'] ?? '',
        'gender': data['gender'] ?? '',
        'birth_date': data['birth_date'] ?? '',
        'description': data['description'] ?? '',
        'interests': data['interests'] ?? [],
        'itinerary': itinerary,
      };

      final patchResp = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      debugPrint('Update itinerary status: ${patchResp.statusCode} body: ${patchResp.body}');
      return patchResp.statusCode == 200 || patchResp.statusCode == 201;
    } catch (e) {
      debugPrint('Error updating itinerary: $e');
      return false;
    }
  }
}