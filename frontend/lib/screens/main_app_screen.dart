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
import 'destination_search_screen.dart';
import 'settings_screen.dart';
import 'private_screen.dart';
import 'notification_screen.dart';

class MainAppScreen extends StatefulWidget {
  final int initialIndex;
  const MainAppScreen({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  late int _selectedIndex;
  Destination? _selectedDestination;
  bool _showDetail = false;
  bool _showExplore = false;
  bool _showBeforeGroup = false;
  bool _showSettings = false;

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
      _showSettings = false;
    });
  }

  void _openDestinationDetail(Destination dest) {
    setState(() {
      _selectedDestination = dest;
      _showDetail = true;
      _showExplore = false;
      _showBeforeGroup = false;
      _showSettings = false;
    });
  }

  void _openDestinationExplore() {
    setState(() {
      _showDetail = false;
      _showExplore = true;
      _showBeforeGroup = false;
      _showSettings = false;
    });
  }

  void _openBeforeGroup() {
    setState(() {
      _showDetail = false;
      _showExplore = false;
      _showBeforeGroup = true;
      _showSettings = false;
    });
  }

  void _closeAllScreens() {
    setState(() {
      _showDetail = false;
      _showExplore = false;
      _showBeforeGroup = false;
      _showSettings = false;
    });
  }

  void _openSettings() {
    setState(() {
      _showDetail = false;
      _showExplore = false;
      _showBeforeGroup = false;
      _showSettings = true;
    });
  }

  void _openDestinationSearchScreen() {
    if (_selectedDestination != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DestinationSearchScreen(cityId: _selectedDestination!.cityId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget mainContent;
    if (_showSettings) {
      mainContent = SettingsScreen(onBack: _closeAllScreens);
    } else if (_showBeforeGroup) {
      mainContent = BeforeGroup(onBack: _closeAllScreens);
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
        NotificationScreen(), // Thay đổi ở đây
        MessagesScreen(),
        const PrivateScreen(),
      ];
      mainContent = IndexedStack(
        index: _selectedIndex,
        children: _screens,
      );
    }
    return Scaffold(
      extendBody: true, // ✅ Cho phép body kéo xuống dưới bottom bar
      backgroundColor: Colors.transparent, // ✅ Nền trong suốt
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white, // ✅ Màu nền (hoặc gradient nếu bạn muốn)
        ),
        child: mainContent,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
