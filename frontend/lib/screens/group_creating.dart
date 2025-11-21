/// File: group_creating.dart
/// Screen for creating a new travel group
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math' as math;
import '../widgets/calendar_card.dart';

class GroupCreatingScreen extends StatefulWidget {
  final String? destinationName;
  final VoidCallback? onBack;

  const GroupCreatingScreen({
    Key? key,
    this.destinationName,
    this.onBack,
  }) : super(key: key);

  @override
  State<GroupCreatingScreen> createState() => _GroupCreatingScreenState();
}

class _GroupCreatingScreenState extends State<GroupCreatingScreen>
    with TickerProviderStateMixin {
  // Key to locate the date field position for popover
  final GlobalKey _dateFieldKey = GlobalKey();

  // Dữ liệu nhóm
  int _numberOfPeople = 10;
  DateTime? _selectedStartDate = DateTime(2025, 10, 21);
  DateTime? _selectedEndDate = DateTime(2025, 10, 24);
  DateTime _focusedDay = DateTime.now();
  String _groupName = 'Mộng mơ';
  File? _groupAvatar;

  // Sở thích và lộ trình
  final List<String> _selectedInterests = [
    'Nghỉ dưỡng',
    'Lãng mạn',
    'Ẩm thực',
    'Thiên nhiên'
  ];
  final List<String> _itineraryItems = [
    'Hồ Xuân Hương',
    'Thiền viện Trúc Lâm',
  ];

  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _stateTransitionController;
  late Animation<double> _slideAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Color?> _buttonColorAnimation;
  late Animation<Color?> _circleColorAnimation;

  int _currentState = 0; // 0: Idle, 1: Processing, 2: Success
  double _dragOffset = 0;
  final double _maxDragOffset = 260;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _stateTransitionController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _textFadeAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );

    _buttonColorAnimation = ColorTween(
      begin: const Color(0xFFEDE2CC),
      end: const Color(0xFFDCC9A7),
    ).animate(_slideController);

    _circleColorAnimation = ColorTween(
      begin: const Color(0xFFF7F3E8),
      end: const Color(0xFFCD7F32),
    ).animate(_slideController);
  }

  @override
  void dispose() {
    _slideController.dispose();
    _stateTransitionController.dispose();
    super.dispose();
  }

  void _handleSlideComplete() async {
    setState(() => _currentState = 1);

    // Simulate processing
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _currentState = 2);

      // Auto close after success
      await Future.delayed(const Duration(seconds: 2));
      if (mounted && widget.onBack != null) {
        widget.onBack!();
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _groupAvatar = File(pickedFile.path);
      });
    }
  }

  void _showEditGroupNameDialog() {
    final controller = TextEditingController(text: _groupName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF7F3E8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Đặt tên nhóm',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF000000),
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nhập tên nhóm',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDCC9A7), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFB99668), width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF7F3E8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () {
              setState(() {
                _groupName = controller.text.isEmpty ? 'Mộng mơ' : controller.text;
              });
              Navigator.pop(context);
            },
            child: const Text(
              'Xác nhận',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3E8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 104),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNumberOfPeople(),
                    const SizedBox(height: 16),
                    _buildLocationAndDate(),
                    const SizedBox(height: 24),
                    _buildInterestsSection(),
                    const SizedBox(height: 24),
                    _buildItinerarySection(),
                    const SizedBox(height: 32),
                    _buildSliderButton(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: Container(
              width: double.infinity,
              height: 300,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/create_background.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Content
          Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: widget.onBack,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFF000000),
                          size: 20,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'TẠO NHÓM',
                            style: const TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFF18900),
                              decoration: TextDecoration.none,
                              fontFamily: 'Alumni Sans',
                              height: 0.965,
                              letterSpacing: -0.04 * 64,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              const Spacer(),

              // Avatar và tên nhóm
              Column(
                children: [
                  // Avatar với khả năng upload
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            image: DecorationImage(
                              image: _groupAvatar != null
                                  ? FileImage(_groupAvatar!)
                                  : const AssetImage('assets/images/group_creating/avatar_gr.jpg')
                              as ImageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF18900),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 19,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _showEditGroupNameDialog,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _groupName,
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFF7F3E8),
                            decoration: TextDecoration.none,
                            fontFamily: 'Alegreya',
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.edit,
                          color: Color(0xFFE5CDB1),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberOfPeople() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _showNumberPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_numberOfPeople người',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF000000),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Image.asset(
                  'assets/images/group_creating/chevron-down.jpg',
                  width: 14,
                  height: 14,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationAndDate() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/group_creating/search_24px.jpg',
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.destinationName ?? 'Đà Lạt',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF000000),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: _showCalendarDialog,
            child: Container(
              key: _dateFieldKey,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/group_creating/calendar_today.jpg',
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedStartDate != null && _selectedEndDate != null
                          ? '${_selectedStartDate!.day} - ${_selectedEndDate!.day} / ${_selectedStartDate!.month} / ${_selectedStartDate!.year}'
                          : 'Chọn ngày',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF000000),
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInterestsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF7F3E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCC9A7), width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sở thích',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000000),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedInterests.map((interest) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCC9A7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '#$interest',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF000000),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildItinerarySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCC9A7), width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lộ trình',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000000),
            ),
          ),
          const SizedBox(height: 12),
          ..._itineraryItems.map((item) => _buildItineraryItem(item)).toList(),
        ],
      ),
    );
  }

  Widget _buildItineraryItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000000),
            ),
          ),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF000000),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderButton() {
    if (_currentState == 0) {
      return GestureDetector(
        onHorizontalDragUpdate: (details) {
          setState(() {
            _dragOffset += details.delta.dx;
            _dragOffset = _dragOffset.clamp(0.0, _maxDragOffset);
            _slideController.value = _dragOffset / _maxDragOffset;
          });
        },
        onHorizontalDragEnd: (details) {
          if (_dragOffset >= _maxDragOffset * 0.8) {
            setState(() {
              _dragOffset = _maxDragOffset;
            });
            _handleSlideComplete();
          } else {
            setState(() {
              _dragOffset = 0;
            });
            _slideController.animateTo(0);
          }
        },
        child: AnimatedBuilder(
          animation: _slideController,
          builder: (context, child) {
            return Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.lerp(const Color(0xFFB99668), const Color(0xFFCD7F32),
                        _slideController.value)!,
                    Color.lerp(const Color(0xFFEDE2CC), const Color(0xFFDCC9A7),
                        _slideController.value)!,
                  ],
                ),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Text "Trượt để tạo" → "Tiến hành"
                  AnimatedOpacity(
                    opacity: 1 - _slideController.value,
                    duration: const Duration(milliseconds: 200),
                    child: Transform.translate(
                      offset: Offset(_dragOffset * 0.5, 0),
                      child: const Text(
                        'Trượt để tạo',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                          fontFamily: 'Alegreya',
                        ),
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: _slideController.value,
                    duration: const Duration(milliseconds: 200),
                    child: Transform.translate(
                      offset: Offset(-_maxDragOffset * (1 - _slideController.value) * 0.5, 0),
                      child: const Text(
                        'Tiến hành',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Alegreya',
                        ),
                      ),
                    ),
                  ),

                  // Sliding circle
                  Positioned(
                    left: 4 + _dragOffset,
                    child: Container(
                      width: 75,
                      height: 75,
                      decoration: BoxDecoration(
                        color: _circleColorAnimation.value,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.arrow_forward,
                          color: Colors.black,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    } else if (_currentState == 1) {
      return Container(
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFCD7F32), Color(0xFFDCC9A7)],
          ),
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Text(
              'Tiến hành',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Inter',
              ),
            ),
            Positioned(
              right: 4,
              child: Container(
                width: 75,
                height: 75,
                decoration: const BoxDecoration(
                  color: Color(0xFFCD7F32),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFB64B12), Color(0xFFCD7F32)],
          ),
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Text(
              'Thành công!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Alegreya',
              ),
            ),
            Positioned(
              right: 4,
              child: Container(
                width: 75,
                height: 75,
                decoration: const BoxDecoration(
                  color: Color(0xFFE49342),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.black,
                  size: 36,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _showCalendarDialog() {
    DateTime? tempStartDate = _selectedStartDate;
    DateTime? tempEndDate = _selectedEndDate;
    DateTime tempFocusedDay = _focusedDay;

    // Try to get position of the date field; fallback to center if not available
    final RenderBox? renderBox = _dateFieldKey.currentContext?.findRenderObject() as RenderBox?;
    final screenSize = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    // Desired dialog size
    final dialogWidth = (screenSize.width * 0.98).clamp(320.0, screenSize.width - 24.0);
    final dialogHeight = (screenSize.height * 0.68).clamp(280.0, screenSize.height - 120.0);

    // Compute anchor position
    double left = (screenSize.width - dialogWidth) / 2;
    double top = (screenSize.height - dialogHeight) / 2;

    if (renderBox != null) {
      final fieldOffset = renderBox.localToGlobal(Offset.zero);
      final fieldSize = renderBox.size;

      // Prefer showing below the field
      final candidateTop = fieldOffset.dy + fieldSize.height + 8;
      final availableBelow = screenSize.height - candidateTop - bottomInset - kBottomNavigationBarHeight;

      if (availableBelow >= dialogHeight) {
        top = math.max(12.0, candidateTop);
      } else {
        // Not enough space below, try above
        final candidateAbove = fieldOffset.dy - dialogHeight - 8;
        if (candidateAbove >= 12.0) {
          top = candidateAbove;
        } else {
          // Fallback: center vertically
          top = math.max(12.0, (screenSize.height - dialogHeight) / 2);
        }
      }

      // Center horizontally on the field if possible
      final candidateLeft = fieldOffset.dx + (fieldSize.width / 2) - (dialogWidth / 2);
      left = candidateLeft.clamp(12.0, screenSize.width - dialogWidth - 12.0);
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'calendar',
      barrierColor: Colors.black.withAlpha((0.5 * 255).toInt()),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return Stack(
          children: [
            // tapping the scrim will dismiss because barrierDismissible true
            Positioned(
              left: left,
              top: top,
              width: dialogWidth,
              child: Material(
                color: Colors.transparent,
                child: CalendarCard(
                  margin: EdgeInsets.zero,
                  focusedDay: tempFocusedDay,
                  rangeStart: tempStartDate,
                  rangeEnd: tempEndDate,
                  accentColor: const Color(0xFFB99668),
                  onDaySelected: (selectedDay, focusedDay) {
                    // Update temp values inside the dialog using Navigator's overlay
                    tempStartDate = tempStartDate == null || tempEndDate != null
                        ? selectedDay
                        : (selectedDay.isAfter(tempStartDate!) ? tempStartDate : selectedDay);
                    // The real logic needs more careful handling; we'll mirror previous behavior below in onClose
                    tempFocusedDay = focusedDay;
                  },
                  onPageChanged: (focusedDay) {
                    tempFocusedDay = focusedDay;
                  },
                  onClose: () {
                    // On close commit the temp values to state and dismiss
                    setState(() {
                      _selectedStartDate = tempStartDate;
                      _selectedEndDate = tempEndDate;
                      _focusedDay = tempFocusedDay;
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, anim, secAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOut);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(scale: curved, child: child),
        );
      },
    );
  }

  void _showNumberPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int tempNumber = _numberOfPeople;
        return AlertDialog(
          backgroundColor: const Color(0xFFF7F3E8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Chọn số người (tối đa 10)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF000000),
            ),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 36),
                        color: const Color(0xFFB99668),
                        onPressed: tempNumber > 1
                            ? () {
                          setDialogState(() {
                            tempNumber--;
                          });
                        }
                            : null, // Disable khi = 1
                      ),
                      Container(
                        width: 80,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFB99668), width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$tempNumber',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF000000),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 36),
                        color: const Color(0xFFB99668),
                        onPressed: tempNumber < 10
                            ? () {
                          setDialogState(() {
                            tempNumber++;
                          });
                        }
                            : null, // ← Disable khi đạt 10
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$tempNumber / 10',
                    style: TextStyle(
                      fontSize: 12,
                      color: tempNumber == 10 ? Colors.red : Colors.grey,
                      fontWeight: tempNumber == 10 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB99668),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () {
                setState(() {
                  _numberOfPeople = tempNumber;
                });
                Navigator.pop(context);
              },
              child: const Text(
                'Xác nhận',
                style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
