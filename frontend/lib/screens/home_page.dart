import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/mock_destinations.dart';
import '../models/destination.dart';
import '../widgets/destination_search_modal.dart';
import '../widgets/calendar_card.dart';
import 'group_matcing_announcement_screen.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';

class HomePage extends StatefulWidget {
  final void Function(Destination)? onDestinationTap;
  final VoidCallback? onSettingsTap;
  final void Function(int index)? onTabChangeRequest;
  const HomePage({
    Key? key,
    this.onDestinationTap,
    this.onSettingsTap,
    this.onTabChangeRequest,
  }) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isCalendarVisible = false;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  DateTime _focusedDay = DateTime.now();

  final UserService _userService = UserService();

  String _userName = 'User';
  String? _userAvatar;
  String? _preferredCity;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();

    // Gọi hàm kiểm tra nhóm mới ngay khi widget được build xong
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNewGroupAcceptance();
    });
  }

  // === [UPDATED] LOGIC KIỂM TRA NHÓM MỚI ĐỂ HIỆN POPUP ===
  Future<void> _checkNewGroupAcceptance() async {
    try {
      final token = await AuthService.getValidAccessToken();
      if (token == null) return;

      // 1. Lấy thông tin user mới nhất từ API
      final profile = await _userService.getUserProfile();
      if (profile == null) return;

      final List<dynamic> currentJoinedGroups = profile['joined_groups'] ?? [];

      // 2. Lấy danh sách ID nhóm đã lưu trong Cache (Lần mở app trước)
      final prefs = await SharedPreferences.getInstance();
      final List<String> cachedIds = prefs.getStringList('joined_group_ids_cache') ?? [];

      // 3. Tìm nhóm MỚI (Có trong Current nhưng KHÔNG có trong Cache)
      for (var group in currentJoinedGroups) {
        final String groupId = (group['group_id'] ?? group['id']).toString();
        final String groupName = group['name'] ?? 'Nhóm mới';

        // Nếu ID này chưa từng thấy trong cache -> Đây là nhóm mới được duyệt!
        if (!cachedIds.contains(groupId)) {
          if (!mounted) return;

          // 4. Hiện Popup "Vào Thôi!"
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => GroupMatchingAnnouncementScreen(
              groupName: groupName,
              groupId: groupId,
              onBack: () => Navigator.of(context).pop(),
              onGoToChat: () {
                Navigator.of(context).pop(); // Tắt popup
                // Chuyển sang tab Chat (Index 2)
                if (widget.onTabChangeRequest != null) {
                  widget.onTabChangeRequest!(2);
                }
              },
            ),
          ));

          // Chỉ hiện 1 popup mỗi lần để tránh spam
          break;
        }
      }

      // 5. Cập nhật lại Cache mới nhất cho lần sau
      // (Lưu tất cả ID nhóm hiện tại vào máy)
      List<String> newIds = currentJoinedGroups
          .map((g) => (g['group_id'] ?? g['id']).toString())
          .toList()
          .cast<String>();

      await prefs.setStringList('joined_group_ids_cache', newIds);

    } catch (e) {
      print('❌ Lỗi check nhóm mới: $e');
    }
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Load từ cache trước (để hiển thị ngay)
    final cachedFirstName = prefs.getString('user_firstname');
    final cachedAvatar = prefs.getString('user_avatar');
    final cachedCity = prefs.getString('user_preferred_city');
    final cachedDates = prefs.getString('user_travel_dates');

    if (cachedFirstName != null) {
      setState(() {
        _userName = cachedFirstName;
        _userAvatar = cachedAvatar;
        _preferredCity = cachedCity;

        if (cachedDates != null && cachedDates.isNotEmpty) {
          _parseTravelDates(cachedDates);
        }
      });
    }

    try {
      final token = await AuthService.getValidAccessToken();
      if (token == null) return;

      final profile = await _userService.getUserProfile();
      if (profile == null) return;

      String fullName = profile['fullname']?.toString() ?? 'User';
      String? avatarUrl = profile['avatar_url']?.toString();
      String? preferredCity = profile['preferred_city']?.toString();
      String? travelDates = profile['travel_dates']?.toString();

      String firstName = fullName.trim().contains(' ')
          ? fullName.trim().split(' ').last
          : fullName.trim();

      await prefs.setString('user_firstname', firstName);
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        await prefs.setString('user_avatar', avatarUrl);
      } else {
        await prefs.remove('user_avatar');
      }

      if (preferredCity != null && preferredCity.isNotEmpty) {
        await prefs.setString('user_preferred_city', preferredCity);
      } else {
        await prefs.remove('user_preferred_city');
      }

      if (travelDates != null && travelDates.isNotEmpty) {
        await prefs.setString('user_travel_dates', travelDates);
      } else {
        await prefs.remove('user_travel_dates');
      }

      if (mounted) {
        setState(() {
          _userName = firstName;
          _userAvatar = avatarUrl;
          _preferredCity = preferredCity;

          if (travelDates != null && travelDates.isNotEmpty) {
            _parseTravelDates(travelDates);
          } else {
            _rangeStart = null;
            _rangeEnd = null;
          }
        });
      }
    } catch (e) {
      print('❌ Lỗi load user info: $e');
    }
  }

  void _parseTravelDates(String dateRange) {
    try {
      if (dateRange.contains('lower') && dateRange.contains('upper')) {
        final cleaned = dateRange
            .replaceAll('{', '')
            .replaceAll('}', '')
            .replaceAll(' ', '');

        String? lower;
        String? upper;

        final parts = cleaned.split(',');
        for (var part in parts) {
          if (part.startsWith('lower:')) {
            lower = part.replaceAll('lower:', '');
          } else if (part.startsWith('upper:')) {
            upper = part.replaceAll('upper:', '');
          }
        }

        if (lower != null && upper != null) {
          _rangeStart = DateTime.parse(lower);
          _rangeEnd = DateTime.parse(upper);
          return;
        }
      }

      if (dateRange.startsWith('[') && dateRange.endsWith(')')) {
        final cleaned = dateRange.replaceAll('[', '').replaceAll(')', '');
        final parts = cleaned.split(',');

        if (parts.length == 2) {
          _rangeStart = DateTime.parse(parts[0].trim());
          _rangeEnd = DateTime.parse(parts[1].trim());
          return;
        }
      }

      _rangeStart = null;
      _rangeEnd = null;

    } catch (e) {
      print('❌ Lỗi parse travel_dates: $e');
      _rangeStart = null;
      _rangeEnd = null;
    }
  }

  Future<void> _handleRefresh() async {
    await _loadUserInfo();
    // Check lại popup khi refresh
    await _checkNewGroupAcceptance();
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // Hàm xử lý nút cái loa (Thông báo thủ công)
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
      var group = joined[0]; // Mở nhóm đầu tiên hoặc logic khác tùy bạn

      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => GroupMatchingAnnouncementScreen(
          groupName: group['name'] ?? "Nhóm",
          groupId: group['group_id'].toString(),
          onBack: () => Navigator.of(context).pop(),
          onGoToChat: () {
            Navigator.of(context).pop();
            if (widget.onTabChangeRequest != null) {
              widget.onTabChangeRequest!(2);
            }
          },
        ),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bạn chưa tham gia nhóm nào hoặc là Host.'.tr())),
      );
    }
  }

  String get _destinationText {
    if (_preferredCity != null && _preferredCity!.isNotEmpty) {
      return _preferredCity!;
    }
    return 'destination'.tr();
  }

  String get _durationText {
    if (_rangeStart != null && _rangeEnd != null) {
      final format = DateFormat('dd/MM');
      return '${format.format(_rangeStart!)} - ${format.format(_rangeEnd!)}';
    }

    if (_rangeStart != null) {
      final format = DateFormat('dd/MM');
      return format.format(_rangeStart!);
    }
    return 'travel_time'.tr();
  }

  void _showCalendar() => setState(() => _isCalendarVisible = true);

  void _hideCalendar() {
    setState(() => _isCalendarVisible = false);
    _loadUserInfo();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      if (_rangeStart == null || _rangeEnd != null) {
        _rangeStart = selectedDay;
        _rangeEnd = null;
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
                    destinationText: _destinationText,
                    durationText: _durationText,
                    onDestinationTap: _openDestinationScreen,
                    onDurationTap: _showCalendar,
                    onSettingsTap: widget.onSettingsTap,
                    onAnnouncementTap: _handleAnnouncementTap,
                    userName: _userName,
                    avatarUrl: _userAvatar,
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      color: const Color(0xFF8A724C),
                      backgroundColor: Colors.white,
                      onRefresh: _handleRefresh,
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

// === CÁC WIDGET PHỤ (Giữ nguyên như cũ) ===

class _TopSection extends StatelessWidget {
  final String destinationText;
  final String durationText;
  final VoidCallback onDestinationTap;
  final VoidCallback onDurationTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback onAnnouncementTap;
  final String userName;
  final String? avatarUrl;

  const _TopSection({
    required this.destinationText,
    required this.durationText,
    required this.onDestinationTap,
    required this.onDurationTap,
    this.onSettingsTap,
    required this.onAnnouncementTap,
    required this.userName,
    this.avatarUrl,
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
            onAnnouncementTap: onAnnouncementTap,
            userName: userName,
            avatarUrl: avatarUrl,
          ),
          const SizedBox(height: 24),
          _SelectionButton(
            hint: destinationText,
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
  final VoidCallback onAnnouncementTap;
  final String userName;
  final String? avatarUrl;

  const _CustomAppBar({
    this.onSettingsTap,
    required this.onAnnouncementTap,
    required this.userName,
    this.avatarUrl,
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
          child: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey[300],
            backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                ? NetworkImage(avatarUrl!) as ImageProvider
                : const AssetImage('assets/images/avatar.jpg'),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'hello_user'.tr(args: [userName]),
          style: const TextStyle(
              fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onAnnouncementTap,
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
    final textColor = accentColor;
    final fontWeight = FontWeight.w500;

    return Material(
      color: const Color(0xFFF7F3E8),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
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
                  fontWeight: fontWeight,
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
                initialRangeStart: rangeStart,
                initialRangeEnd: rangeEnd,
                onClose: onClose,
                accentColor: const Color(0xFFB99668)
            ),
          ),
        ),
      ),
    );
  }
}