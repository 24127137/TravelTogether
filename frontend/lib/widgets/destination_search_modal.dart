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
        final currentLocale = context.locale.languageCode;
        _results = mockDestinations.where((d) {
          final q = _query;
          return d.name.toLowerCase().contains(q) ||
              d.province.toLowerCase().contains(q) ||
              d.location.toLowerCase().contains(q) ||
              d.getDescription(currentLocale).toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kAppBgColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
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
                const SizedBox(height: 16),
              ],
            ),
          ),


          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: kCardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: _results.isEmpty
                  ? Center(
                      child: Text(
                        'no_results'.tr(),
                        style: const TextStyle(
                          color: kTitleColor,
                          fontSize: 16,
                          fontFamily: 'Alegreya',
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: _results.length,
                      itemBuilder: (ctx, i) {
                        final d = _results[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            elevation: 2,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => widget.onSelect(d),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.asset(
                                        d.imagePath,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 56,
                                            height: 56,
                                            color: kSubtleColor,
                                            child: const Icon(Icons.image, color: Colors.white),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            d.name,
                                            style: const TextStyle(
                                              fontFamily: 'Alegreya',
                                              color: kTitleColor,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 19,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            d.province,
                                            style: const TextStyle(
                                              fontFamily: 'Alegreya',
                                              color: kPrimaryTextColor,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

