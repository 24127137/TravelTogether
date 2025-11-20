/// File: group_creating.dart
/// Screen for creating a new travel group
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
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

class _GroupCreatingScreenState extends State<GroupCreatingScreen> {
  // Trạng thái cho hiệu ứng trượt
  int _currentStep = 0; // 0: Trượt để tạo, 1: Tiến hành, 2: Thành công

  // Dữ liệu nhóm
  int _numberOfPeople = 10;
  DateTime? _selectedStartDate = DateTime(2025, 10, 21);
  DateTime? _selectedEndDate = DateTime(2025, 10, 24);
  DateTime _focusedDay = DateTime.now();

  // Controller cho dragging
  double _dragOffset = 0;
  final double _maxDragOffset = 250;

  // Sở thích đã chọn
  final List<String> _selectedInterests = [
    'Nghỉ dưỡng',
    'Lãng mạn',
    'Ẩm thực',
    'Thiên nhiên'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3E8), // Màu nền chính
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
      height: 300,
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
          // Background image (Top.jpg - hình thuyền buồm) - KHÔNG CÓ OVERLAY
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: Container(
              width: double.infinity,
              height: 300,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/group_creating/Top.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Content
          Column(
            children: [
              // Top bar với back button và title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (widget.onBack != null) {
                          widget.onBack!();
                        }
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/group_creating/Arrow.jpg',
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'create_group_title'.tr(),
                          style: const TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.w900, // Black weight
                            color: Color(0xFFF18900),
                            decoration: TextDecoration.none,
                            fontFamily: 'AlumniSans',
                            height: 0.965, // Line height 96.5%
                            letterSpacing: -0.04 * 64, // -4% of font size
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
                  // Avatar circle
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/group_creating/avatar_gr.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Mộng mơ',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFF18900),
                      decoration: TextDecoration.none,
                      fontFamily: 'DMSerifDisplay',
                      height: 1.0,
                      letterSpacing: 0.5,
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
                  '$_numberOfPeople ${'number_of_people'.tr()}',
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
        // Box Vị trí
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

        // Box Ngày
        Expanded(
          child: GestureDetector(
            onTap: _showCalendarDialog,
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
                    'assets/images/group_creating/calendar_today.jpg',
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedStartDate != null && _selectedEndDate != null
                          ? '${_selectedStartDate!.day} - ${_selectedEndDate!.day} / ${_selectedStartDate!.month} / ${_selectedStartDate!.year}'
                          : 'choose_date'.tr(),
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
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'interests'.tr(),
            style: const TextStyle(
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
                  color: const Color(0xFFDCC9A7), // Màu nền thẻ Sở thích
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
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'itinerary'.tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000000),
            ),
          ),
          const SizedBox(height: 12),
          _buildItineraryItem('Hồ Xuân Hương'),
          const SizedBox(height: 8),
          _buildItineraryItem('Thiền viện Trúc Lâm'),
        ],
      ),
    );
  }

  Widget _buildItineraryItem(String text) {
    return Row(
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
    );
  }

  Widget _buildSliderButton() {
    // Hiển thị theo trạng thái hiện tại
    String buttonText;
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    IconData? iconData;

    switch (_currentStep) {
      case 0:
        buttonText = 'slide_to_create'.tr();
        backgroundColor = const Color(0xFFEDE2CC);
        borderColor = const Color(0xFFB99668);
        textColor = Colors.black.withValues(alpha: 0.4);
        iconData = null;
        break;
      case 1:
        buttonText = 'proceed'.tr();
        backgroundColor = const Color(0xFFDA9551);
        borderColor = const Color(0xFFB97636);
        textColor = Colors.white;
        iconData = Icons.arrow_forward;
        break;
      case 2:
        buttonText = 'success_created'.tr();
        backgroundColor = const Color(0xFFB85E2A);
        borderColor = const Color(0xFF8B3E15);
        textColor = Colors.white;
        iconData = Icons.check;
        break;
      default:
        buttonText = 'slide_to_create'.tr();
        backgroundColor = const Color(0xFFEDE2CC);
        borderColor = const Color(0xFFB99668);
        textColor = Colors.black.withValues(alpha: 0.4);
        iconData = null;
    }

    if (_currentStep == 0) {
      // Interactive slider for first step
      return GestureDetector(
        onHorizontalDragUpdate: (details) {
          setState(() {
            _dragOffset += details.delta.dx;
            if (_dragOffset < 0) _dragOffset = 0;
            if (_dragOffset > _maxDragOffset) {
              _currentStep = 1;
              _dragOffset = 0;
              // Simulate processing time
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  setState(() {
                    _currentStep = 2;
                  });
                }
              });
            }
          });
        },
        onHorizontalDragEnd: (details) {
          if (_dragOffset < _maxDragOffset) {
            setState(() {
              _dragOffset = 0;
            });
          }
        },
        child: Container(
          width: double.infinity,
          height: 64,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: borderColor, width: 3),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Text
              Text(
                buttonText,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontFamily: 'Inter',
                ),
              ),
              // Slider circle with Vector icon
              Positioned(
                left: 4 + _dragOffset,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFFFFF),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/group_creating/Vector.jpg',
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Static button for other steps
      return Container(
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: borderColor, width: 3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              buttonText,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
                fontFamily: 'Inter',
                decoration: TextDecoration.none,
              ),
            ),
            if (iconData != null) ...[
              const SizedBox(width: 12),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _currentStep == 1
                      ? const Color(0xFFE8A862)
                      : const Color(0xFFD17847),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconData,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ],
        ),
      );
    }
  }

  void _showCalendarDialog() {
    DateTime? tempStartDate = _selectedStartDate;
    DateTime? tempEndDate = _selectedEndDate;
    DateTime tempFocusedDay = _focusedDay;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: CalendarCard(
                focusedDay: tempFocusedDay,
                rangeStart: tempStartDate,
                rangeEnd: tempEndDate,
                accentColor: const Color(0xFFB99668), // Màu vàng nâu cho group creating
                onDaySelected: (selectedDay, focusedDay) {
                  setDialogState(() {
                    if (tempStartDate == null || tempEndDate != null) {
                      tempStartDate = selectedDay;
                      tempEndDate = null;
                    } else if (selectedDay.isAfter(tempStartDate!)) {
                      tempEndDate = selectedDay;
                    } else {
                      tempStartDate = selectedDay;
                      tempEndDate = null;
                    }
                    tempFocusedDay = focusedDay;
                  });
                },
                onPageChanged: (focusedDay) {
                  setDialogState(() {
                    tempFocusedDay = focusedDay;
                  });
                },
                onClose: () {
                  // Lưu giá trị vào state chính khi đóng
                  setState(() {
                    _selectedStartDate = tempStartDate;
                    _selectedEndDate = tempEndDate;
                    _focusedDay = tempFocusedDay;
                  });
                  Navigator.pop(context);
                },
              ),
            );
          },
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
          backgroundColor: const Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'select_number'.tr(),
            style: const TextStyle(
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
                        icon: const Icon(Icons.remove_circle_outline, size: 32),
                        color: const Color(0xFFB99668),
                        onPressed: () {
                          if (tempNumber > 1) {
                            setDialogState(() {
                              tempNumber--;
                            });
                          }
                        },
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
                        icon: const Icon(Icons.add_circle_outline, size: 32),
                        color: const Color(0xFFB99668),
                        onPressed: () {
                          if (tempNumber < 100) {
                            setDialogState(() {
                              tempNumber++;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'cancel_action'.tr(),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB99668),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 2,
              ),
              onPressed: () {
                setState(() {
                  _numberOfPeople = tempNumber;
                });
                Navigator.pop(context);
              },
              child: Text(
                'confirm_action'.tr(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
