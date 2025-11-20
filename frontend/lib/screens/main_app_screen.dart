/// File: main_app_screen.dart
/// Mô tả: Widget container chính quản lý các tab và bottom bar, giao diện tiếng Việt.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'home_page.dart';
import 'messages_screen.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../models/destination.dart';
import 'destination_detail_screen.dart';
import 'destination_explore_screen.dart';
import 'before_group_screen.dart';
import 'group_creating.dart';
import 'destination_search_screen.dart';
import 'settings_screen.dart';
import 'private_screen.dart';
import 'notification_screen.dart';
import 'profile.dart';
import 'join_group_screen.dart';

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
  String? _groupDestinationName;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _showDetail = false;
      _showExplore = false;
      _showBeforeGroup = false;
      _showGroupCreating = false;
      _showSettings = false;
      _showProfile = false;
      _showJoinGroup = false;
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
      _selectedIndex = -1; // ← KHÔNG ửng màu icon nào
    });
  }

  void _openDestinationExplore() {
    setState(() {
      _showDetail = false;
      _showExplore = true;
      _showBeforeGroup = false;
      _showGroupCreating = false;
      _showSettings = false;
      _selectedIndex = -1; // ← KHÔNG ửng màu icon nào
    });
  }

  void _openBeforeGroup() {
    setState(() {
      _showDetail = false;
      _showExplore = false;
      _showBeforeGroup = true;
      _showGroupCreating = false;
      _showSettings = false;
      _selectedIndex = -1; // ← KHÔNG ửng màu icon nào
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
      _selectedIndex = -1; // ← KHÔNG ửng màu icon nào
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
    });
  }

  void _openSettings() {
    setState(() {
      _showDetail = false;
      _showExplore = false;
      _showBeforeGroup = false;
      _showGroupCreating = false;
      _showSettings = true;
      _showProfile = false;
      _selectedIndex = -1; // Đặt selectedIndex về -1 để không chọn tab nào
    });
  }

  void _openProfile() {
    setState(() {
      _showDetail = false;
      _showExplore = false;
      _showBeforeGroup = false;
      _showGroupCreating = false;
      _showSettings = false;
      _showProfile = true;
      _selectedIndex = -1; // ← KHÔNG ửng màu icon nào
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
      _showJoinGroup = true; // ← Thêm flag mới
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

  // Xử lý nút back của điện thoại
  Future<bool> _handleBackButton() async {
    // Nếu đang ở màn hình phụ (Settings, Detail, Explore, BeforeGroup, GroupCreating, Profile)
    if (_showSettings || _showDetail || _showExplore || _showBeforeGroup ||
        _showGroupCreating || _showProfile) {
      if (_showJoinGroup) {
        setState(() {
          _showJoinGroup = false;
          _showBeforeGroup = true;
        });
        return false;
      }
      // Nếu đang ở Profile, quay về Settings
      if (_showProfile) {
        _openSettings();
        return false;
      }
      // Nếu đang ở GroupCreating, quay về BeforeGroup
      if (_showGroupCreating) {
        _openBeforeGroup();
        return false;
      }
      // Các trường hợp khác, đóng tất cả
      _closeAllScreens();
      return false; // Không thoát app
    }

    // Nếu đang ở tab khác ngoài Home (tab 0)
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0; // Quay về tab Home
      });
      return false; // Không thoát app
    }

    // Nếu đang ở tab Home → Hiển thị dialog xác nhận thoát
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

    return shouldExit ?? false; // Chỉ thoát khi user chọn "Thoát"
  }

  @override
  Widget build(BuildContext context) {
    Widget mainContent;
    if (_showJoinGroup) {
      mainContent = JoinGroupScreen(
        onBack: () {
          setState(() {
            _showJoinGroup = false;
            _showBeforeGroup = true;
          });
        },
      );
    }
    else if (_showProfile) {
      mainContent = ProfilePage(onBack: _openSettings);
    } else if (_showSettings) {
      mainContent =
          SettingsScreen(onBack: _closeAllScreens, onProfileTap: _openProfile);
    } else if (_showGroupCreating) {
      mainContent = GroupCreatingScreen(
        destinationName: _groupDestinationName,
        onBack: _openBeforeGroup,
      );
    } else if (_showBeforeGroup) {
      mainContent = BeforeGroup(
        onBack: _closeAllScreens,
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
        onBack: _closeAllScreens,
        onBeforeGroup: _openBeforeGroup,
        onSearchPlace: _openDestinationSearchScreen,
      );
    } else {
      final List<Widget> _screens = [
        HomePage(
          onDestinationTap: _openDestinationDetail,
          onSettingsTap: _openSettings,
        ),
        NotificationScreen(),
        MessagesScreen(accessToken: widget.accessToken),
        const PrivateScreen(),
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
        extendBody: true,
        body: Stack( // ← Thêm Stack
          children: [
            // Nội dung chính
            mainContent,

            // Thanh bar luôn ở trên cùng
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
