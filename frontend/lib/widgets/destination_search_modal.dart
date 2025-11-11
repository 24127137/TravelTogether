/// File: destination_search_modal.dart
/// Mô tả: Modal tìm kiếm điểm đến

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../data/mock_destinations.dart';
import '../models/destination.dart';

const kAppBgColor = Color(0xFFA15C20);
const kCardColor = Color(0xFFEDE2CC);
const kAccentColor = Color(0xFFB64B12);
const kSubtleColor = Color(0xFFB89568);
const kTitleColor = Color(0xFF000000);
const kPrimaryTextColor = Color(0xFF000000);
const kHintTextColor = Color(0xFF7F3E8);
const kSearchBarBgColor = Color(0xFFF7F3E8);

class DestinationSearchModal extends StatefulWidget {
  final ValueChanged<Destination> onSelect;
  const DestinationSearchModal({Key? key, required this.onSelect}) : super(key: key);

  @override
  _DestinationSearchModalState createState() => _DestinationSearchModalState();
}

class _DestinationSearchModalState extends State<DestinationSearchModal> {
  String _query = '';
  late List<Destination> _results;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _results = List<Destination>.from(mockDestinations);
  }

  void _onChanged(String v) {
    setState(() {
      _query = v.trim().toLowerCase();
      if (_query.isEmpty) {
        _results = List<Destination>.from(mockDestinations);
      } else {
        _results = mockDestinations.where((d) {
          final q = _query;
          return d.name.toLowerCase().contains(q) ||
              d.province.toLowerCase().contains(q) ||
              d.location.toLowerCase().contains(q) ||
              d.description.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    // Header widget được tách riêng để dùng trong SliverPersistentHeader
    Widget buildHeader(BuildContext ctx) {
      return Container(
        color: kAppBgColor,
        padding: const EdgeInsets.only(top: 10, bottom: 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: kSubtleColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 13),
            Text(
              'search_city'.tr(),
              style: const TextStyle(
                color: kCardColor,
                fontSize: 22,
                fontFamily: 'Alegreya',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 11),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _onChanged,
                style: const TextStyle(
                  color: kTitleColor,
                  fontFamily: 'Alegreya',
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'location'.tr(),
                  hintStyle: const TextStyle(
                    color: kSubtleColor,
                    fontFamily: 'Alegreya',
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: kSubtleColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: kSearchBarBgColor,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 5),
          ],
        ),
      );
    }

    return Material(
      color: kAppBgColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: CustomScrollView(
              slivers: [
                // Header cố định (pinned) - không bị list đè lên
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _ModalHeaderDelegate(
                    child: buildHeader,
                    minHeight: 142,
                    maxHeight: 142,
                  ),
                ),

                // Nội dung: empty state hoặc danh sách
                if (_results.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'no_results'.tr(),
                        style: const TextStyle(
                          color: kCardColor,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final d = _results[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              onTap: () => widget.onSelect(d),
                              tileColor: kCardColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  d.imagePath,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              title: Text(
                                d.name,
                                style: const TextStyle(
                                  fontFamily: 'Alegreya',
                                  color: kTitleColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 19,
                                ),
                              ),
                              subtitle: Text(
                                d.province,
                                style: const TextStyle(
                                  fontFamily: 'Alegreya',
                                  color: kPrimaryTextColor,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: _results.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Delegate cho SliverPersistentHeader - giúp header cố định khi cuộn
class _ModalHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget Function(BuildContext) child;
  final double minHeight;
  final double maxHeight;

  _ModalHeaderDelegate({
    required this.child,
    required this.minHeight,
    required this.maxHeight,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child(context);
  }

  @override
  bool shouldRebuild(covariant _ModalHeaderDelegate oldDelegate) {
    return oldDelegate.minHeight != minHeight ||
        oldDelegate.maxHeight != maxHeight ||
        oldDelegate.child != child;
  }
}

