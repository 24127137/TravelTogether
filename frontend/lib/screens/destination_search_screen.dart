import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../data/mock_explore_items.dart';
import '../models/destination_explore_item.dart';
import '../services/recommendation_service.dart';
import '../services/user_service.dart';

class DestinationSearchScreen extends StatefulWidget {
  final String cityId;
  // THÊM: Biến nhận điểm số từ màn hình trước truyền qua
  final Map<String, int>? preloadedScores;

  const DestinationSearchScreen({
    Key? key,
    required this.cityId,
    this.preloadedScores, // Constructor nhận biến này
  }) : super(key: key);

  @override
  _DestinationSearchScreenState createState() => _DestinationSearchScreenState();
}

class _DestinationSearchScreenState extends State<DestinationSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final RecommendationService _recommendService = RecommendationService();
  final UserService _userService = UserService();

  String _searchText = '';
  Map<String, int> _compatibilityScores = {};

  @override
  void initState() {
    super.initState();
    // LOGIC MỚI:
    // Nếu màn hình trước đã truyền điểm qua -> Dùng luôn
    if (widget.preloadedScores != null && widget.preloadedScores!.isNotEmpty) {
      _compatibilityScores = widget.preloadedScores!;
    } else {
      // Chỉ gọi API nếu không có dữ liệu truyền qua (Fallback)
      _loadCompatibilityScores();
    }
  }

  Future<void> _loadCompatibilityScores() async {
    try {
      final recommendations = await _recommendService.getMyRecommendations();
      if (mounted) {
        setState(() {
          for (var rec in recommendations) {
            _compatibilityScores[rec.locationName.toLowerCase().trim()] = rec.score;
          }
        });
      }
    } catch (e) { /* Ignore error */ }
  }

  int _getScore(String locationName) {
    return _compatibilityScores[locationName.toLowerCase().trim()] ?? 0;
  }

  void _toggleFavorite(DestinationExploreItem item) async {
    setState(() {
      item.isFavorite = !item.isFavorite;
    });
    await _userService.toggleItineraryItem(item.name, item.isFavorite);
  }

  @override
  Widget build(BuildContext context) {
    // ... (Giữ nguyên phần UI Build không thay đổi) ...
    // Copy lại toàn bộ hàm build từ code cũ của bạn
    final currentLocale = context.locale.languageCode;

    final filteredItems = mockExploreItems
        .where((item) =>
    item.cityId == widget.cityId &&
        (item.name.toLowerCase().contains(_searchText.toLowerCase()) ||
            item.getSubtitle(currentLocale).toLowerCase().contains(_searchText.toLowerCase())))
        .toList();

    filteredItems.sort((a, b) {
      int scoreA = _getScore(a.name);
      int scoreB = _getScore(b.name);
      if (scoreA == 0 && scoreB == 0) return 0;
      return scoreB.compareTo(scoreA);
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Container(
            width: double.infinity, color: Colors.white,
            padding: const EdgeInsets.only(left: 24.0, top: 16.0),
            child: Text('place'.tr(), style: const TextStyle(fontFamily: 'Alumni Sans', fontWeight: FontWeight.w800, fontSize: 30, color: Colors.black)),
          ),
          _buildSearchBar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: GridView.builder(
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.75,
                ),
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  final score = _getScore(item.name);
                  return _buildDestinationCard(item, score);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ... (Giữ nguyên _buildHeader, _buildSearchBar, _buildDestinationCard) ...
  Widget _buildHeader() {
    return Container(
      width: double.infinity, color: const Color(0xFFB99668),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 56, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Stack(
            children: [
              Positioned(
                top: 0, right: 0,
                child: GestureDetector(onTap: () => Navigator.of(context).maybePop(), child: Container(padding: const EdgeInsets.all(4), child: const Icon(Icons.close, color: Colors.black, size: 32))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchText = value),
        decoration: InputDecoration(hintText: 'search_place'.tr(), filled: true, fillColor: const Color(0xFFEDE2CC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none), prefixIcon: const Icon(Icons.search, color: Colors.black), contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20)),
      ),
    );
  }

  Widget _buildDestinationCard(DestinationExploreItem item, int score) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2))]),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Positioned.fill(child: Image.asset(item.imageUrl, fit: BoxFit.cover)),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 78.0, padding: const EdgeInsets.all(10.0),
                    decoration: const BoxDecoration(color: Color.fromRGBO(237, 226, 204, 0.92), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(item.name, style: const TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black, height: 1.1), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(item.getSubtitle(context.locale.languageCode), style: const TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w400, fontSize: 11, color: Color(0xFF555555)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 8, left: 8,
          child: GestureDetector(
            onTap: () => _toggleFavorite(item),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), shape: BoxShape.circle),
              child: Icon(item.isFavorite ? Icons.favorite : Icons.favorite_border, color: item.isFavorite ? Colors.red : Colors.white, size: 20),
            ),
          ),
        ),
        if (score > 0)
          Positioned(
            top: 8, right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFB64B12).withOpacity(0.95), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white, width: 1), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]),
              child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.auto_awesome, color: Colors.yellow, size: 12), const SizedBox(width: 4), Text('$score%', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Roboto'))]),
            ),
          ),
      ],
    );
  }
}