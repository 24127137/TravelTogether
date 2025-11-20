/// File: destination_search_screen.dart
/// Mô tả: Màn hình tìm kiếm và chọn điểm đến, giao diện tiếng Việt.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../data/mock_explore_items.dart';
import '../models/destination_explore_item.dart';
//File này là screen tên là <Destination_search> trong figma
class DestinationSearchScreen extends StatefulWidget {
  final String cityId;
  const DestinationSearchScreen({Key? key, required this.cityId}) : super(key: key);

  @override
  _DestinationSearchScreenState createState() => _DestinationSearchScreenState();
}

class _DestinationSearchScreenState extends State<DestinationSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale.languageCode;
    final filteredItems = mockExploreItems
        .where((item) =>
    item.cityId == widget.cityId &&
        (item.name.toLowerCase().contains(_searchText.toLowerCase()) ||
            item.getSubtitle(currentLocale).toLowerCase().contains(_searchText.toLowerCase())))
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          // Chữ "Địa điểm" nằm dưới header, căn trái, không nằm trong header
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
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.8,
                ),
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  return _buildDestinationCard(item);
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
      height: 64, // tăng chiều cao header để nút X nằm hoàn toàn trong header
      color: const Color(0xFFB99668),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned(
              top: 6, // chỉnh top từ 16 thành 8 để nút X dịch lên sát mép trên header
              right: 8,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).maybePop();
                },
                child: const Icon(
                  Icons.close,
                  color: Colors.black,
                  size: 32,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 0.0), // Giảm top padding để search bar gần card
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchText = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'search_place'.tr(),
          filled: true,
          fillColor: const Color(0xFFEDE2CC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          prefixIcon: const Icon(Icons.search, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildDestinationCard(DestinationExploreItem item) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Card địa điểm
        Positioned.fill(
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            shadowColor: const Color(0x33000000),
            child: Stack(
              children: [
                // Hình ảnh nền
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),

                // Icon Yêu thích
                Positioned(
                  top: 8,
                  left: 8,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        item.isFavorite = !item.isFavorite;
                      });
                    },
                    child: Icon(
                      item.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: item.isFavorite ? Colors.red : Colors.white,
                    ),
                  ),
                ),

                // Phần nền màu be và chữ ở dưới cùng
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(237, 226, 204, 0.85), // MÀU NỀN VÀ ĐỘ TRONG SUỐT
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name, // TÊN ĐỊA ĐIỂM
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          item.getSubtitle(context.locale.languageCode), // Dịch subtitle
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            color: Colors.black,
                          ),
                          maxLines: 2,
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
        // Pill-shaped tag at bottom-right (inset so it doesn't overflow rounded corner)
// Thay thế đoạn Positioned cũ bằng đoạn code này
        Positioned(
          bottom: 160, // Vị trí cách đáy 160px (giữ nguyên theo code bạn cung cấp)
          right: 8,  // Vị trí cách phải 8px
          child: Container(
            // Đảm bảo không có màu nền bao quanh (Transparent)
            color: Colors.transparent,
            // Dùng Row để căn chỉnh điểm rating và icon
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end, // Căn sang phải
              mainAxisSize: MainAxisSize.min, // Giúp Row chiếm ít không gian nhất có thể
              children: [
                // 1. Text Rating (PHÓNG TO và BỎ %)
                Text(
                  // Chỉ lấy giá trị rating, chuyển sang String và BỎ DẤU %
                  item.rating.toString(),
                  style: const TextStyle(
                    color: Colors.white, // Màu chữ trắng
                    fontSize: 18, // <-- PHÓNG TO FONT
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w800, // Làm đậm hơn để nổi bật
                    shadows: [ // Thêm shadow nhẹ để nổi bật trên ảnh
                      Shadow(color: Colors.black, blurRadius: 4), // Tăng blur radius shadow
                    ],
                  ),
                ),
                const SizedBox(width: 6), // <-- TĂNG KHOẢNG CÁCH một chút
                // 2. Icon Tag (PHÓNG TO)
                const Icon(
                  Icons.local_offer,
                  color: Colors.white, // Màu icon trắng
                  size: 26, // <-- PHÓNG TO ICON
                  shadows: [ // Thêm shadow nhẹ để nổi bật trên ảnh
                    Shadow(color: Colors.black, blurRadius: 4), // Tăng blur radius shadow
                  ],
                ),
              ],
            ),
          ),
        ),
       ],
     );
   }
}

