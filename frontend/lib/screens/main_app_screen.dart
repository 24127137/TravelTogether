/// File: main_app_screen.dart
/// Mô tả: Widget container chính quản lý các tab và bottom bar, giao diện tiếng Việt.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http; // Import http
import 'dart:convert'; // Import convert

import 'home_page.dart';
import 'messages_screen.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/notification_permission_dialog.dart';
import '../services/background_notification_service.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart'; // Import UserService
import '../services/auth_service.dart'; // Import AuthService
import '../config/api_config.dart'; // Import ApiConfig

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

  // Các biến quản lý trạng thái màn hình con
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

  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _startBackgroundNotificationService();
    _requestNotificationPermission();

    // === THÊM MỚI: KIỂM TRA DỮ LIỆU ĐỂ HIỆN DOT CAM ===
    _checkUnreadData();
  }

  // Hàm kiểm tra tin nhắn chưa đọc và yêu cầu pending
  Future<void> _checkUnreadData() async {
    try {
      final token = await AuthService.getValidAccessToken();
      if (token == null) return;

      bool hasUnread = false;

      // 1. Kiểm tra yêu cầu gia nhập nhóm (Group Requests)
      final profile = await _userService.getUserProfile();
      if (profile != null) {
        final List ownedGroups = profile['owned_groups'] ?? [];
        if (ownedGroups.isNotEmpty) {
          final requestUrl = ApiConfig.getUri(ApiConfig.groupManageRequests);
          final response = await http.get(
            requestUrl,
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          );

          if (response.statusCode == 200) {
            final List<dynamic> requests = jsonDecode(utf8.decode(response.bodyBytes));
            // Nếu có bất kỳ request nào -> Bật dot
            if (requests.isNotEmpty) {
              hasUnread = true;
            }
          }
        }
      }

      // 2. Kiểm tra tin nhắn chưa đọc (Chat)
      // (Logic đơn giản: Nếu có tin nhắn mới hơn tin nhắn cuối cùng đã xem)
      if (!hasUnread) { // Nếu đã true ở trên thì không cần check tiếp để tối ưu
        try {
          final url = ApiConfig.getUri(ApiConfig.chatHistory);
          final response = await http.get(
            url,
            headers: {"Authorization": "Bearer $token"},
          );
          if (response.statusCode == 200) {
            final List<dynamic> messages = jsonDecode(utf8.decode(response.bodyBytes));
            final prefs = await SharedPreferences.getInstance();
            final currentUserId = prefs.getString('user_id');
            final lastSeenId = prefs.getString('last_seen_message_id');

            if (messages.isNotEmpty) {
              final lastMsg = messages.last;
              // Nếu tin nhắn cuối không phải của mình VÀ khác với lastSeenId
              if (lastMsg['sender_id'].toString() != currentUserId &&
                  lastMsg['id'].toString() != lastSeenId) {
                hasUnread = true;
              }
            }
          }
        } catch (_) {}
      }

      // 3. Cập nhật trạng thái Badge
      if (hasUnread) {
        NotificationService().showBadgeNotifier.value = true;
      }

    } catch (e) {
      debugPrint('Error checking unread data: $e');
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
    }
  }

  void _onItemTapped(int index) {
    // Nếu chọn tab Notification (index 1), xóa badge
    if (index == 1) {
      NotificationService().clearBadge();
    }

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

  // ... (Giữ nguyên toàn bộ các hàm _openDestinationDetail, _openDestinationExplore... cho đến hết file)
  // Chỉ copy phần logic _checkUnreadData và initState ở trên là quan trọng nhất.
  // Các phần dưới đây là code điều hướng cũ của bạn, không thay đổi gì.

  void _openDestinationDetail(Destination dest) {
    setState(() {
      _selectedDestination = dest;
      _showDetail = true; _showExplore = false; _showBeforeGroup = false;
      _showGroupCreating = false; _showSettings = false; _selectedIndex = -1;
    });
  }

  void _openDestinationExplore() {
    setState(() {
      _showDetail = false; _showExplore = true; _showBeforeGroup = false;
      _showGroupCreating = false; _showSettings = false; _selectedIndex = -1;
    });
  }

  void _backToDestinationDetail() {
    setState(() {
      _showExplore = false; _showDetail = true; _showBeforeGroup = false;
      _showGroupCreating = false; _showSettings = false; _selectedIndex = -1;
    });
  }

  void _openBeforeGroup() {
    setState(() {
      _showDetail = false; _showExplore = false; _showBeforeGroup = true;
      _showGroupCreating = false; _showSettings = false; _selectedIndex = -1;
    });
  }

  void _openGroupCreating(String? destinationName) {
    setState(() {
      _showDetail = false; _showExplore = false; _showBeforeGroup = false;
      _showGroupCreating = true; _showSettings = false; _showProfile = false;
      _groupDestinationName = destinationName; _selectedIndex = -1;
    });
  }

  void _closeAllScreens() {
    setState(() {
      _showDetail = false; _showExplore = false; _showBeforeGroup = false;
      _showGroupCreating = false; _showSettings = false; _showProfile = false;
      _showGroupState = false; _showTravelPlan = false; _showJoinGroup = false;
      _selectedIndex = 0;
    });
  }

  void _openSettings() {
    setState(() {
      _showDetail = false; _showExplore = false; _showBeforeGroup = false;
      _showGroupCreating = false; _showSettings = true; _showProfile = false;
      _selectedIndex = -1;
    });
  }

  void _openGroupState() {
    setState(() {
      _showDetail = false; _showExplore = false; _showBeforeGroup = false;
      _showGroupCreating = false; _showSettings = false; _showProfile = false;
      _showJoinGroup = false; _showGroupState = true; _selectedIndex = -1;
    });
  }

  void _openTravelPlan() {
    setState(() {
      _showDetail = false; _showExplore = false; _showBeforeGroup = false;
      _showGroupCreating = false; _showSettings = false; _showProfile = false;
      _showJoinGroup = false; _showGroupState = false; _showTravelPlan = true;
      _selectedIndex = -1;
    });
  }

  void _openProfile() {
    setState(() {
      _showDetail = false; _showExplore = false; _showBeforeGroup = false;
      _showGroupCreating = false; _showSettings = false; _showProfile = true;
      _selectedIndex = -1;
    });
  }

  void _openJoinGroup() {
    setState(() {
      _showDetail = false; _showExplore = false; _showBeforeGroup = false;
      _showGroupCreating = false; _showSettings = false; _showProfile = false;
      _showJoinGroup = true; _selectedIndex = -1;
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
        setState(() { _showJoinGroup = false; _showBeforeGroup = true; });
        return false;
      }
      if (_showGroupState) {
        setState(() { _showGroupState = false; _selectedIndex = 3; });
        return false;
      }
      if (_showTravelPlan) {
        setState(() { _showTravelPlan = false; _selectedIndex = 3; });
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
      setState(() { _selectedIndex = 0; });
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
          setState(() { _showTravelPlan = false; _selectedIndex = 3; });
        },
      );
    } else if (_showGroupState) {
      mainContent = GroupStateScreen(
        onBack: () {
          setState(() { _showGroupState = false; _selectedIndex = 3; });
        },
      );
    } else if (_showJoinGroup) {
      mainContent = JoinGroupScreen(
        onBack: () {
          setState(() { _showJoinGroup = false; _showBeforeGroup = true; });
        },
      );
    } else if (_showProfile) {
      mainContent = ProfilePage(onBack: _openSettings);
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
          ],
        ),
      ),
    );
  }
}