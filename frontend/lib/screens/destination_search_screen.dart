/// Mô tả: Màn hình tìm kiếm, tích hợp AI Score và tối ưu giao diện thẻ.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../data/mock_explore_items.dart';
import '../models/destination_explore_item.dart';
import '../services/recommendation_service.dart'; // Import service

class DestinationSearchScreen extends StatefulWidget {
  final String cityId;
  const DestinationSearchScreen({Key? key, required this.cityId}) : super(key: key);

  @override
  _DestinationSearchScreenState createState() => _DestinationSearchScreenState();
}

class _DestinationSearchScreenState extends State<DestinationSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final RecommendationService _recommendService = RecommendationService();

  String _searchText = '';

  // Map lưu điểm số AI: Key = Tên địa điểm (chuẩn hóa), Value = Điểm %
  Map<String, int> _compatibilityScores = {};
  bool _isLoadingScore = true;

  @override
  void initState() {
    super.initState();
    _loadCompatibilityScores();
  }

  // Gọi API lấy điểm tương thích
  Future<void> _loadCompatibilityScores() async {
    try {
      final recommendations = await _recommendService.getMyRecommendations();

      if (mounted) {
        setState(() {
          for (var rec in recommendations) {
            String apiName = rec.locationName.toLowerCase().trim();
            _compatibilityScores[apiName] = rec.score;
          }
          _isLoadingScore = false;
        });
      }
    } catch (e) {
      print('⚠️ Search Screen: Không tải được điểm AI ($e) - Ẩn phần %');
      if (mounted) setState(() => _isLoadingScore = false);
    }
  }

  // Helper lấy điểm
  int _getScore(String locationName) {
    String key = locationName.toLowerCase().trim();
    return _compatibilityScores[key] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale.languageCode;

    // Lọc danh sách theo Search Text
    final filteredItems = mockExploreItems
        .where((item) =>
    item.cityId == widget.cityId &&
        (item.name.toLowerCase().contains(_searchText.toLowerCase()) ||
            item.getSubtitle(currentLocale).toLowerCase().contains(_searchText.toLowerCase())))
        .toList();

    // Sắp xếp: Nếu có điểm AI, đưa địa điểm điểm cao lên đầu
    filteredItems.sort((a, b) {
      int scoreA = _getScore(a.name);
      int scoreB = _getScore(b.name);
      if (scoreA == 0 && scoreB == 0) return 0; // Giữ nguyên nếu không có điểm
      return scoreB.compareTo(scoreA); // Cao xếp trước
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),

          // Title "Địa điểm"
          Container(
            width: double.infinity,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.only(left: 24.0, top: 16.0, bottom: 0.0),
              child: Text(
                'place'.tr(),
                style: const TextStyle(
                  fontFamily: 'Alumni Sans',
                  fontWeight: FontWeight.w800,
                  fontSize: 34,
                  color: Colors.black,
                ),
              ),
            ),
          ),

          _buildSearchBar(),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: GridView.builder(
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75, // Tỷ lệ khung hình thẻ (Cao hơn chút để chứa info)
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFB99668),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.close, color: Colors.black, size: 32),
                  ),
                ),
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
        decoration: InputDecoration(
          hintText: 'search_place'.tr(),
          filled: true,
          fillColor: const Color(0xFFEDE2CC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          prefixIcon: const Icon(Icons.search, color: Colors.black),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildDestinationCard(DestinationExploreItem item, int score) {
    // Cố định chiều cao phần text để giao diện đồng đều
    const double textContainerHeight = 78.0;

    return Stack(
      children: [
        // Card nền
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2))
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // 1. Hình ảnh (Full Card)
                Positioned.fill(
                  child: Image.asset(
                    item.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),

                // 2. Khung Text màu be (Cố định ở đáy)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: textContainerHeight, // QUAN TRỌNG: Chiều cao cố định
                    padding: const EdgeInsets.all(10.0),
                    decoration: const BoxDecoration(
                      color: Color.fromRGBO(237, 226, 204, 0.92), // Màu be đậm hơn chút
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center, // Căn giữa theo chiều dọc
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.black,
                            height: 1.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.getSubtitle(context.locale.languageCode),
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w400,
                            fontSize: 11,
                            color: Color(0xFF555555),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 3. Nút Yêu thích (Góc trái trên - Giống Explore Screen)
        Positioned(
          top: 8,
          left: 8,
          child: GestureDetector(
            onTap: () {
              setState(() {
                item.isFavorite = !item.isFavorite;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: item.isFavorite ? Colors.red : Colors.white,
                size: 20,
              ),
            ),
          ),
        ),

        // 4. Badge % Tương thích (Thay thế Icon Tag cũ) - Đặt góc PHẢI TRÊN
        if (score > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFB64B12).withOpacity(0.95), // Màu cam thương hiệu
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 1),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.yellow, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    '$score%', // Chỉ hiện số % cho gọn
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}