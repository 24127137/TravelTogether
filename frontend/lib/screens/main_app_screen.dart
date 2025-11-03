/// File: main_app_screen.dart
/// Mô tả: Widget container chính quản lý các tab và bottom bar, giao diện tiếng Việt.

import 'package:flutter/material.dart';
import 'home_page.dart';
import 'messages_screen.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../models/destination.dart';
import 'destination_detail_screen.dart';
import 'destination_explore_screen.dart';
import 'before_group_screen.dart';
import 'destination_search_screen.dart';

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
    });
  }

  void _openDestinationDetail(Destination dest) {
    setState(() {
      _selectedDestination = dest;
      _showDetail = true;
      _showExplore = false;
      _showBeforeGroup = false;
    });
  }

  void _openDestinationExplore() {
    setState(() {
      _showDetail = false;
      _showExplore = true;
      _showBeforeGroup = false;
    });
  }

  void _openBeforeGroup() {
    setState(() {
      _showDetail = false;
      _showExplore = false;
      _showBeforeGroup = true;
    });
  }

  void _closeAllScreens() {
    setState(() {
      _showDetail = false;
      _showExplore = false;
      _showBeforeGroup = false;
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
    if (_showBeforeGroup) {
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
        HomePage(onDestinationTap: _openDestinationDetail),
        Center(child: Text('Thông báo', style: TextStyle(fontSize: 24))),
        MessagesScreen(),
        Center(child: Text('Tài khoản', style: TextStyle(fontSize: 24))),
      ];
      mainContent = IndexedStack(
        index: _selectedIndex,
        children: _screens,
      );
    }
    return Scaffold(
      body: mainContent,
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
