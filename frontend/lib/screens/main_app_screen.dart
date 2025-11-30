/// File: main_app_screen.dart
/// Mô tả: Widget container chính quản lý các tab và bottom bar, giao diện tiếng Việt.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http; // THÊM MỚI
import 'dart:convert'; // THÊM MỚI
import 'home_page.dart';
import 'messages_screen.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/notification_permission_dialog.dart';
import '../services/background_notification_service.dart';
import '../services/notification_service.dart'; // Import service để xử lý badge
import '../services/auth_service.dart'; // THÊM MỚI: Import auth service
import '../config/api_config.dart'; // THÊM MỚI: Import API config
import '../models/destination.dart';
import 'destination_detail_screen.dart';
import 'destination_explore_screen.dart';
import 'before_group_screen.dart';
import 'group_creating.dart';
import 'destination_search_screen.dart';
import 'settings_screen.dart';
import 'notification_screen.dart';
import 'profile.dart';
import 'join_group_screen.dart';
import 'group_state_screen.dart';
import 'travel_plan_screen.dart';
import 'personal_section.dart';

class MainAppScreen extends StatefulWidget {
  final int initialIndex;
  final String accessToken;

  const MainAppScreen({
    Key? key,
    this.initialIndex = 0,
    required this.accessToken,
  }) : super(key: key);

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  late int _selectedIndex;
  Destination? _selectedDestination;
  bool _showDetail = false;
  bool _showExplore = false;
  bool _showBeforeGroup = false;
  bool _showGroupCreating = false;
  bool _showSettings = false;
  bool _showProfile = false;
  bool _showJoinGroup = false;
  bool _showGroupState = false;
  bool _showTravelPlan = false;
  String? _groupDestinationName;

  // === THÊM MỚI: Loading state cho pre-load ===
  bool _isPreLoading = false;

  // === THÊM MỚI: Cache profile data để Settings/Profile load nhanh ===
  Map<String, dynamic>? _cachedProfileData;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _startBackgroundNotificationService();
    _requestNotificationPermission();
    _preloadProfileData(); // === THÊM MỚI: Pre-load data ngay khi app start ===
  }

  // === THÊM MỚI: Pre-load profile data ngay từ đầu ===
  Future<void> _preloadProfileData() async {
    try {
      final token = await AuthService.getValidAccessToken();
      if (token == null) return;

      final url = ApiConfig.getUri(ApiConfig.userProfile);
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        _cachedProfileData = jsonDecode(utf8.decode(response.bodyBytes));
        debugPrint('✅ Profile data pre-loaded successfully');
      } else {
        debugPrint('⚠️ Error pre-loading profile data: Status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ Error pre-loading profile data: $e');
    }
  }

  Future<void> _startBackgroundNotificationService() async {
    try {
      await BackgroundNotificationService().start();
      debugPrint('✅ Background notification service started successfully');
    } catch (e) {
      debugPrint('❌ Error starting background notification service: $e');
    }
  }

  Future<void> _requestNotificationPermission() async {
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;

    final hasPermission = await NotificationService().checkPermission();

    if (!hasPermission) {
      final granted = await NotificationPermissionDialog.show(context);
      if (granted) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('notification_permission_asked', true);
      }
    } else {
      debugPrint('✅ Notification permission already granted, skip dialog');
    }
  }

  void _onItemTapped(int index) {
    // === THÊM MỚI LOGIC BADGE ===
    // Nếu người dùng chọn tab Notification (index == 1)
    // Gọi lệnh xóa badge ngay lập tức để UI cập nhật (mất chấm đỏ)
    if (index == 1) {
      NotificationService().clearBadge();
    }
    // ============================

    setState(() {
      _selectedIndex = index;
      _showDetail = false;
      _showExplore = false;
      _showBeforeGroup = false;
      _showGroupCreating = false;
      _showSettings = false;
      _showProfile = false;
      _showJoinGroup = false;
      _showGroupState = false;
      _showTravelPlan = false;
    });
  }

  void _openDestinationDetail(Destination dest) {
    setState(() {
      _selectedDestination = dest;
      _showDetail = true;
      _showExplore = false;
      _showBeforeGroup = false;
      _showGroupCreating = false;
      _showSettings = false;
      _selectedIndex = -1;
    });
  }

  void _openDestinationExplore() {
    setState(() {
      _showDetail = false;
      _showExplore = true;
      _showBeforeGroup = false;
      _showGroupCreating = false;
      _showSettings = false;
      _selectedIndex = -1;
    });
  }

  void _backToDestinationDetail() {
    setState(() {
      _showExplore = false;
      _showDetail = true;
      _showBeforeGroup = false;
      _showGroupCreating = false;
      _showSettings = false;
      _selectedIndex = -1;
    });
  }

  void _openBeforeGroup() {
    setState(() {
      _showDetail = false;
      _showExplore = false;
      _showBeforeGroup = true;
      _showGroupCreating = false;
      _showSettings = false;
      _selectedIndex = -1;
    });
  }

  void _openGroupCreating(String? destinationName) {
    setState(() {
      _showDetail = false;
      _showExplore = false;
      _showBeforeGroup = false;
      _showGroupCreating = true;
      _showSettings = false;
      _showProfile = false;
      _groupDestinationName = destinationName;
      _selectedIndex = -1;
    });
  }

  // === SỬA MỚI: Pre-load data THỰC SỰ trước khi mở Settings ===
  Future<void> _openSettings() async {
    // Hiện loading ngay lập tức
    setState(() => _isPreLoading = true);

    // Load data nếu chưa có cache hoặc cache cũ
    if (_cachedProfileData == null) {
      await _preloadProfileData();
    }

    // Delay nhỏ để đảm bảo loading animation hiện (tối thiểu 400ms)
    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;

    // Ẩn loading và hiện Settings với data đã sẵn sàng
    setState(() {
      _isPreLoading = false;
      _showDetail = false;
      _showExplore = false;
      _showBeforeGroup = false;
      _showGroupCreating = false;
      _showSettings = true;
      _showProfile = false;
      _selectedIndex = -1;
    });
  }

  // === THÊM MỚI: Callback khi quay từ Profile về Settings ===
  Future<void> _onProfileBack() async {
    // Refresh cache trước khi quay về Settings
    await _preloadProfileData();
    _openSettings();
  }

  void _openGroupState() {
    setState(() {
      _showDetail = false;
      _showExplore = false;
      _showBeforeGroup = false;
      _showGroupCreating = false;
      _showSettings = false;
      _showProfile = false;
      _showJoinGroup = false;
      _showGroupState = true;
      _selectedIndex = -1;
    });
  }

  void _openTravelPlan() {
    setState(() {
      _showDetail = false;
      _showExplore = false;
      _showBeforeGroup = false;
      _showGroupCreating = false;
      _showSettings = false;
      _showProfile = false;
      _showJoinGroup = false;
      _showGroupState = false;
      _showTravelPlan = true;
      _selectedIndex = -1;
    });
  }

  void _closeAllScreens() {
    setState(() {
      _showDetail = false;
      _showExplore = false;
      _showBeforeGroup = false;
      _showGroupCreating = false;
      _showSettings = false;
      _showProfile = false;
      _showJoinGroup = false;
      _showGroupState = false;
      _showTravelPlan = false;
      _selectedIndex = 0;
    });

    // === THÊM MỚI: Update cache trong HomePage sau khi đóng Settings ===
    _updateHomePageCache();
  }

  // === THÊM MỚI: Update cache để HomePage hiển thị ngay data mới ===
  Future<void> _updateHomePageCache() async {
    if (_cachedProfileData == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Lấy fullname và tách tên
      String fullName = _cachedProfileData!['fullname']?.toString() ?? 'User';
      String firstName = fullName.trim().contains(' ')
          ? fullName.trim().split(' ').last
          : fullName.trim();

      String? avatarUrl = _cachedProfileData!['avatar_url']?.toString();

      // Update cache trong SharedPreferences
      await prefs.setString('user_firstname', firstName);
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        await prefs.setString('user_avatar', avatarUrl);
      } else {
        await prefs.remove('user_avatar');
      }

      debugPrint('✅ HomePage cache updated: $firstName, $avatarUrl');
    } catch (e) {
      debugPrint('❌ Error updating HomePage cache: $e');
    }
  }

  // === SỬA MỚI: Pre-load data THỰC SỰ trước khi mở Profile ===
  Future<void> _openProfile() async {
    // Hiện loading ngay lập tức
    setState(() => _isPreLoading = true);

    // Load data nếu chưa có cache hoặc cache cũ
    if (_cachedProfileData == null) {
      await _preloadProfileData();
    }

    // Delay nhỏ để đảm bảo loading animation hiện (tối thiểu 400ms)
    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;

    // Ẩn loading và hiện Profile với data đã sẵn sàng
    setState(() {
      _isPreLoading = false;
      _showDetail = false;
      _showExplore = false;
      _showBeforeGroup = false;
      _showGroupCreating = false;
      _showSettings = false;
      _showProfile = true;
      _selectedIndex = -1;
    });
  }

  void _openJoinGroup() {
    setState(() {
      _showDetail = false;
      _showExplore = false;
      _showBeforeGroup = false;
      _showGroupCreating = false;
      _showSettings = false;
      _showProfile = false;
      _showJoinGroup = true;
      _selectedIndex = -1;
    });
  }

  void _openDestinationSearchScreen() {
    if (_selectedDestination != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              DestinationSearchScreen(cityId: _selectedDestination!.cityId),
        ),
      );
    }
  }

  Future<bool> _handleBackButton() async {
    if (_showSettings || _showDetail || _showExplore || _showBeforeGroup ||
        _showGroupCreating || _showProfile || _showGroupState || _showTravelPlan || _showJoinGroup) {

      if (_showJoinGroup) {
        setState(() {
          _showJoinGroup = false;
          _showBeforeGroup = true;
        });
        return false;
      }

      if (_showGroupState) {
        setState(() {
          _showGroupState = false;
          _selectedIndex = 3;
        });
        return false;
      }

      if (_showTravelPlan) {
        setState(() {
          _showTravelPlan = false;
          _selectedIndex = 3;
        });
        return false;
      }

      if (_showProfile) {
        _openSettings();
        return false;
      }

      if (_showGroupCreating) {
        _openBeforeGroup();
        return false;
      }

      _closeAllScreens();
      return false;
    }

    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
      return false;
    }

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text('exit_app'.tr()),
            content: Text('exit_app_confirmation'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('cancel'.tr()),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('exit'.tr()),
              ),
            ],
          ),
    );

    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    Widget mainContent;

    if (_showTravelPlan) {
      mainContent = TravelPlanScreen(
        onBack: () {
          setState(() {
            _showTravelPlan = false;
            _selectedIndex = 3;
          });
        },
      );
    } else if (_showGroupState) {
      mainContent = GroupStateScreen(
        onBack: () {
          setState(() {
            _showGroupState = false;
            _selectedIndex = 3;
          });
        },
      );
    } else if (_showJoinGroup) {
      mainContent = JoinGroupScreen(
        onBack: () {
          setState(() {
            _showJoinGroup = false;
            _showBeforeGroup = true;
          });
        },
      );
    } else if (_showProfile) {
      mainContent = ProfilePage(
        onBack: _onProfileBack, // === SỬA: Dùng callback đặc biệt để refresh cache ===
      );
    } else if (_showSettings) {
      mainContent = SettingsScreen(
        onBack: _closeAllScreens,
        onProfileTap: _openProfile,
      );
    } else if (_showGroupCreating) {
      mainContent = GroupCreatingScreen(
        destinationName: _groupDestinationName,
        onBack: _openBeforeGroup,
      );
    } else if (_showBeforeGroup) {
      mainContent = BeforeGroup(
        onBack: _openDestinationExplore,
        onCreateGroup: _openGroupCreating,
        onJoinGroup: _openJoinGroup,
      );
    } else if (_showDetail && _selectedDestination != null) {
      mainContent = DestinationDetailScreen(
        destination: _selectedDestination,
        onBack: _closeAllScreens,
        onContinue: _openDestinationExplore,
      );
    } else if (_showExplore && _selectedDestination != null) {
      mainContent = DestinationExploreScreen(
        cityId: _selectedDestination!.cityId,
        currentIndex: _selectedIndex,
        onTabChange: _onItemTapped,
        onBack: _backToDestinationDetail,
        onBeforeGroup: _openBeforeGroup,
        onSearchPlace: _openDestinationSearchScreen,
      );
    } else {
      final List<Widget> _screens = [
        HomePage(
          onDestinationTap: _openDestinationDetail,
          onSettingsTap: _openSettings,
          onTabChangeRequest: (index) {
            _onItemTapped(index);
          },
        ),
        NotificationScreen(),
        MessagesScreen(accessToken: widget.accessToken),
        PersonalSection(
          onGroupStateTap: _openGroupState,
          onTravelPlanTap: _openTravelPlan,
        ),
      ];
      mainContent = IndexedStack(
        index: _selectedIndex,
        children: _screens,
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (!didPop) {
          final shouldPop = await _handleBackButton();
          if (shouldPop && mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        extendBody: true,
        body: Stack(
          children: [
            mainContent,
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: CustomBottomNavBar(
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
              ),
            ),
            // === THÊM MỚI: Loading overlay khi pre-load data ===
            if (_isPreLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB99668)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}