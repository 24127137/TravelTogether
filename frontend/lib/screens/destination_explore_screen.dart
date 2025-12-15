import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
<<<<<<< HEAD
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
=======
import '../data/mock_explore_items.dart';
import '../models/destination_explore_item.dart';
import '../widgets/enter_bar.dart';
import '../services/recommendation_service.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';
import 'destination_search_screen.dart';
import 'before_group_screen.dart';
import 'dart:ui'; // Để dùng ImageFilter.blur
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ExploreCacheManager {
  static final ExploreCacheManager _instance = ExploreCacheManager._internal();
  factory ExploreCacheManager() => _instance;
  ExploreCacheManager._internal();

  // Cache cho từng cityId
  final Map<String, CachedExploreData> _cacheByCity = {};
  static const Duration _cacheDuration = Duration(hours: 24); // Tăng lên 24h
  static const String _interestsKey = 'cached_user_interests';
  static const String _cacheTimestampKey = 'cache_timestamp';

  /// Kiểm tra cache có tồn tại cho cityId không
  bool hasCache(String cityId) {
    return _cacheByCity.containsKey(cityId);
  }

  /// Lấy cache data (nullable)
  CachedExploreData? getCache(String cityId) {
    return _cacheByCity[cityId];
  }

  /// Cập nhật chỉ savedNames trong cache (giữ nguyên scores và interests)
  Future<void> updateSavedNames(String cityId, List<String> savedNames) async {
    final oldCache = _cacheByCity[cityId];
    if (oldCache != null) {
      await setCache(
        cityId,
        oldCache.scores,
        savedNames,
        oldCache.interests,
      );
    }
  }

  /// Lấy cache mà KHÔNG gọi API - chỉ check local
  CachedExploreData? getCacheSync(String cityId) {
    final cached = _cacheByCity[cityId];
    if (cached == null) return null;

    if (DateTime.now().difference(cached.timestamp) > _cacheDuration) {
      _cacheByCity.remove(cityId);
      return null;
    }
    return cached;
  }

  /// Kiểm tra interests có thay đổi so với cache (so sánh với param truyền vào)
  bool hasInterestsChanged(List<String> currentInterests, List<String> cachedInterests) {
    if (currentInterests.length != cachedInterests.length) return true;
    final setA = Set.from(currentInterests);
    final setB = Set.from(cachedInterests);
    return setA.difference(setB).isNotEmpty || setB.difference(setA).isNotEmpty;
  }

  /// Lưu interests vào SharedPreferences (gọi khi user thay đổi interests)
  Future<void> saveInterestsToLocal(List<String> interests) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_interestsKey, jsonEncode(interests));
  }

  /// Lấy interests từ SharedPreferences
  Future<List<String>> getLocalInterests() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_interestsKey);
    if (json == null) return [];
    try {
      return List<String>.from(jsonDecode(json));
    } catch (e) {
      return [];
    }
  }

  Future<void> setCache(
    String cityId,
    Map<String, int> scores,
    List<String> savedNames,
    List<String> interests,
  ) async {
    _cacheByCity[cityId] = CachedExploreData(
      scores: scores,
      savedNames: savedNames,
      interests: interests,
      timestamp: DateTime.now(),
    );
    // Lưu interests vào local để lần sau so sánh
    await saveInterestsToLocal(interests);
    print("💾 [Cache] Đã lưu cache cho cityId: $cityId");
  }

  void invalidateCity(String cityId) {
    _cacheByCity.remove(cityId);
    print("🗑️ [Cache] Đã xóa cache cho cityId: $cityId");
  }

  void clearAll() {
    _cacheByCity.clear();
    print("🗑️ [Cache] Đã xóa toàn bộ cache");
  }

  /// Kiểm tra interests từ API với interests đã lưu trong SharedPreferences
  /// Trả về true nếu có thay đổi (cần reset cache)
  Future<bool> _checkAndUpdateInterests() async {
    try {
      // 1. Lấy interests từ API trực tiếp
      String? accessToken = await AuthService.getValidAccessToken();
      
      if (accessToken == null) {
        print("⚠️ Không có access token, skip kiểm tra interests");
        return false;
      }

      final url = ApiConfig.getUri(ApiConfig.userProfile);
      
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
      );

      if (response.statusCode != 200) {
        print("⚠️ API /users/me trả về status ${response.statusCode}");
        return false;
      }

      final data = jsonDecode(response.body);
      final apiInterests = List<String>.from(data['interests'] ?? []);
      
      // 2. Lấy interests đã lưu trong SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedInterestsJson = prefs.getString(_interestsKey);
      
      List<String> savedInterests = [];
      if (savedInterestsJson != null) {
        try {
          savedInterests = List<String>.from(jsonDecode(savedInterestsJson));
        } catch (e) {
          print("⚠️ Lỗi parse interests từ SharedPreferences: $e");
        }
      }
      
      // 3. So sánh
      final hasChanged = !_areInterestsEqual(apiInterests, savedInterests);
      
      if (hasChanged) {
        print("🔄 [Cache] Interests thay đổi:");
        print("   Cũ: $savedInterests");
        print("   Mới: $apiInterests");
        
        // 4. Cập nhật interests mới vào SharedPreferences
        await prefs.setString(_interestsKey, jsonEncode(apiInterests));
        print("💾 [Cache] Đã cập nhật interests mới vào SharedPreferences");
      } else {
        print("✅ [Cache] Interests không thay đổi");
      }
      
      return hasChanged;
    } catch (e) {
      print("⚠️ Lỗi kiểm tra interests: $e");
      return false; // Nếu có lỗi, giữ nguyên cache
    }
  }

  bool _areInterestsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final setA = Set.from(a);
    final setB = Set.from(b);
    return setA.difference(setB).isEmpty && setB.difference(setA).isEmpty;
  }
}

class CachedExploreData {
  final Map<String, int> scores;
  final List<String> savedNames;
  final List<String> interests;
  final DateTime timestamp;

  CachedExploreData({
    required this.scores,
    required this.savedNames,
    required this.interests,
    required this.timestamp,
  });
}
>>>>>>> week10

class DestinationExploreScreen extends StatefulWidget {
  final String cityId;
  final String? restoreCityRawName;

  final int? currentIndex;
  final void Function(int)? onTabChange;
  final VoidCallback? onBack;
  final VoidCallback? onBeforeGroup;
  final VoidCallback? onSearchPlace;

<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> week10
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

<<<<<<< HEAD
=======
>>>>>>> 3ee7efe (done all groupapis)
=======
>>>>>>> week10
  @override
  State<DestinationExploreScreen> createState() => _DestinationExploreScreenState();
}

class _DestinationExploreScreenState extends State<DestinationExploreScreen> {
<<<<<<< HEAD
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
=======
  final RecommendationService _recommendService = RecommendationService();
  final UserService _userService = UserService();
  final ExploreCacheManager _cacheManager = ExploreCacheManager();

  List<DestinationExploreItem> _displayItems = [];
  Map<String, int> _compatibilityScores = {};

  // THAY ĐỔI: Tách riêng loading cho scores
  bool _isLoadingScores = true;  // Chỉ loading điểm số
  bool _isPageReady = false;     // Trang đã sẵn sàng hiển thị

  bool _hasLoadedOnce = false;
  String? _userAvatar;
  List<String> _currentInterests = [];

  Key _enterButtonKey = UniqueKey();

>>>>>>> week10
  String _normalizeName(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
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
=======
    _initializeScreen();
  }

  void _initializeScreen() {
    // 1. Load địa điểm từ mock data ngay lập tức
>>>>>>> week10
    _displayItems = mockExploreItems
        .where((item) => item.cityId == widget.cityId)
        .toList();

<<<<<<< HEAD
    // 3. Gọi load dữ liệu
=======
    for (var item in _displayItems) {
      item.isFavorite = false;
    }

    // 2. Đánh dấu trang đã sẵn sàng hiển thị
    setState(() {
      _isPageReady = true;
      _isLoadingScores = true; // Điểm số vẫn đang load
    });

    // 3. Load data trong background
>>>>>>> week10
    _loadAllData();
    _loadUserAvatar();
  }

  Future<void> _loadAllData() async {
<<<<<<< HEAD
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
=======
    try {
      print("🚀 [Explore] Bắt đầu load dữ liệu cho cityId: ${widget.cityId}");

      // 1. Kiểm tra cache SYNC (không gọi API)
      final cached = _cacheManager.getCacheSync(widget.cityId);

      if (cached != null) {
        // 2. Lấy interests hiện tại từ profile để so sánh
        final profile = await _userService.getUserProfile();
        final currentInterests = List<String>.from(profile?['interests'] ?? []);

        // 3. So sánh interests
        if (!_cacheManager.hasInterestsChanged(currentInterests, cached.interests)) {
          // Interests không đổi -> Dùng cache
          print("⚡ [Cache] Interests không đổi, sử dụng cache");
          _compatibilityScores = cached.scores;
          _currentInterests = cached.interests;
          _applySavedNames(cached.savedNames);

          _sortDisplayItems();

          if (mounted) {
            setState(() {
              _isLoadingScores = false;
            });
          }

          // Vẫn refresh savedNames trong background
          _refreshSavedNamesOnly();
          return;
        } else {
          print("🔄 [Cache] Interests đã thay đổi, cần tính lại");
          _cacheManager.invalidateCity(widget.cityId);
        }
      }

      // 4. Không có cache hoặc interests đã đổi -> Call API
      print("📡 [API] Đang gọi API tính recommendation...");

      final results = await Future.wait([
        _userService.getUserProfile(),
        _recommendService.getMyRecommendations(),
        _userService.getSavedItineraryNames(),
      ]);

      final profile = results[0] as Map<String, dynamic>?;
      final recommendations = results[1] as List<RecommendationOutput>;
      final savedNames = results[2] as List<String>;

      _currentInterests = List<String>.from(profile?['interests'] ?? []);

>>>>>>> week10
      _compatibilityScores.clear();
      for (var rec in recommendations) {
        _compatibilityScores[_normalizeName(rec.locationName)] = rec.score;
      }

<<<<<<< HEAD
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
=======
      // 5. Lưu vào cache
      await _cacheManager.setCache(
        widget.cityId,
        Map.from(_compatibilityScores),
        List.from(savedNames),
        List.from(_currentInterests),
      );

      _applySavedNames(savedNames);

      _sortDisplayItems();

      if (mounted) {
        setState(() {
          _isLoadingScores = false;
        });
      }

    } catch (e) {
      print("⚠️ Lỗi load data: $e");
      if (mounted) {
        setState(() {
          _isLoadingScores = false;
        });
      }
    }
  }


  Future<void> _refreshSavedNamesOnly() async {
    try {
      print("🔄 [Refresh] Chỉ cập nhật trạng thái tim...");

      final savedNames = await _userService.getSavedItineraryNames();
      print("📥 Nhận được ${savedNames.length} địa điểm đã lưu");

      _applySavedNames(savedNames);

      // Sử dụng method public thay vì truy cập private member
      await _cacheManager.updateSavedNames(widget.cityId, savedNames);

      if (mounted) setState(() {});

      print("✅ [Refresh] Đã cập nhật trạng thái tim");
    } catch (e) {
      print("⚠️ Lỗi refresh savedNames: $e");
    }
  }


  void _applySavedNames(List<String> savedNames) {
    int matchCount = 0;
    for (var item in _displayItems) {
      String itemNormal = _normalizeName(item.name);
      bool isSaved = savedNames.any((savedName) {
        return _normalizeName(savedName) == itemNormal;
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

  /// Sắp xếp danh sách địa điểm theo điểm tương thích từ cao đến thấp
  void _sortDisplayItems() {
    _displayItems.sort((a, b) {
      int scoreA = _getScore(a.name);
      int scoreB = _getScore(b.name);
      // Sắp xếp giảm dần (điểm cao lên trước)
      return scoreB.compareTo(scoreA);
    });

    _hasLoadedOnce = true;
    print("📊 [Sort] Đã sắp xếp ${_displayItems.length} địa điểm theo điểm tương thích");
  }

  Future<void> _loadUserAvatar() async {
>>>>>>> week10
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
<<<<<<< HEAD
    _loadAllData();
=======
    await _refreshSavedNamesOnly();
>>>>>>> week10
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

<<<<<<< HEAD
  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
=======
  void _showDescriptionPopup(BuildContext context, DestinationExploreItem item) {
    // Tách văn bản thành các đoạn nhỏ dựa trên 2 dấu xuống dòng để làm hiệu ứng xuất hiện từng đoạn
    List<String> paragraphs = item.description.split('\n\n');

    showGeneralDialog(
      context: context,
      barrierDismissible: true, // <--- QUAN TRỌNG: Cho phép nhấn ra ngoài để đóng
      barrierLabel: "Close",
      barrierColor: Colors.black.withOpacity(0.2), // Màu nền tối nhẹ phía sau lớp kính
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Stack(
          children: [
            // 1. Lớp kính mờ (Frosted Glass) toàn màn hình
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.transparent),
            ),

            // 2. Vùng nhận diện click để đóng (khi nhấn vào vùng mờ)
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                color: Colors.transparent,
                width: double.infinity,
                height: double.infinity,
              ),
            ),

            // 3. Nội dung chính (Popup)
            Center(
              child: GestureDetector(
                onTap: () {}, // Chặn click xuyên qua thẻ (để không bị đóng khi nhấn vào nội dung)
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                  ),
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    // Thay bằng ảnh nền da cam kết hợp lớp phủ màu kem
                    image: DecorationImage(
                      image: const AssetImage('assets/images/description.png'),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFB99668), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3E3322).withOpacity(0.3),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- Tiêu đề ---
                      Text(
                        item.name.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Alumni Sans', // Hoặc font có chân bạn thích
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: Colors.white, // Nâu đậm
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Đường kẻ trang trí
                      Container(width: 40, height: 2, color: const Color(0xFFB99668)),
                      const SizedBox(height: 20),

                      // --- Nội dung cuộn ---
                      Flexible(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Duyệt qua từng đoạn văn để tạo hiệu ứng Staggered (xuất hiện đuổi nhau)
                              ...paragraphs.map((text) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    text,
                                    style: const TextStyle(
                                      fontFamily: 'Alegreya',
                                      fontSize: 15,
                                      height: 1.6, // Giãn dòng dễ đọc
                                      color: Colors.white,
                                      decoration: TextDecoration.none,
                                    ),
                                    textAlign: TextAlign.justify,
                                  ),
                                );
                              }).toList()
                              // THÊM HIỆU ỨNG ANIMATION Ở ĐÂY
                                  .animate(interval: 100.ms) // Mỗi đoạn cách nhau 100ms
                                  .fade(duration: 600.ms, curve: Curves.easeOut) // Hiện dần
                                  .slideY(begin: 0.2, end: 0, duration: 600.ms, curve: Curves.easeOut), // Trượt nhẹ từ dưới lên
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                      // --- Nút đóng nhỏ bên dưới ---
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          "ĐÓNG",
                          style: TextStyle(color: Colors.white, letterSpacing: 1, fontSize: 13),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        // Hiệu ứng scale nhẹ khi popup hiện ra
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
>>>>>>> week10
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
<<<<<<< HEAD
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
=======
>>>>>>> week10
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        extendBody: true,
        appBar: AppBar(
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> week10
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: _handleBack),
<<<<<<< HEAD
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
=======
>>>>>>> week10
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
<<<<<<< HEAD
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator(color: Color(0xFFB64B12)))
                            : _displayItems.isEmpty
                            ? const Center(child: Text("Không tìm thấy địa điểm nào", style: TextStyle(color: Colors.white)))
=======
                        child: _displayItems.isEmpty
                            ? Center(
                          child: Text(
                            'no_places_found'.tr(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        )
>>>>>>> week10
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
<<<<<<< HEAD
=======
>>>>>>> week10
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
<<<<<<< HEAD
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
=======
>>>>>>> week10
              ),
            ),
          ],
        ),
      ),
    );
  }

<<<<<<< HEAD
<<<<<<< HEAD
  Widget _buildPlaceCard(DestinationExploreItem item, double cardWidth, double scaleFactor) {
    final score = _getScore(item.name);
=======
  Widget _buildPlaceCard(DestinationExploreItem item, double cardWidth, double scaleFactor) {
    final score = _getScore(item.name);

>>>>>>> week10
    return GestureDetector(
      onTap: () => _toggleFavorite(item),
      child: Container(
        width: cardWidth,
<<<<<<< HEAD
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
=======
        height: 380 * scaleFactor,
        decoration: BoxDecoration(
          color: const Color(0xFFD9D9D9),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Stack(
          children: [
            // Ảnh nền
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.asset(item.imageUrl, fit: BoxFit.cover),
              ),
            ),

            // THAY ĐỔI: Badge điểm tương thích với loading state
            Positioned(
              left: 16 * scaleFactor,
              top: 16 * scaleFactor,
              child: _buildCompatibilityBadge(score, scaleFactor),
            ),

            // Nút tim (giữ nguyên)
            Positioned(
              right: 16 * scaleFactor,
              top: 16 * scaleFactor,
              child: GestureDetector(
                onTap: () => _toggleFavorite(item),
                child: Container(
                  width: 32 * scaleFactor,
                  height: 32 * scaleFactor,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16 * scaleFactor),
                  ),
                  child: Icon(
                    item.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: item.isFavorite ? Colors.red : Colors.black.withOpacity(0.2),
                    size: 22 * scaleFactor,
                  ),
                ),
              ),
            ),

            // Tên địa điểm (giữ nguyên)
            Positioned(
              left: 20 * scaleFactor,
              bottom: 20 * scaleFactor,
              right: 20 * scaleFactor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18 * scaleFactor,
                      fontWeight: FontWeight.w700,
                      shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4 * scaleFactor),
                  Text(
                    item.getSubtitle(context.locale.languageCode),
                    style: TextStyle(
                      color: const Color(0xFFDDDDDD),
                      fontSize: 13 * scaleFactor,
                      shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),
                ],
              ),
            ),

            // Nút mô tả (giữ nguyên)
            Positioned(
              right: 16 * scaleFactor,
              bottom: 16 * scaleFactor,
              child: GestureDetector(
                onTap: () => _showDescriptionPopup(context, item),
                child: Container(
                  width: 36 * scaleFactor,
                  height: 36 * scaleFactor,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3E3322).withOpacity(0.9),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFB99668), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Icon(
                    Icons.auto_stories_outlined,
                    color: const Color(0xFFEDE2CC),
                    size: 18 * scaleFactor,
                  ),
                ),
              ),
>>>>>>> week10
            ),
          ],
        ),
      ),
<<<<<<< HEAD
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
=======
    );
  }

  /// Widget badge hiển thị điểm tương thích hoặc loading
  Widget _buildCompatibilityBadge(int score, double scaleFactor) {
    // Nếu đang loading scores
    if (_isLoadingScores) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: 10 * scaleFactor,
          vertical: 6 * scaleFactor,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF3E3322).withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFB99668), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14 * scaleFactor,
              height: 14 * scaleFactor,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: const Color(0xFFB99668),
              ),
            ),
            SizedBox(width: 6 * scaleFactor),
            Text(
              'Đang tính...',
              style: TextStyle(
                color: const Color(0xFFEDE2CC),
                fontSize: 12 * scaleFactor,
                fontWeight: FontWeight.w500,
                fontFamily: 'Roboto',
              ),
            ),
          ],
        ),
      );
    }

    // Nếu có điểm số
    if (score > 0) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: 10 * scaleFactor,
          vertical: 6 * scaleFactor,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFB64B12).withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              color: Colors.yellow,
              size: 14 * scaleFactor,
            ),
            SizedBox(width: 4 * scaleFactor),
            Text(
              '$score% Hợp',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14 * scaleFactor,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
              ),
            ),
          ],
        ),
      );
    }

    // Không có điểm và không loading -> ẩn badge
    return const SizedBox.shrink();
  }

>>>>>>> week10
}