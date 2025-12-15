import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
<<<<<<< HEAD
import 'package:shared_preferences/shared_preferences.dart'; // Cần để lưu trạng thái đã xem
=======
import 'package:shared_preferences/shared_preferences.dart';
>>>>>>> week10
import '../data/mock_destinations.dart';
import '../models/destination.dart';
import '../widgets/destination_search_modal.dart';
import '../widgets/calendar_card.dart';
import 'group_matcing_announcement_screen.dart';
<<<<<<< HEAD
import '../services/user_service.dart'; // Import UserService
import '../services/auth_service.dart'; // Import AuthService
=======
import '../services/user_service.dart';
import '../services/auth_service.dart';
>>>>>>> week10

class HomePage extends StatefulWidget {
  final void Function(Destination)? onDestinationTap;
  final VoidCallback? onSettingsTap;
  final void Function(int index)? onTabChangeRequest;
<<<<<<< HEAD
<<<<<<< HEAD
  const HomePage({Key? key, this.onDestinationTap, this.onSettingsTap, this.onTabChangeRequest,}) : super(key: key);
=======
=======
>>>>>>> week10
  const HomePage({
    Key? key,
    this.onDestinationTap,
    this.onSettingsTap,
    this.onTabChangeRequest,
  }) : super(key: key);
<<<<<<< HEAD
>>>>>>> 274291d (update)
=======
>>>>>>> week10

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isCalendarVisible = false;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  DateTime _focusedDay = DateTime.now();

<<<<<<< HEAD
  final UserService _userService = UserService(); // Init Service

<<<<<<< HEAD
<<<<<<< HEAD
  String _userName = 'User'; // Mặc định
  String? _userAvatar;
=======
  final UserService _userService = UserService();

  String _userName = 'User';
  String? _userAvatar;
  String? _preferredCity;
>>>>>>> week10

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
<<<<<<< HEAD
=======
  @override
  void initState() {
    super.initState();
>>>>>>> 3ee7efe (done all groupapis)
=======
  @override
  void initState() {
    super.initState();
>>>>>>> 274291d (update)
    // Tự động kiểm tra xem có cần popup thông báo vào nhóm không
    _checkNewGroupAcceptance();
  }

<<<<<<< HEAD
<<<<<<< HEAD
  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Load từ cache trước để hiển thị ngay (tránh UI trống)
    setState(() {
      _userName = prefs.getString('user_firstname') ?? 'User';
      _userAvatar = prefs.getString('user_avatar');
    });

    // 2. Gọi API để lấy dữ liệu mới nhất
=======

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

>>>>>>> week10
    try {
      final token = await AuthService.getValidAccessToken();
      if (token == null) return;

      final profile = await _userService.getUserProfile();
      if (profile == null) return;

<<<<<<< HEAD
      // Lấy fullname từ API: "Nguyễn Văn Toàn" hoặc "Toàn"
      String fullName = profile['fullname']?.toString() ?? 'User';
      String? avatarUrl = profile['avatar_url']?.toString();

      // Tách tên: Lấy từ cuối cùng (tên người Việt)
      // "Nguyễn Văn Toàn" -> "Toàn"
=======
      String fullName = profile['fullname']?.toString() ?? 'User';
      String? avatarUrl = profile['avatar_url']?.toString();
      String? preferredCity = profile['preferred_city']?.toString();
      String? travelDates = profile['travel_dates']?.toString();

>>>>>>> week10
      String firstName = fullName.trim().contains(' ')
          ? fullName.trim().split(' ').last
          : fullName.trim();

<<<<<<< HEAD
      // Lưu cache để lần sau load nhanh
=======
>>>>>>> week10
      await prefs.setString('user_firstname', firstName);
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        await prefs.setString('user_avatar', avatarUrl);
      } else {
        await prefs.remove('user_avatar');
      }

<<<<<<< HEAD
      // Cập nhật UI
=======
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

>>>>>>> week10
      if (mounted) {
        setState(() {
          _userName = firstName;
          _userAvatar = avatarUrl;
<<<<<<< HEAD
=======
          _preferredCity = preferredCity;

          if (travelDates != null && travelDates.isNotEmpty) {
            _parseTravelDates(travelDates);
          } else {
            _rangeStart = null;
            _rangeEnd = null;
          }
>>>>>>> week10
        });
      }
    } catch (e) {
      print('❌ Lỗi load user info: $e');
    }
  }

<<<<<<< HEAD
  // === THÊM MỚI: Hàm refresh cho pull-to-refresh ===
  Future<void> _handleRefresh() async {
    await _loadUserInfo();
    // Có thể thêm các refresh khác nếu cần (ví dụ: refresh danh sách điểm đến)
    await Future.delayed(const Duration(milliseconds: 500)); // Thêm delay nhỏ cho mượt
  }

=======
>>>>>>> 3ee7efe (done all groupapis)
=======
>>>>>>> 274291d (update)
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
<<<<<<< HEAD
  // --- LOGIC NÚT LOA (ĐÃ ĐIỀN ĐỦ THAM SỐ) ---
=======
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
>>>>>>> week10
  void _handleAnnouncementTap() async {
    final token = await AuthService.getValidAccessToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Vui lòng đăng nhập'.tr())));
<<<<<<< HEAD
=======
  void _handleAnnouncementTap() async {
    final token = await AuthService.getValidAccessToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng đăng nhập'.tr())),
      );
>>>>>>> 274291d (update)
=======
>>>>>>> week10
      return;
    }

    final profile = await _userService.getUserProfile();
    if (profile == null) return;

    List joined = profile['joined_groups'] ?? [];

    if (joined.isNotEmpty) {
<<<<<<< HEAD
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
=======
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
>>>>>>> week10
            }
          },
        ),
      ));
    } else {
<<<<<<< HEAD
      // Nếu không có nhóm -> Thông báo
=======
>>>>>>> week10
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bạn chưa tham gia nhóm nào hoặc là Host.'.tr())),
      );
    }
  }

<<<<<<< HEAD
<<<<<<< HEAD
  // ... (Các hàm lịch và duration giữ nguyên)
=======
>>>>>>> 274291d (update)
  String get _durationText {
    if (_rangeStart == null) return 'travel_time'.tr();
    final format = DateFormat('dd/MM');
    if (_rangeEnd == null) return format.format(_rangeStart!);
    return '${format.format(_rangeStart!)} - ${format.format(_rangeEnd!)}';
  }

  void _showCalendar() => setState(() => _isCalendarVisible = true);
  void _hideCalendar() => setState(() => _isCalendarVisible = false);
=======
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
>>>>>>> week10

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      if (_rangeStart == null || _rangeEnd != null) {
        _rangeStart = selectedDay;
<<<<<<< HEAD
=======
        _rangeEnd = null;
>>>>>>> week10
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
<<<<<<< HEAD
=======
                    destinationText: _destinationText,
>>>>>>> week10
                    durationText: _durationText,
                    onDestinationTap: _openDestinationScreen,
                    onDurationTap: _showCalendar,
                    onSettingsTap: widget.onSettingsTap,
<<<<<<< HEAD
                    // Truyền hàm xử lý nút Loa xuống dưới
                    onAnnouncementTap: _handleAnnouncementTap,
<<<<<<< HEAD
<<<<<<< HEAD
=======
                    onAnnouncementTap: _handleAnnouncementTap,
>>>>>>> week10
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
<<<<<<< HEAD
=======
                  ),
                  Expanded(
=======
                  ),
                  Expanded(
>>>>>>> 274291d (update)
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
<<<<<<< HEAD
>>>>>>> 3ee7efe (done all groupapis)
=======
>>>>>>> 274291d (update)
=======
>>>>>>> week10
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

<<<<<<< HEAD
// --- Top Section Widgets (Đã cập nhật callback) ---
class _TopSection extends StatelessWidget {
=======
// === CÁC WIDGET PHỤ (Giữ nguyên như cũ) ===

class _TopSection extends StatelessWidget {
  final String destinationText;
>>>>>>> week10
  final String durationText;
  final VoidCallback onDestinationTap;
  final VoidCallback onDurationTap;
  final VoidCallback? onSettingsTap;
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
  final VoidCallback onAnnouncementTap;
  final String userName;
  final String? avatarUrl;
=======
  final VoidCallback onAnnouncementTap; // Callback mới
>>>>>>> 3ee7efe (done all groupapis)
=======
  final VoidCallback onAnnouncementTap; // Callback mới
>>>>>>> 274291d (update)

  const _TopSection({
=======
  final VoidCallback onAnnouncementTap;
  final String userName;
  final String? avatarUrl;

  const _TopSection({
    required this.destinationText,
>>>>>>> week10
    required this.durationText,
    required this.onDestinationTap,
    required this.onDurationTap,
    this.onSettingsTap,
<<<<<<< HEAD
    required this.onAnnouncementTap, // Required
<<<<<<< HEAD
<<<<<<< HEAD
    required this.userName,
    this.avatarUrl,
=======
>>>>>>> 3ee7efe (done all groupapis)
=======
>>>>>>> 274291d (update)
=======
    required this.onAnnouncementTap,
    required this.userName,
    this.avatarUrl,
>>>>>>> week10
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
<<<<<<< HEAD
            onAnnouncementTap: onAnnouncementTap, // Truyền tiếp
<<<<<<< HEAD
<<<<<<< HEAD
            userName: userName,
            avatarUrl: avatarUrl,
=======
>>>>>>> 3ee7efe (done all groupapis)
=======
>>>>>>> 274291d (update)
          ),
          const SizedBox(height: 24),
          _SelectionButton(
            hint: 'destination'.tr(),
=======
            onAnnouncementTap: onAnnouncementTap,
            userName: userName,
            avatarUrl: avatarUrl,
          ),
          const SizedBox(height: 24),
          _SelectionButton(
            hint: destinationText,
>>>>>>> week10
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
<<<<<<< HEAD
  final VoidCallback onAnnouncementTap; // Callback mới
<<<<<<< HEAD
<<<<<<< HEAD
  final String userName;      // Thêm
  final String? avatarUrl;
=======
>>>>>>> 3ee7efe (done all groupapis)
=======
>>>>>>> 274291d (update)
=======
  final VoidCallback onAnnouncementTap;
  final String userName;
  final String? avatarUrl;
>>>>>>> week10

  const _CustomAppBar({
    this.onSettingsTap,
    required this.onAnnouncementTap,
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
    required this.userName,   // Thêm
    this.avatarUrl,
=======
>>>>>>> 3ee7efe (done all groupapis)
=======
>>>>>>> 274291d (update)
=======
    required this.userName,
    this.avatarUrl,
>>>>>>> week10
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
<<<<<<< HEAD
        // AVATAR ĐỘNG
=======
>>>>>>> week10
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
<<<<<<< HEAD
<<<<<<< HEAD
          child: CircleAvatar(
=======
          child: const CircleAvatar(
            backgroundImage: AssetImage('assets/images/avatar.jpg'),
>>>>>>> 3ee7efe (done all groupapis)
            radius: 18,
            backgroundColor: Colors.grey[300], // Màu nền khi chưa có ảnh
            backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                ? NetworkImage(avatarUrl!) as ImageProvider
                : const AssetImage('assets/images/avatar.jpg'), // Ảnh mặc định
          ),
        ),
        const SizedBox(width: 12),

        // TÊN ĐỘNG
        Text(
          'hello_user'.tr(args: [userName]), // Dùng tham số dịch: "Xin chào, {name}"
=======
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
>>>>>>> week10
          style: const TextStyle(
              fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
<<<<<<< HEAD
        // NÚT LOA (CAMPAIGN)
        GestureDetector(
          onTap: onAnnouncementTap, // Gọi hàm từ HomePage
=======
        GestureDetector(
          onTap: onAnnouncementTap,
>>>>>>> week10
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

<<<<<<< HEAD
// ... (Các widget _SelectionButton, _RecommendedCard, _CalendarOverlay giữ nguyên)
=======
>>>>>>> week10
class _SelectionButton extends StatelessWidget {
  final String hint;
  final IconData icon;
  final VoidCallback onTap;

  const _SelectionButton({required this.hint, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFA15C20);
<<<<<<< HEAD

    final isDateHint = RegExp(r'\d{2}/\d{2}').hasMatch(hint);
    final isDefaultHint = hint == 'destination'.tr() || hint == 'travel_time'.tr();

    final textColor = isDefaultHint
        ? accentColor
        : (isDateHint ? accentColor : Colors.black);
=======
    final textColor = accentColor;
    final fontWeight = FontWeight.w500;
>>>>>>> week10

    return Material(
      color: const Color(0xFFF7F3E8),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
<<<<<<< HEAD
        onTap: () {
          print('SelectionButton tapped: $hint');
          onTap();
        },
=======
        onTap: onTap,
>>>>>>> week10
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
<<<<<<< HEAD
                  fontWeight: isDefaultHint ? FontWeight.w400 : FontWeight.w500,
=======
                  fontWeight: fontWeight,
>>>>>>> week10
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
<<<<<<< HEAD
              focusedDay: focusedDay,
              rangeStart: rangeStart,
              rangeEnd: rangeEnd,
              onDaySelected: onDaySelected,
              onPageChanged: onPageChanged,
              onClose: onClose,
=======
                focusedDay: focusedDay,
                initialRangeStart: rangeStart,
                initialRangeEnd: rangeEnd,
                onClose: onClose,
                accentColor: const Color(0xFFB99668)
>>>>>>> week10
            ),
          ),
        ),
      ),
    );
  }
}