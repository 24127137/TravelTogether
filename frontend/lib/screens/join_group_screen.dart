import 'package:flutter/material.dart';
import 'package:my_travel_app/screens/home_page.dart';
import 'package:my_travel_app/screens/messages_screen.dart';
import 'package:my_travel_app/screens/notification_screen.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import 'dart:ui';
import 'package:confetti/confetti.dart';
import 'package:easy_localization/easy_localization.dart';


void main() {
  runApp(const FigmaToCodeApp());
}

class FigmaToCodeApp extends StatelessWidget {
  const FigmaToCodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color.fromARGB(255, 18, 32, 47),
      ),
      home: const JoinGroupScreen(),
    );
  }
}

class JoinGroupScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const JoinGroupScreen({
    super.key,
    this.onBack,
  });

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  late PageController _pageController;
  int _currentPage = 1;

  final List<GroupData> _groups = [
    GroupData(
      name: 'Khám phá Hà Nội',
      compatibility: 85,
      members: 8,
      maxMembers: 10,
      imageUrl: 'assets/images/saigon_art.jpg',
      tags: ['Ẩm thực', 'Văn hóa', 'Lịch sử', 'Nhiếp ảnh'],
      destinations: ['Hồ Hoàn Kiếm', 'Phố cổ', 'Văn Miếu', 'Tháp Rùa'],
    ),
    GroupData(
      name: 'Sài Gòn về đêm',
      compatibility: 92,
      members: 6,
      maxMembers: 8,
      imageUrl: 'assets/images/sapa.jpg',
      tags: ['Nightlife', 'Ẩm thực', 'Cafe', 'Shopping'],
      destinations: ['Chợ Bến Thành', 'Đường sách', 'Phố Bùi Viện', 'Bitexco'],
    ),
    GroupData(
      name: 'Đà Nẵng chill',
      compatibility: 78,
      members: 5,
      maxMembers: 10,
      imageUrl: 'assets/images/travel_plan.png',
      tags: ['Biển', 'Thư giãn', 'Resort', 'Hải sản'],
      destinations: ['Bãi Mỹ Khê', 'Bà Nà Hills', 'Cầu Rồng', 'Hội An'],
    ),
    GroupData(
      name: 'Saigon đẹp lắm',
      compatibility: 78,
      members: 5,
      maxMembers: 10,
      imageUrl: 'assets/images/saigon.jpg',
      tags: ['Biển', 'Thư giãn', 'Resort', 'Hải sản'],
      destinations: ['Bãi Mỹ Khê', 'Bà Nà Hills', 'Cầu Rồng', 'Hội An'],
    ),
    GroupData(
      name: 'Saigon chill',
      compatibility: 78,
      members: 5,
      maxMembers: 10,
      imageUrl: 'assets/images/canhan.jpg',
      tags: ['Biển', 'Thư giãn', 'Resort', 'Hải sản'],
      destinations: ['Bãi Mỹ Khê', 'Bà Nà Hills', 'Cầu Rồng', 'Hội An'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    const int multiplier = 1000;
    final int centerIndex = multiplier * _groups.length ~/ 2;

    _pageController = PageController(
      initialPage: centerIndex + _currentPage,
      viewportFraction: 0.75,
    );
  }


  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showGroupDetails(GroupData group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      // Cho phép đóng khi tap ra ngoài
      enableDrag: true,
      // Cho phép kéo xuống để đóng
      builder: (context) => GroupDetailsSheet(group: group),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/join_group.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 70),
                const SizedBox(height: 30),
                Expanded(
                  child: _buildCarousel(),
                ),
              ],
            ),
          ),
          // CHỈ GIỮ LẠI PHẦN NÀY - Ảnh Group 7.png
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  height: 584,
                  width: 630,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/Group 7.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 15, // Dưới status bar
            left: 26,
            child: GestureDetector(
              onTap: () {
                if (widget.onBack != null) {
                  widget.onBack!();
                } else {
                  Navigator.pop(context);
                }
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFF6F6F8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCarousel() {
    const int multiplier = 1000;

    return Transform.translate(
      offset: const Offset(0, -160), // Dịch carousel lên trên
      child: SizedBox(
        height: 380, // Tăng chiều cao từ 300 lên 400
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index % _groups.length;
            });
          },
          itemCount: _groups.length * multiplier,
          itemBuilder: (context, index) {
            final int actualIndex = index % _groups.length;
            final GroupData group = _groups[actualIndex];

            return AnimatedBuilder(
              animation: _pageController,
              builder: (context, child) {
                double value = 1.0;
                if (_pageController.position.haveDimensions) {
                  value = _pageController.page! - index;
                  value = (1 - (value.abs() * 0.3)).clamp(0.7, 1.0); // Thay đổi 0.6→0.3 và 0.85→0.7
                }
                return Center(
                  child: SizedBox(
                    height: Curves.easeInOut.transform(value) * 200, // Tăng từ 200 lên 350
                    width: Curves.easeInOut.transform(value) * 330,
                    child: child,
                  ),
                );
              },
              child: GestureDetector(
                onTap: () => _showGroupDetails(group),
                child: _buildGroupCard(group),
              ),
            );
          },
        ),
      ),
    );
  }
}

  Widget _buildGroupCard(GroupData group) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(
          image: AssetImage(group.imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${'compatibility'.tr()}: ${group.compatibility}%',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                '${'quantity'.tr()}: ${group.members}/${group.maxMembers}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


class GroupData {
  final String name;
  final int compatibility;
  final int members;
  final int maxMembers;
  final String imageUrl;
  final List<String> tags;
  final List<String> destinations;

  GroupData({
    required this.name,
    required this.compatibility,
    required this.members,
    required this.maxMembers,
    required this.imageUrl,
    required this.tags,
    required this.destinations,
  });
}

class GroupDetailsSheet extends StatefulWidget {
  final GroupData group;

  const GroupDetailsSheet({super.key, required this.group});

  @override
  State<GroupDetailsSheet> createState() => _GroupDetailsSheetState();
}

class _GroupDetailsSheetState extends State<GroupDetailsSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late ConfettiController _confettiController;
  ButtonState _buttonState = ButtonState.idle;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _handleJoinRequest() async {
    if (_buttonState != ButtonState.idle) return;

    setState(() => _buttonState = ButtonState.loading);
    _animationController.repeat();

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _buttonState = ButtonState.success);
      _animationController.stop();
      _confettiController.play();

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  // Tính toán maxChildSize dựa trên số lượng địa điểm
  double _calculateMaxSize() {
    final screenHeight = MediaQuery.of(context).size.height;

    // Chiều cao cố định
    const double dragHandle = 24; // Drag handle + margin
    const double title = 44; // Tiêu đề
    const double interestsSection = 120; // Section Sở thích (tùy số tag)
    const double routeTitle = 50; // Tiêu đề "Lộ trình"
    const double button = 100; // Nút + padding
    const double padding = 80; // Padding tổng

    // Chiều cao động: mỗi địa điểm ~40px
    final double destinationsHeight = widget.group.destinations.length * 40.0;

    // Tổng chiều cao nội dung
    final double totalContentHeight =
        dragHandle + title + interestsSection + routeTitle +
            destinationsHeight + button + padding;

    // Chuyển sang tỷ lệ % màn hình, giới hạn 0.5 - 0.95
    final double maxSize = (totalContentHeight / screenHeight).clamp(0.5, 0.95);

    return maxSize;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: _calculateMaxSize(), // ← Chiều cao động
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFD8713B).withOpacity(0.86),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Stack(
            children: [
              SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.group.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      'interests'.tr(),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.group.tags
                            .map((tag) => _buildTag(tag))
                            .toList(),
                      ),
                      hasBackground: false,
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      'itinerary'.tr(),
                      Column(
                        children: widget.group.destinations
                            .map((dest) => _buildDestinationItem(dest))
                            .toList(),
                      ),
                      hasBackground: true,
                    ),
                    const SizedBox(height: 30),
                    Center(child: _buildJoinButton()),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              // Confetti overlay
            ...List.generate(5, (index) {
          final double angle = -3.14 / 2 + (index - 2) * 0.5;

          return Align(
            alignment: Alignment.center,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: angle,
              emissionFrequency: 0.03,
              numberOfParticles: 25,
              maxBlastForce: 120,
              minBlastForce: 80,
              gravity: 0.25,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [
                Colors.red,
                Colors.blue,
                Colors.green,
                Colors.yellow,
                Colors.purple,
                Colors.orange,
                Colors.pink,
                Colors.cyan,
              ],
            ),
          );
        }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, Widget content, {bool hasBackground = false}) {
    if (hasBackground) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE2CC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: content,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE2CC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCD7F32)),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          color: Color(0xFF8A724C),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDestinationItem(String destination) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Color(0xFFCD7F32), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              destination,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF8A724C),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinButton() {
    return GestureDetector(
      onTap: _handleJoinRequest,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: _buttonState == ButtonState.loading ? 80 : 250,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _buttonState == ButtonState.success
                ? [Colors.green.shade400, Colors.green.shade700]
                : [const Color(0xFFB64B12), const Color(0xFFCD7F32)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: (_buttonState == ButtonState.success
                  ? Colors.green
                  : const Color(0xFFCD7F32))
                  .withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: _buildButtonContent(),
        ),
      ),
    );
  }

  Widget _buildButtonContent() {
    switch (_buttonState) {
      case ButtonState.idle:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'send_request'.tr(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );

      case ButtonState.loading:
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final delay = index * 0.2;
                final value = (_animationController.value - delay).clamp(0.0, 1.0);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Transform.translate(
                    offset: Offset(0, -10 * (0.5 - (value - 0.5).abs()) * 2),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        );

      case ButtonState.success:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'success'.tr(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
    }
  }
}

enum ButtonState { idle, loading, success }
