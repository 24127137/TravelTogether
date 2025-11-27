import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Cần để lưu trạng thái đã xem
import '../data/mock_destinations.dart';
import '../models/destination.dart';
import '../widgets/destination_search_modal.dart';
import '../widgets/calendar_card.dart';
import 'group_matcing_announcement_screen.dart';
import '../services/user_service.dart'; // Import UserService
import '../services/auth_service.dart'; // Import AuthService

class HomePage extends StatefulWidget {
  final void Function(Destination)? onDestinationTap;
  final VoidCallback? onSettingsTap;
  final void Function(int index)? onTabChangeRequest;
  const HomePage({Key? key, this.onDestinationTap, this.onSettingsTap, this.onTabChangeRequest,}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isCalendarVisible = false;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  DateTime _focusedDay = DateTime.now();

  final UserService _userService = UserService(); // Init Service

  @override
  void initState() {
    super.initState();
    // Tự động kiểm tra xem có cần popup thông báo vào nhóm không
    _checkNewGroupAcceptance();
  }

  // --- LOGIC AUTO POPUP ---
  Future<void> _checkNewGroupAcceptance() async {
    // 1. Kiểm tra token
    final token = await AuthService.getValidAccessToken();
    if (token == null) return;

    // 2. Lấy thông tin user
    final profile = await _userService.getUserProfile();
    if (profile == null) return;

    // 3. Kiểm tra xem có đang ở trong nhóm với vai trò MEMBER không (joined_groups)
    List joined = profile['joined_groups'] ?? [];

    if (joined.isNotEmpty) {
      // User đang ở trong một nhóm
      var group = joined[0]; // Lấy nhóm đầu tiên (theo logic 1 user 1 nhóm)
      String groupName = group['name'] ?? "Nhóm của bạn";
      int groupId = group['group_id'];

      // 4. Kiểm tra SharedPreferences xem đã hiện thông báo cho nhóm này chưa
      final prefs = await SharedPreferences.getInstance();
      String key = 'seen_announcement_group_$groupId';
      bool hasSeen = prefs.getBool(key) ?? false;

      if (!hasSeen) {
        // Nếu CHƯA xem -> Hiện Popup
        if (!mounted) return;

        // Đánh dấu là đã xem ngay để không hiện lại lần sau
        await prefs.setBool(key, true);

        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => GroupMatchingAnnouncementScreen(
            groupName: groupName,
            groupId: groupId.toString(),
            onBack: () => Navigator.of(context).pop(),
          ),
        ));
      }
    }
  }

  // --- LOGIC NÚT LOA (THỦ CÔNG) ---
  // --- LOGIC NÚT LOA (ĐÃ ĐIỀN ĐỦ THAM SỐ) ---
  void _handleAnnouncementTap() async {
    final token = await AuthService.getValidAccessToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Vui lòng đăng nhập'.tr())));
      return;
    }

    final profile = await _userService.getUserProfile();
    if (profile == null) return;

    List joined = profile['joined_groups'] ?? [];

    if (joined.isNotEmpty) {
      // Lấy thông tin nhóm
      var group = joined[0];

      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => GroupMatchingAnnouncementScreen(
          // 1. THAM SỐ BẮT BUỘC (Phải có dòng này mới hết gạch đỏ)
          groupName: group['name'] ?? "Nhóm",

          // 2. Các tham số khác
          groupId: group['group_id'].toString(),

          onBack: () => Navigator.of(context).pop(),

          // 3. Callback chuyển tab chat
          onGoToChat: () {
            Navigator.of(context).pop(); // Đóng popup Announcement trước
            if (widget.onTabChangeRequest != null) {
              widget.onTabChangeRequest!(2); // Yêu cầu MainApp chuyển sang Tab 2 (Messages)
            }
          },
        ),
      ));
    } else {
      // Nếu không có nhóm -> Thông báo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bạn chưa tham gia nhóm nào hoặc là Host.'.tr())),
      );
    }
  }

  // ... (Các hàm lịch và duration giữ nguyên)
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
    final top5Cities = List<Destination>.from(mockDestinations)
      ..sort((a, b) => b.rating.compareTo(a.rating));
    final top5 = top5Cities.take(5).toList();

    return Container(
      color: const Color(0xFFB99668),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned.fill(
              child: Column(
                children: [
                  _TopSection(
                    durationText: _durationText,
                    onDestinationTap: _openDestinationScreen,
                    onDurationTap: _showCalendar,
                    onSettingsTap: widget.onSettingsTap,
                    // Truyền hàm xử lý nút Loa xuống dưới
                    onAnnouncementTap: _handleAnnouncementTap,
                  ),
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
                              ...top5.map((dest) => _RecommendedCard(
                                destination: dest,
                                onTap: widget.onDestinationTap,
                              )).toList(),
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

// --- Top Section Widgets (Đã cập nhật callback) ---
class _TopSection extends StatelessWidget {
  final String durationText;
  final VoidCallback onDestinationTap;
  final VoidCallback onDurationTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback onAnnouncementTap; // Callback mới

  const _TopSection({
    required this.durationText,
    required this.onDestinationTap,
    required this.onDurationTap,
    this.onSettingsTap,
    required this.onAnnouncementTap, // Required
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 20),
      decoration: const BoxDecoration(
          color: Color(0xFFEDE2CC),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          )),
      child: Column(
        children: [
          _CustomAppBar(
            onSettingsTap: onSettingsTap,
            onAnnouncementTap: onAnnouncementTap, // Truyền tiếp
          ),
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
  final VoidCallback onAnnouncementTap; // Callback mới

  const _CustomAppBar({
    this.onSettingsTap,
    required this.onAnnouncementTap,
  });

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
        // NÚT LOA (CAMPAIGN)
        GestureDetector(
          onTap: onAnnouncementTap, // Gọi hàm từ HomePage
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

// ... (Các widget _SelectionButton, _RecommendedCard, _CalendarOverlay giữ nguyên)
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