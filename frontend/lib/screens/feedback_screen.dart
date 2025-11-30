import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  // Data models
  final String groupName = '2 tháng 1 lần';
  final String groupAvatar = 'assets/images/group_avatar.jpg';

  final List<String> members = [
    'Cả nhóm',
    'Nguyễn Văn A',
    'Trần Thị B',
    'Lê Văn C',
    'Phạm Thị D',
  ];

  // State
  String? selectedMember;
  int selectedStars = 0;
  Set<String> selectedTags = {};

  // Tags theo mức sao
  final Map<int, List<String>> tagsByRating = {
    1: ['Tệ', 'Không đáng tin', 'Thiếu trách nhiệm', 'Thất hứa', 'Vô tổ chức'],
    2: ['Kém', 'Muộn giờ', 'Thiếu nhiệt tình', 'Không hợp tác', 'Cần cải thiện'],
    3: ['Bình thường', 'Đúng giờ', 'Tham gia đầy đủ', 'Hợp tác', 'Ổn'],
    4: ['Tốt', 'Nhiệt tình', 'Thân thiện', 'Hỗ trợ', 'Đáng tin cậy'],
    5: ['Xuất sắc', 'Tuyệt vời', 'Chuyên nghiệp', 'Vui vẻ', 'Sáng tạo'],
  };

  void _resetForm() {
    setState(() {
      selectedMember = null;
      selectedStars = 0;
      selectedTags.clear();
    });
  }

  void _submitFeedback() {
    if (selectedMember == null || selectedStars == 0 || selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng chọn đầy đủ thông tin đánh giá'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // TODO: Gửi đánh giá lên server

    // Choose a localized display name for the member; translate "Cả nhóm" to "Whole group" in English
    final memberDisplay = (selectedMember == 'Cả nhóm')
        ? (context.locale.languageCode == 'en' ? 'Whole group' : 'Cả nhóm')
        : selectedMember!;

    // Localized success message
    final successMessage = (context.locale.languageCode == 'en')
        ? 'Feedback submitted for $memberDisplay'
        : 'Đã gửi đánh giá cho $memberDisplay';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(successMessage),
        backgroundColor: Colors.green,
      ),
    );

    // Reset form sau khi submit
    _resetForm();
  }

  @override
  Widget build(BuildContext context) {
    final availableTags = selectedStars > 0 ? tagsByRating[selectedStars]! : <String>[];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Background với 2 khung nhỏ hơn
          Container(
            color: const Color(0xFFB64B12),
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Spacer(flex: 80),
                      Container(width: 50, height: double.infinity, color: const Color(0xFF6D2D0B)),
                      const Spacer(flex: 40),
                      Container(width: 50, height: double.infinity, color: const Color(0xFF6D2D0B)),
                      const Spacer(flex: 80),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Responsive scaling dựa trên chiều cao màn hình
                final screenHeight = constraints.maxHeight;

                // Scale factor: baseline 800px = 1.0, 600px = 0.75
                final scaleFactor = (screenHeight / 800).clamp(0.65, 1.0);

                // Language scale: shorten big title when locale is English (to avoid overflow)
                final langScale = context.locale.languageCode == 'en' ? 0.75 : 1.0;

                // Tất cả sizes scale theo tỷ lệ
                final titleFontSize = 96.0 * scaleFactor * langScale;
                final titleOffset = -55.0 * scaleFactor * langScale;
                final contentTopPosition = 50.0 * scaleFactor;
                final contentTopPadding = 60.0 * scaleFactor;
                final groupImageSize = 120.0 * scaleFactor;
                final groupNameSize = 40.0 * scaleFactor;
                final starSize = 28.0 * scaleFactor;
                final sectionTitleSize = 32.0 * scaleFactor;
                final sectionSpacing = 40.0 * scaleFactor;
                final headerVerticalPadding = 15.0 * scaleFactor;
                final contentHorizontalPadding = 24.0 * scaleFactor;
                final contentBottomPadding = 24.0 * scaleFactor;
                final tagFontSize = 14.0 * scaleFactor;
                final bottomPosition = 20.0 * scaleFactor;
                final strokeWidth = 5.0 * scaleFactor;
                final containerPadding = 16.0 * scaleFactor;
                final tagPaddingH = 16.0 * scaleFactor;
                final tagPaddingV = 8.0 * scaleFactor;
                final wrapSpacing = 8.0 * scaleFactor;
                final minBoxHeight = 192.0 * scaleFactor;
                final emptyTextSize = 16.0 * scaleFactor;

                return Column(
                  children: [
                    // Header với nút back và confirm
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 26, vertical: headerVerticalPadding),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF6F6F8),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.black),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF6F6F8),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.check, color: Colors.black),
                              onPressed: _submitFeedback,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 10 * scaleFactor),

                    // Stack để đặt chữ GÓP Ý chồng lên viền khung
                    Expanded(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Content card - bắt đầu từ giữa chữ GÓP Ý
                          Positioned(
                            top: contentTopPosition,
                            left: 20,
                            right: 20,
                            bottom: bottomPosition,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0x65000000),
                                border: Border.all(color: const Color(0xFFEDE2CC), width: 6),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: ListView(
                                padding: EdgeInsets.fromLTRB(
                                  contentHorizontalPadding,
                                  contentTopPadding,
                                  contentHorizontalPadding,
                                  contentBottomPadding
                                ),
                                children: [
                                  // Group info
                                  Row(
                                    children: [
                                      Container(
                                        width: groupImageSize,
                                        height: groupImageSize,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          image: DecorationImage(
                                            image: AssetImage(groupAvatar),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 16 * scaleFactor),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              groupName,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: groupNameSize,
                                                fontFamily: 'Alumni Sans',
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            SizedBox(height: 8 * scaleFactor),
                                            Row(
                                              children: List.generate(5, (index) {
                                                return GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      selectedStars = index + 1;
                                                      selectedTags.clear();
                                                    });
                                                  },
                                                  child: Padding(
                                                    padding: const EdgeInsets.only(right: 1),
                                                    child: Icon(
                                                      index < selectedStars ? Icons.star : Icons.star_border,
                                                      color: const Color(0xFFFFD700),
                                                      size: starSize,
                                                    ),
                                                  ),
                                                );
                                              }),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: sectionSpacing),

                                  // Đối tượng section
                                  Text(
                                    'Đối tượng'.tr(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: sectionTitleSize,
                                      fontFamily: 'Alumni Sans',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: containerPadding),
                                  Container(
                                    padding: EdgeInsets.all(containerPadding),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: const Color(0xFFDCC9A7), width: 2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Wrap(
                                      spacing: wrapSpacing,
                                      runSpacing: wrapSpacing,
                                      children: members.map((member) {
                                        final isSelected = selectedMember == member;
                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              selectedMember = member;
                                            });
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: tagPaddingH,
                                              vertical: tagPaddingV
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? const Color(0xFFEDE2CC)
                                                  : const Color(0x60B64B12),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              // Translate only the 'Cả nhóm' key, keep real member names untranslated
                                              member == 'Cả nhóm' ? member.tr() : member,
                                              style: TextStyle(
                                                color: isSelected ? Colors.black : Colors.white,
                                                fontSize: tagFontSize,
                                                fontFamily: 'Alumni Sans',
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),

                                  SizedBox(height: sectionSpacing),

                                  // Ý kiến section
                                  Text(
                                    'Ý kiến'.tr(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: sectionTitleSize,
                                      fontFamily: 'Alumni Sans',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: containerPadding),
                                  Container(
                                    constraints: BoxConstraints(minHeight: minBoxHeight),
                                    padding: EdgeInsets.all(containerPadding),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: const Color(0xFFEDE2CC), width: 2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: selectedStars == 0
                                        ? Center(
                                      child: Text(
                                        'Vui lòng chọn số sao để xem gợi ý'.tr(),
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: emptyTextSize,
                                          fontFamily: 'Alumni Sans',
                                        ),
                                      ),
                                    )
                                        : Wrap(
                                      spacing: wrapSpacing,
                                      runSpacing: wrapSpacing,
                                      children: availableTags.map((tag) {
                                        final isSelected = selectedTags.contains(tag);
                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              if (isSelected) {
                                                selectedTags.remove(tag);
                                              } else {
                                                selectedTags.add(tag);
                                              }
                                            });
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: tagPaddingH,
                                              vertical: tagPaddingV
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? const Color(0xFFEDE2CC)
                                                  : const Color(0x60B64B12),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              tag.tr(),
                                              style: TextStyle(
                                                color: isSelected ? Colors.black : Colors.white,
                                                fontSize: tagFontSize,
                                                fontFamily: 'Alumni Sans',
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Chữ GÓP Ý với viền màu F7912D
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Transform.translate(
                              offset: Offset(0, titleOffset),
                              child: Center(
                                child: Stack(
                                  children: [
                                    // Viền
                                    Text(
                                      'GÓP Ý'.tr(),
                                      style: TextStyle(
                                        fontSize: titleFontSize,
                                        fontFamily: 'Alumni Sans',
                                        fontWeight: FontWeight.w900,
                                        foreground: Paint()
                                          ..style = PaintingStyle.stroke
                                          ..strokeWidth = strokeWidth
                                          ..color = const Color(0xFFF7912D),
                                      ),
                                    ),
                                    // Chữ chính
                                    Text(
                                      'GÓP Ý'.tr(),
                                      style: TextStyle(
                                        color: const Color(0xFF4A1A0F),
                                        fontSize: titleFontSize,
                                        fontFamily: 'Alumni Sans',
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
