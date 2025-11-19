import 'package:flutter/material.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  // Data models
  final String groupName = '2 tháng 1 lần';
  final String groupAvatar = 'https://placehold.co/107x107';

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
        const SnackBar(
          content: Text('Vui lòng chọn đầy đủ thông tin đánh giá'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // TODO: Gửi đánh giá lên server
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã gửi đánh giá cho $selectedMember'),
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
      body: Stack(
        children: [
          // Background
          Container(
            color: const Color(0xFFB64B12),
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Spacer(flex: 64),
                      Container(width: 239, height: double.infinity, color: const Color(0xFF6D2D0B)),
                      const Spacer(flex: 137),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header với nút back và confirm
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 15),
                  child: Row(
                    children: [
                      // Back button
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
                      // Confirm button
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

                // Title
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    'GÓP Ý',
                    style: TextStyle(
                      color: Color(0xFF4A1A0F),
                      fontSize: 96,
                      fontFamily: 'Alumni Sans',
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Content card
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.27),
                      border: Border.all(color: const Color(0xFFEDE2CC), width: 6),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        // Group info
                        Row(
                          children: [
                            // Group avatar
                            Container(
                              width: 107,
                              height: 107,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                image: DecorationImage(
                                  image: NetworkImage(groupAvatar),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Group name and stars
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    groupName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 40,
                                      fontFamily: 'Alumni Sans',
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Star selector
                                  Row(
                                    children: List.generate(5, (index) {
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedStars = index + 1;
                                            selectedTags.clear(); // Clear tags khi đổi sao
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.only(right: 8),
                                          child: Icon(
                                            index < selectedStars ? Icons.star : Icons.star_border,
                                            color: const Color(0xFFFFD700),
                                            size: 35,
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

                        const SizedBox(height: 40),

                        // Đối tượng section
                        const Text(
                          'Đối tượng',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontFamily: 'Alumni Sans',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFDCC9A7), width: 2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: members.map((member) {
                              final isSelected = selectedMember == member;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedMember = member;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFEDE2CC)
                                        : const Color(0x60B64B12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    member,
                                    style: TextStyle(
                                      color: isSelected ? Colors.black : Colors.white,
                                      fontSize: 14,
                                      fontFamily: 'Alumni Sans',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Ý kiến section
                        const Text(
                          'Ý kiến',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontFamily: 'Alumni Sans',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          constraints: const BoxConstraints(minHeight: 192),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFEDE2CC), width: 2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: selectedStars == 0
                              ? const Center(
                            child: Text(
                              'Vui lòng chọn số sao để xem gợi ý',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontFamily: 'Alumni Sans',
                              ),
                            ),
                          )
                              : Wrap(
                            spacing: 8,
                            runSpacing: 8,
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
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFEDE2CC)
                                        : const Color(0x60B64B12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      color: isSelected ? Colors.black : Colors.white,
                                      fontSize: 14,
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

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
