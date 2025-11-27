/// File: home_page.dart
/// Trạng thái: Đã sửa lỗi layout (Unbounded Height)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import '../data/mock_destinations.dart';
import '../models/destination.dart';
import '../widgets/destination_search_modal.dart';
import '../widgets/calendar_card.dart';
import 'group_matcing_announcement_screen.dart'; // Kiểm tra lại tên file này xem có đúng chính tả "matching" không nhé

class HomePage extends StatefulWidget {
  final void Function(Destination)? onDestinationTap;
  final VoidCallback? onSettingsTap;
  const HomePage({Key? key, this.onDestinationTap, this.onSettingsTap}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Trạng thái cho bộ chọn ngày
  bool _isCalendarVisible = false;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  DateTime _focusedDay = DateTime.now();

  String get _durationText {
    if (_rangeStart == null) return 'travel_time'.tr();
    final format = DateFormat('dd/MM');
    if (_rangeEnd == null) return format.format(_rangeStart!);
    return '${format.format(_rangeStart!)} - ${format.format(_rangeEnd!)}';
  }

  void _showCalendar() => setState(() => _isCalendarVisible = true);

  void _hideCalendar() => setState(() => _isCalendarVisible = false);

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      if (_rangeStart == null || _rangeEnd != null) {
        _rangeStart = selectedDay;
      } else if (selectedDay.isAfter(_rangeStart!)) {
        _rangeEnd = selectedDay;
      } else {
        _rangeStart = selectedDay;
        _rangeEnd = null;
      }
      _focusedDay = focusedDay;
    });
  }

  void _openDestinationScreen() {
    print('Opening destination modal...');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (ctx) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: DestinationSearchModal(
            onSelect: (Destination dest) {
              print('Destination selected: ${dest.name}');
              Navigator.of(ctx).pop();
              if (widget.onDestinationTap != null) {
                widget.onDestinationTap!(dest);
              }
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lấy 5 thành phố có rating cao nhất
    final top5Cities = List<Destination>.from(mockDestinations)
      ..sort((a, b) => b.rating.compareTo(a.rating));
    final top5 = top5Cities.take(5).toList();

    return Container(
      color: const Color(0xFFB99668), // Màu nền Scaffold cũ
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            // --- FIX QUAN TRỌNG: Positioned.fill ---
            // Bắt buộc Column phải khớp độ cao với Stack để Expanded hoạt động
            Positioned.fill(
              child: Column(
                children: [
                  // 1. Phần Fixed (Cố định)
                  _TopSection(
                    durationText: _durationText,
                    onDestinationTap: _openDestinationScreen,
                    onDurationTap: _showCalendar,
                    onSettingsTap: widget.onSettingsTap,
                  ),

                  // 2. Phần Scroll (Cuộn) - Chiếm hết không gian còn lại
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "top_destinations".tr(),
                                style: const TextStyle(
                                  color: Color(0xFFFFFFFF),
                                  fontSize: 19,
                                  fontFamily: 'Alegreya',
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Render danh sách thành phố
                              ...top5.map((dest) => _RecommendedCard(
                                destination: dest,
                                onTap: widget.onDestinationTap,
                              )).toList(),

                              // Padding cuối cùng để tránh bị BottomNavigationBar bên ngoài che
                              SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Lớp phủ Calendar (nằm trên cùng Stack)
            if (_isCalendarVisible)
              _CalendarOverlay(
                focusedDay: _focusedDay,
                rangeStart: _rangeStart,
                rangeEnd: _rangeEnd,
                onDaySelected: _onDaySelected,
                onClose: _hideCalendar,
                onPageChanged: (day) => setState(() => _focusedDay = day),
              ),
          ],
        ),
      ),
    );
  }
}

// --- Top Section Widgets ---
class _TopSection extends StatelessWidget {
  final String durationText;
  final VoidCallback onDestinationTap;
  final VoidCallback onDurationTap;
  final VoidCallback? onSettingsTap;

  const _TopSection({
    required this.durationText,
    required this.onDestinationTap,
    required this.onDurationTap,
    this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Thêm padding top an toàn cho notch/status bar.
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 20),
      decoration: const BoxDecoration(
          color: Color(0xFFEDE2CC), // Cream color
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          )),
      child: Column(
        children: [
          _CustomAppBar(onSettingsTap: onSettingsTap),
          const SizedBox(height: 24),
          _SelectionButton(
            hint: 'destination'.tr(),
            icon: Icons.search,
            onTap: onDestinationTap,
          ),
          const SizedBox(height: 12),
          _SelectionButton(
            hint: durationText,
            icon: Icons.calendar_today_outlined,
            onTap: onDurationTap,
          ),
        ],
      ),
    );
  }
}

class _CustomAppBar extends StatelessWidget {
  final VoidCallback? onSettingsTap;

  const _CustomAppBar({this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          decoration: const ShapeDecoration(
            shape: OvalBorder(
              side: BorderSide(
                width: 2,
                strokeAlign: BorderSide.strokeAlignCenter,
                color: Color(0xFFF7F3E8),
              ),
            ),
          ),
          child: const CircleAvatar(
            // LƯU Ý: Đảm bảo asset này tồn tại trong pubspec.yaml
            backgroundImage: AssetImage('assets/images/avatar.jpg'),
            radius: 18,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'hello_user'.tr(),
          style: const TextStyle(
              fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            // LƯU Ý: Đảm bảo GroupMatchingAnnouncementScreen được import đúng
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => GroupMatchingAnnouncementScreen(
                groupName: '1 tháng 2 lần',
                onBack: () {
                  Navigator.of(context).pop();
                },
              ),
            ));
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: const ShapeDecoration(
              color: Color(0xFFF7F3E8),
              shape: OvalBorder(),
            ),
            child: const Icon(Icons.campaign, size: 20, color: Color(0xFF3E3322)),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onSettingsTap,
          child: Container(
            width: 36,
            height: 36,
            decoration: const ShapeDecoration(
              color: Color(0xFFF7F3E8),
              shape: OvalBorder(),
            ),
            child: const Icon(Icons.settings, size: 20, color: Color(0xFF3E3322)),
          ),
        ),
      ],
    );
  }
}

class _SelectionButton extends StatelessWidget {
  final String hint;
  final IconData icon;
  final VoidCallback onTap;

  const _SelectionButton({required this.hint, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFA15C20);

    final isDateHint = RegExp(r'\d{2}/\d{2}').hasMatch(hint);
    final isDefaultHint = hint == 'destination'.tr() || hint == 'travel_time'.tr();

    final textColor = isDefaultHint
        ? accentColor
        : (isDateHint ? accentColor : Colors.black);

    return Material(
      color: const Color(0xFFF7F3E8),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          print('SelectionButton tapped: $hint');
          onTap();
        },
        child: Container(
          height: 43,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFFA15C20)),
              const SizedBox(width: 8),
              Text(
                hint,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontFamily: 'Poppins',
                  fontWeight: isDefaultHint ? FontWeight.w400 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Recommended Section ---
class _RecommendedCard extends StatelessWidget {
  final Destination destination;
  final void Function(Destination)? onTap;
  const _RecommendedCard({required this.destination, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) onTap!(destination);
      },
      child: Container(
        height: 200,
        margin: const EdgeInsets.only(bottom: 20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(destination.imagePath, fit: BoxFit.cover),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withAlpha((0.1 * 255).toInt()),
                            Colors.black.withAlpha((0.3 * 255).toInt()),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 15,
                    child: SizedBox(
                      width: constraints.maxWidth - 30,
                      child: Text(
                        destination.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontFamily: 'AlumniSans',
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(
                              blurRadius: 5.0,
                              color: Colors.black,
                              offset: Offset(1.0, 1.0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// --- Calendar Overlay ---
class _CalendarOverlay extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(DateTime) onPageChanged;
  final VoidCallback onClose;

  const _CalendarOverlay(
      {required this.focusedDay,
        this.rangeStart,
        this.rangeEnd,
        required this.onDaySelected,
        required this.onPageChanged,
        required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: onClose,
        child: Container(
          color: Colors.black.withAlpha((0.5 * 255).toInt()),
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () {},
            child: CalendarCard(
              focusedDay: focusedDay,
              rangeStart: rangeStart,
              rangeEnd: rangeEnd,
              onDaySelected: onDaySelected,
              onPageChanged: onPageChanged,
              onClose: onClose,
            ),
          ),
        ),
      ),
    );
  }
}