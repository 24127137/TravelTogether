/// File: home_page.dart
/// Mô tả: Widget nội dung cho tab Trang chủ. Đã dịch sang tiếng Việt.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
<<<<<<< HEAD
import 'package:easy_localization/easy_localization.dart';
import '../data/mock_destinations.dart';
import '../models/destination.dart';
import 'package:table_calendar/table_calendar.dart';
import '../widgets/destination_search_modal.dart';
import '../widgets/calendar_card.dart';

class HomePage extends StatefulWidget {
  final void Function(Destination)? onDestinationTap;
  final VoidCallback? onSettingsTap;
  const HomePage({Key? key, this.onDestinationTap, this.onSettingsTap}) : super(key: key);
=======
import 'package:my_travel_app/data/mock_destinations.dart';
import 'package:my_travel_app/models/destination.dart';
import 'package:table_calendar/table_calendar.dart';

class HomePage extends StatefulWidget {
  final void Function(Destination)? onDestinationTap;
  const HomePage({Key? key, this.onDestinationTap}) : super(key: key);
>>>>>>> 9fb9c5b (Add homepage frontend and after that implementation)

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
<<<<<<< HEAD
    if (_rangeStart == null) return 'travel_time'.tr();
=======
    if (_rangeStart == null) return 'Thời gian du lịch (ngày)';
>>>>>>> 9fb9c5b (Add homepage frontend and after that implementation)
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
<<<<<<< HEAD
    print('Opening destination modal...');
=======
    // debug
    // ignore: avoid_print
    print('home_page._openDestinationScreen called');
    // Mở modal tìm kiếm để người dùng gõ và chọn điểm đến từ mock data
>>>>>>> 9fb9c5b (Add homepage frontend and after that implementation)
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
<<<<<<< HEAD
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
=======
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.85,
        child: DestinationSearchModal(
          onSelect: (Destination dest) {
            Navigator.of(ctx).pop(); // đóng modal
            if (widget.onDestinationTap != null) {
              widget.onDestinationTap!(dest);
            }
          },
        ),
      ),
>>>>>>> 9fb9c5b (Add homepage frontend and after that implementation)
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lấy 5 thành phố có rating cao nhất
    final top5Cities = List<Destination>.from(mockDestinations)
      ..sort((a, b) => b.rating.compareTo(a.rating));
    final top5 = top5Cities.take(5).toList();

    // 1. Loại bỏ Scaffold và BottomNavigationBar
    // 2. Wrap nội dung chính bằng Container có màu nền Scaffold cũ
    return Container(
      color: const Color(0xFFB99668), // Màu nền Scaffold cũ
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            // Dùng ListView để nội dung cuộn được.
            ListView(
              padding: EdgeInsets.zero,
              children: [
                _TopSection(
                  durationText: _durationText,
                  onDestinationTap: _openDestinationScreen,
                  onDurationTap: _showCalendar,
<<<<<<< HEAD
                  onSettingsTap: widget.onSettingsTap,
=======
>>>>>>> 9fb9c5b (Add homepage frontend and after that implementation)
                ),
                // Hiển thị 5 thẻ thành phố rating cao nhất
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
<<<<<<< HEAD
                      Text(
                        "top_destinations".tr(),
                        style: const TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontSize: 19,
                          fontFamily: 'Alegreya',
                          fontWeight: FontWeight.w900,
=======
                      const Text(
                        "Danh sách gợi ý",
                        style: TextStyle(
                          color: Color(0xFFE3D1B4),
                          fontSize: 19,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w700,
>>>>>>> 9fb9c5b (Add homepage frontend and after that implementation)
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...top5.map((dest) => _RecommendedCard(destination: dest, onTap: widget.onDestinationTap)).toList(),
                    ],
                  ),
                ),
                // Padding cuối cùng để tránh bị BottomNavigationBar bên ngoài che.
                SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
              ],
            ),
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
<<<<<<< HEAD
  final VoidCallback? onSettingsTap;
=======
>>>>>>> 9fb9c5b (Add homepage frontend and after that implementation)

  const _TopSection({
    required this.durationText,
    required this.onDestinationTap,
    required this.onDurationTap,
<<<<<<< HEAD
    this.onSettingsTap,
=======
>>>>>>> 9fb9c5b (Add homepage frontend and after that implementation)
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Thêm padding top an toàn cho notch/status bar.
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 20),
      decoration: const BoxDecoration(
          color: Color(0xFFEDE2CC), // Cream color for the top section
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          )),
      child: Column(
        children: [
<<<<<<< HEAD
          _CustomAppBar(onSettingsTap: onSettingsTap),
          const SizedBox(height: 24),
          _SelectionButton(
            hint: 'destination'.tr(),
=======
          const _CustomAppBar(),
          const SizedBox(height: 24),
          _SelectionButton(
            hint: 'Điểm đến',
>>>>>>> 9fb9c5b (Add homepage frontend and after that implementation)
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
<<<<<<< HEAD
  final VoidCallback? onSettingsTap;

  const _CustomAppBar({this.onSettingsTap});
=======
  const _CustomAppBar();
>>>>>>> 9fb9c5b (Add homepage frontend and after that implementation)

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          decoration: ShapeDecoration(
            shape: OvalBorder(
              side: BorderSide(
                width: 2,
                strokeAlign: BorderSide.strokeAlignCenter,
                color: const Color(0xFFF7F3E8),
              ),
            ),
          ),
          child: const CircleAvatar(
            // Cần đảm bảo asset này tồn tại
            // Thay thế bằng NetworkImage nếu cần
            backgroundImage: AssetImage('assets/images/avatar.jpg'),
            radius: 18,
          ),
        ),
        const SizedBox(width: 12),
<<<<<<< HEAD
        Text(
          'hello_user'.tr(),
          style: const TextStyle(
              fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onSettingsTap,
          child: Container(
            width: 36,
            height: 36,
            decoration: const ShapeDecoration(
              color: Color(0xFFF7F3E8),
              shape: OvalBorder(),
            ),
            child: const Icon(Icons.settings, size: 20, color: Color(0xFF3E3322),),
          ),
=======
        const Text(
          'Xin chào, Toàn Handsome',
          style: TextStyle(
              fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        Container(
          width: 36,
          height: 36,
          decoration: const ShapeDecoration(
            color: Color(0xFFF7F3E8),
            shape: OvalBorder(),
          ),
          child: const Icon(Icons.notifications_none, size: 20, color: Color(0xFF3E3322),),
>>>>>>> 9fb9c5b (Add homepage frontend and after that implementation)
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
<<<<<<< HEAD
    const accentColor = Color(0xFFA15C20);

    // Detect if the hint contains a date (e.g. "dd/MM" or a date range with '-').
    final isDateHint = RegExp(r'\d{2}/\d{2}').hasMatch(hint);
    final isDefaultHint = hint == 'destination'.tr() || hint == 'travel_time'.tr();

    final textColor = isDefaultHint
        ? accentColor
        : (isDateHint ? accentColor : Colors.black);

=======
    final isDefaultHint = hint == 'Thời gian du lịch (ngày)' || hint == 'Điểm đến';
    const accentColor = Color(0xFFA15C20);
>>>>>>> 9fb9c5b (Add homepage frontend and after that implementation)
    return Material(
      color: const Color(0xFFF7F3E8),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          // debug print to confirm tap
          // ignore: avoid_print
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
<<<<<<< HEAD
                  color: textColor,
=======
                  color: isDefaultHint ? accentColor : Colors.black,
>>>>>>> 9fb9c5b (Add homepage frontend and after that implementation)
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

// --- Recommended Section (Không thay đổi) ---
class _RecommendedCard extends StatelessWidget {
  final Destination destination;
  final void Function(Destination)? onTap;
  const _RecommendedCard({required this.destination, this.onTap});

  @override
  Widget build(BuildContext context) {
    // removed rating percent display from the card
    return GestureDetector(
      onTap: () {
        if (onTap != null) onTap!(destination);
      },
      child: Container(
        height: 200,
        margin: const EdgeInsets.only(bottom: 20),
<<<<<<< HEAD
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
                  // rating pill removed per request
                ],
              ),
            );
          },
=======
        child: ClipRRect(
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
                top: 15,
                right: 20,
                child: Text(
                  destination.name.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Bangers',
                    fontSize: 30,
                    color: Colors.white,
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
              // rating pill removed per request
            ],
          ),
>>>>>>> 9fb9c5b (Add homepage frontend and after that implementation)
        ),
      ),
    );
  }
}

// --- Calendar Overlay (Không thay đổi) ---
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
<<<<<<< HEAD
            child: CalendarCard(
=======
            child: _CalendarCard(
>>>>>>> 9fb9c5b (Add homepage frontend and after that implementation)
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
<<<<<<< HEAD
=======

class _CalendarCard extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(DateTime) onPageChanged;
  final VoidCallback onClose;

  const _CalendarCard(
      {required this.focusedDay,
        this.rangeStart,
        this.rangeEnd,
        required this.onDaySelected,
        required this.onPageChanged,
        required this.onClose});

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFA15C20);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Chọn ngày',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: focusedDay,
              rangeStartDay: rangeStart,
              rangeEndDay: rangeEnd,
              onDaySelected: onDaySelected,
              onPageChanged: onPageChanged,
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                    color: accentColor.withAlpha((0.5 * 255).toInt()), shape: BoxShape.circle),
                selectedDecoration: BoxDecoration(
                    color: accentColor, shape: BoxShape.circle),
                rangeStartDecoration: BoxDecoration(
                    color: accentColor, shape: BoxShape.circle),
                rangeEndDecoration: BoxDecoration(
                    color: accentColor, shape: BoxShape.circle),
                rangeHighlightColor: accentColor.withAlpha((0.5 * 255).toInt()),
              ),
              headerStyle: const HeaderStyle(
                  formatButtonVisible: false, titleCentered: true),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
              ),
              onPressed: onClose,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Chọn ngày',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------ Widget Modal Search ------------------
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
        final q = _query;
        _results = mockDestinations.where((d) {
          return d.name.toLowerCase().contains(q)
              || d.province.toLowerCase().contains(q)
              || d.location.toLowerCase().contains(q)
              || d.description.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Material(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        onChanged: _onChanged,
                        decoration: InputDecoration(
                          hintText: 'Tìm địa điểm',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF2F2F2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Hủy'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _results.isEmpty
                    ? const Center(child: Text('Không tìm thấy kết quả'))
                    : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemBuilder: (ctx, i) {
                    final d = _results[i];
                    return ListTile(
                      onTap: () => widget.onSelect(d),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          d.imagePath,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(d.name),
                      subtitle: Text(d.province),
                    );
                  },
                  separatorBuilder: (_, __) => const Divider(),
                  itemCount: _results.length,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
>>>>>>> 9fb9c5b (Add homepage frontend and after that implementation)
