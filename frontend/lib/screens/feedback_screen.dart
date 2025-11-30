import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/feedback_models.dart'; // Import models
import '../../services/feedback_service.dart'; // Import FeedbackService
import '../../services/group_service.dart'; // <--- 1. Import GroupService để lấy ảnh

class FeedbackScreen extends StatefulWidget {
  final PendingReviewGroup groupData;
  final String accessToken;

  const FeedbackScreen({
    super.key,
    required this.groupData,
    required this.accessToken,
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  late List<UnreviewedMember> _remainingMembers;
  final FeedbackService _apiService = FeedbackService();
  final GroupService _groupService = GroupService(); // <--- 2. Init Service

  // State
  UnreviewedMember? selectedMember;
  int selectedStars = 0;
  Set<String> selectedTags = {};
  bool isLoading = false;

  // Biến chứa ảnh mới load từ API (nếu model cũ thiếu ảnh)
  String? _latestImageUrl;

  // --- MAPPING TAGS ---
  final Map<int, Map<String, String>> tagsMapping = {
    1: {
      'Tệ': 'bad', 'Không đáng tin': 'unreliable', 'Thiếu trách nhiệm': 'irresponsible',
      'Thất hứa': 'broken_promises', 'Vô tổ chức': 'disorganized'
    },
    2: {
      'Kém': 'poor', 'Muộn giờ': 'late', 'Thiếu nhiệt tình': 'unenthusiastic',
      'Không hợp tác': 'uncooperative', 'Cần cải thiện': 'needs_improvement'
    },
    3: {
      'Bình thường': 'average', 'Đúng giờ': 'punctual', 'Tham gia đầy đủ': 'participative',
      'Hợp tác': 'cooperative', 'Ổn': 'decent'
    },
    4: {
      'Tốt': 'good', 'Nhiệt tình': 'enthusiastic', 'Thân thiện': 'friendly',
      'Hỗ trợ': 'helpful', 'Đáng tin cậy': 'trustworthy'
    },
    5: {
      'Xuất sắc': 'excellent', 'Tuyệt vời': 'amazing', 'Chuyên nghiệp': 'professional',
      'Vui vẻ': 'fun', 'Sáng tạo': 'creative'
    },
  };

  @override
  void initState() {
    super.initState();
    _remainingMembers = List.from(widget.groupData.unreviewedMembers);

    // <--- 3. GỌI API LẤY ẢNH NẾU THIẾU --->
    if (widget.groupData.groupImageUrl == null || widget.groupData.groupImageUrl!.isEmpty) {
      _fetchImage();
    }
  }

  // Hàm gọi API lấy thông tin nhóm (chứa ảnh)
  Future<void> _fetchImage() async {
    try {
      final data = await _groupService.getGroupPlanById(widget.accessToken, widget.groupData.groupId);
      // Kiểm tra xem có dữ liệu và có link ảnh không
      if (data != null && data['group_image_url'] != null && mounted) {
        setState(() {
          _latestImageUrl = data['group_image_url'];
        });
      }
    } catch (e) {
      print("Lỗi load ảnh nhóm: $e");
    }
  }

  void _resetForm() {
    setState(() {
      selectedMember = null;
      selectedStars = 0;
      selectedTags.clear();
    });
  }

  Future<void> _submitFeedback() async {
    if (selectedMember == null || selectedStars == 0 || selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng chọn đầy đủ thông tin đánh giá'.tr()), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final englishTags = selectedTags.map((displayTag) {
        return tagsMapping[selectedStars]![displayTag]!;
      }).toList();

      final success = await _apiService.submitFeedback(
        token: widget.accessToken,
        revId: selectedMember!.profileId,
        groupId: widget.groupData.groupId,
        rating: selectedStars,
        contentTags: englishTags,
      );

      if (success) {
        final evaluatedName = selectedMember!.fullname;

        setState(() {
          _remainingMembers.removeWhere((m) => m.profileId == selectedMember!.profileId);
          _resetForm();
          isLoading = false;
        });

        if (_remainingMembers.isEmpty) {
          _showCompletionDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã gửi đánh giá cho $evaluatedName'), backgroundColor: Colors.green),
          );
        }
      } else {
        throw Exception("Server trả về lỗi (có thể do 401/400)");
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text("Hoàn tất".tr()),
        content: Text("Bạn đã đánh giá tất cả thành viên trong nhóm này.".tr()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, true);
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableDisplayTags = selectedStars > 0 ? tagsMapping[selectedStars]!.keys.toList() : <String>[];

    // <--- 4. ƯU TIÊN ẢNH VỪA LOAD ĐƯỢC --->
    final displayImage = _latestImageUrl ?? widget.groupData.groupImageUrl;
    final hasImage = displayImage != null && displayImage.isNotEmpty;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
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

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenHeight = constraints.maxHeight;
                final scaleFactor = (screenHeight / 800).clamp(0.65, 1.0);
                final langScale = context.locale.languageCode == 'en' ? 0.75 : 1.0;

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
                final containerPadding = 16.0 * scaleFactor;
                final tagFontSize = 14.0 * scaleFactor;

                return Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 26, vertical: headerVerticalPadding),
                      child: Row(
                        children: [
                          _buildCircleBtn(
                              icon: Icons.arrow_back,
                              onTap: () => Navigator.pop(context, true)
                          ),
                          const Spacer(),
                          if (isLoading)
                            const CircularProgressIndicator(color: Colors.white)
                          else
                            _buildCircleBtn(
                                icon: Icons.check,
                                onTap: _submitFeedback
                            ),
                        ],
                      ),
                    ),

                    SizedBox(height: 10 * scaleFactor),

                    Expanded(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            top: contentTopPosition,
                            left: 20, right: 20, bottom: 20 * scaleFactor,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0x65000000),
                                border: Border.all(color: const Color(0xFFEDE2CC), width: 6),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: ListView(
                                padding: EdgeInsets.fromLTRB(24 * scaleFactor, contentTopPadding, 24 * scaleFactor, 24 * scaleFactor),
                                children: [
                                  Row(
                                    children: [
                                      // <--- HIỂN THỊ ẢNH NHÓM --->
                                      Container(
                                        width: groupImageSize,
                                        height: groupImageSize,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          image: DecorationImage(
                                            image: hasImage
                                                ? NetworkImage(displayImage) as ImageProvider
                                                : const AssetImage('assets/images/default_group.jpg'),
                                            fit: BoxFit.cover,
                                            onError: (_, __) {},
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 16 * scaleFactor),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              widget.groupData.groupName,
                                              style: TextStyle(
                                                color: Colors.white, fontSize: groupNameSize,
                                                fontFamily: 'Alumni Sans', fontWeight: FontWeight.w900,
                                              ),
                                              maxLines: 2, overflow: TextOverflow.ellipsis,
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

                                  Text('Đối tượng'.tr(), style: _sectionTitleStyle(sectionTitleSize)),
                                  SizedBox(height: containerPadding),
                                  Container(
                                    padding: EdgeInsets.all(containerPadding),
                                    decoration: _boxDecoration(),
                                    child: _remainingMembers.isEmpty
                                        ? Center(child: Text("Đã đánh giá hết", style: TextStyle(color: Colors.white70, fontSize: tagFontSize)))
                                        : Wrap(
                                      spacing: 8 * scaleFactor,
                                      runSpacing: 8 * scaleFactor,
                                      children: _remainingMembers.map((member) {
                                        final isSelected = selectedMember?.profileId == member.profileId;
                                        return GestureDetector(
                                          onTap: () => setState(() => selectedMember = member),
                                          child: _buildTag(
                                              text: member.fullname,
                                              isSelected: isSelected,
                                              fontSize: tagFontSize
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),

                                  SizedBox(height: sectionSpacing),

                                  Text('Ý kiến'.tr(), style: _sectionTitleStyle(sectionTitleSize)),
                                  SizedBox(height: containerPadding),
                                  Container(
                                    constraints: BoxConstraints(minHeight: 192.0 * scaleFactor),
                                    padding: EdgeInsets.all(containerPadding),
                                    decoration: _boxDecoration(),
                                    child: selectedStars == 0
                                        ? Center(
                                      child: Text(
                                        'Vui lòng chọn số sao để xem gợi ý'.tr(),
                                        style: TextStyle(color: Colors.white70, fontSize: 16 * scaleFactor, fontFamily: 'Alumni Sans'),
                                      ),
                                    )
                                        : Wrap(
                                      spacing: 8 * scaleFactor,
                                      runSpacing: 8 * scaleFactor,
                                      children: availableDisplayTags.map((tag) {
                                        final isSelected = selectedTags.contains(tag);
                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              isSelected ? selectedTags.remove(tag) : selectedTags.add(tag);
                                            });
                                          },
                                          child: _buildTag(
                                              text: tag,
                                              isSelected: isSelected,
                                              fontSize: tagFontSize
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          Positioned(
                            top: 0, left: 0, right: 0,
                            child: Transform.translate(
                              offset: Offset(0, titleOffset),
                              child: Center(
                                child: Stack(
                                  children: [
                                    Text(
                                      'GÓP Ý'.tr(),
                                      style: TextStyle(
                                        fontSize: titleFontSize, fontFamily: 'Alumni Sans', fontWeight: FontWeight.w900,
                                        foreground: Paint()..style = PaintingStyle.stroke..strokeWidth = 5 * scaleFactor..color = const Color(0xFFF7912D),
                                      ),
                                    ),
                                    Text(
                                      'GÓP Ý'.tr(),
                                      style: TextStyle(
                                        color: const Color(0xFF4A1A0F), fontSize: titleFontSize,
                                        fontFamily: 'Alumni Sans', fontWeight: FontWeight.w900,
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

  Widget _buildCircleBtn({required IconData icon, required VoidCallback onTap}) {
    return Container(
      width: 44, height: 44,
      decoration: const BoxDecoration(color: Color(0xFFF6F6F8), shape: BoxShape.circle),
      child: IconButton(icon: Icon(icon, color: Colors.black), onPressed: onTap),
    );
  }

  TextStyle _sectionTitleStyle(double size) {
    return TextStyle(color: Colors.white, fontSize: size, fontFamily: 'Alumni Sans', fontWeight: FontWeight.w500);
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      border: Border.all(color: const Color(0xFFEDE2CC), width: 2),
      borderRadius: BorderRadius.circular(10),
    );
  }

  Widget _buildTag({required String text, required bool isSelected, required double fontSize}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFEDE2CC) : const Color(0x60B64B12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text.tr(),
        style: TextStyle(
          color: isSelected ? Colors.black : Colors.white,
          fontSize: fontSize, fontFamily: 'Alumni Sans', fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}