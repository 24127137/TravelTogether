import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/feedback_service.dart';
import '../models/feedback_models.dart';

class ReputationScreen extends StatefulWidget {
  const ReputationScreen({super.key});

  @override
  State<ReputationScreen> createState() => _ReputationScreenState();
}

class _ReputationScreenState extends State<ReputationScreen> {
  final FeedbackService _feedbackService = FeedbackService();

  bool _isLoading = true;
  MyReputationResponse? _reputationData;

  // Thông tin user (lấy từ cache/prefs vì API reputation chỉ trả về rating)
  String _userName = "Loading...";
  String _userEmail = "";
  String? _userAvatar;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    // Lấy thông tin user từ cache (lưu lúc login)
    setState(() {
      _userName = prefs.getString('user_fullname') ?? "User";
      _userEmail = prefs.getString('user_email') ?? "";
      _userAvatar = prefs.getString('user_avatar'); // URL avatar nếu có
    });

    if (token != null) {
      final data = await _feedbackService.getMyReputation(token);
      if (mounted) {
        setState(() {
          _reputationData = data;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Background (Giữ nguyên thiết kế cũ)
          Container(
            color: const Color(0xFFB64B12),
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Spacer(flex: 141),
                      Container(width: 47, color: const Color(0xFFCD7F32)),
                      const Spacer(flex: 65),
                      Container(width: 47, color: const Color(0xFFCD7F32)),
                      const Spacer(flex: 140),
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
                final langScale = context.locale.languageCode == 'en' ? 0.65 : 1.0;

                // Scaled sizes
                final titleFontSize = 96.0 * scaleFactor * langScale;
                final titleOffset = -55.0 * scaleFactor;
                final contentTopPosition = 50.0 * scaleFactor;
                final contentTopPadding = 60.0 * scaleFactor;
                final headerVerticalPadding = 15.0 * scaleFactor;
                final listPaddingH = 24.0 * scaleFactor;
                final userCardGap = 40.0 * scaleFactor;
                final strokeWidth = 5.0 * scaleFactor;

                return Column(
                  children: [
                    // Header
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 26, vertical: headerVerticalPadding),
                      child: Row(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: const BoxDecoration(color: Color(0xFFF6F6F8), shape: BoxShape.circle),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.black),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 10 * scaleFactor),

                    Expanded(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Card Nội dung
                          Positioned(
                            top: contentTopPosition,
                            left: 20, right: 20, bottom: 20 * scaleFactor,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.27),
                                border: Border.all(color: const Color(0xFFEDE2CC), width: 6),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: _isLoading
                                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                                  : ListView(
                                padding: EdgeInsets.fromLTRB(listPaddingH, contentTopPadding, listPaddingH, 24 * scaleFactor),
                                children: [
                                  // 1. User Info & Overall Rating
                                  _UserInfoCard(
                                      userName: _userName,
                                      userEmail: _userEmail,
                                      avatarUrl: _userAvatar,
                                      userRating: _reputationData?.averageRating ?? 0.0,
                                      totalReviews: _reputationData?.totalFeedbacks ?? 0,
                                      scaleFactor: scaleFactor
                                  ),

                                  SizedBox(height: userCardGap),

                                  // 2. List Group Ratings
                                  if (_reputationData != null && _reputationData!.groups.isNotEmpty)
                                    ..._reputationData!.groups.map((group) => Padding(
                                      padding: EdgeInsets.only(bottom: 16 * scaleFactor),
                                      child: _GroupRatingCard(groupData: group, scaleFactor: scaleFactor),
                                    ))
                                  else
                                    Center(
                                      child: Text(
                                        "Chưa có đánh giá nào",
                                        style: TextStyle(color: Colors.white70, fontSize: 16 * scaleFactor),
                                      ),
                                    )
                                ],
                              ),
                            ),
                          ),

                          // Title UY TÍN
                          Positioned(
                            top: 0, left: 0, right: 0,
                            child: Transform.translate(
                              offset: Offset(0, titleOffset),
                              child: Center(
                                child: Stack(
                                  children: [
                                    Text(
                                      'reputation'.tr(), // "UY TÍN"
                                      style: TextStyle(
                                        fontSize: titleFontSize,
                                        fontFamily: 'Alumni Sans',
                                        fontWeight: FontWeight.w900,
                                        foreground: Paint()..style = PaintingStyle.stroke..strokeWidth = strokeWidth..color = const Color(0xFFF7912D),
                                      ),
                                    ),
                                    Text(
                                      'reputation'.tr(),
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

// --- WIDGETS CON ---

class _UserInfoCard extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String? avatarUrl;
  final double userRating;
  final int totalReviews;
  final double scaleFactor;

  const _UserInfoCard({
    required this.userName,
    required this.userEmail,
    this.avatarUrl,
    required this.userRating,
    required this.totalReviews,
    this.scaleFactor = 1.0
  });

  @override
  Widget build(BuildContext context) {
    final avatarSize = 77.0 * scaleFactor;
    final nameFontSize = 24.0 * scaleFactor;
    final emailFontSize = 16.0 * scaleFactor;
    final starSize = 32.0 * scaleFactor;
    final starContainerHeight = 47.0 * scaleFactor;

    return Column(
      children: [
        Row(
          children: [
            // Avatar
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                image: DecorationImage(
                  image: (avatarUrl != null && avatarUrl!.isNotEmpty)
                      ? NetworkImage(avatarUrl!) as ImageProvider
                      : const AssetImage("assets/images/avatar.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 26 * scaleFactor),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: TextStyle(color: Colors.white, fontSize: nameFontSize, fontFamily: 'Alegreya', fontWeight: FontWeight.w800),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4 * scaleFactor),
                  Text(
                    userEmail,
                    style: TextStyle(color: Colors.white70, fontSize: emailFontSize, fontFamily: 'Alegreya', fontWeight: FontWeight.w500),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "$totalReviews reviews",
                    style: TextStyle(color: Colors.orangeAccent, fontSize: 14 * scaleFactor, fontFamily: 'Alegreya'),
                  )
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: 20 * scaleFactor),

        // Total Rating Bar
        Container(
          height: starContainerHeight,
          decoration: BoxDecoration(
            color: const Color(0xFFB64B12),
            border: Border.all(color: const Color(0xFFB64B12), width: 3),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...List.generate(5, (index) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.0 * scaleFactor),
                  child: Icon(
                    index < userRating.floor()
                        ? Icons.star
                        : (index < userRating ? Icons.star_half : Icons.star_border),
                    color: const Color(0xFFFFD700),
                    size: starSize,
                  ),
                );
              }),
              SizedBox(width: 8 * scaleFactor),
              Text(
                userRating.toStringAsFixed(1),
                style: TextStyle(color: Colors.white, fontSize: 20 * scaleFactor, fontWeight: FontWeight.bold),
              )
            ],
          ),
        ),
      ],
    );
  }
}

class _GroupRatingCard extends StatelessWidget {
  final GroupReputationSummary groupData;
  final double scaleFactor;

  const _GroupRatingCard({required this.groupData, this.scaleFactor = 1.0});

  @override
  Widget build(BuildContext context) {
    final containerHeight = 128.0 * scaleFactor;
    final avatarSize = 105.0 * scaleFactor;
    final nameFontSize = 15.0 * scaleFactor;
    final ratingFontSize = 14.0 * scaleFactor;
    final starSize = 16.0 * scaleFactor;
    final tagFontSize = 12.0 * scaleFactor;
    final tagPaddingH = 10.0 * scaleFactor;

    // 1. Tính điểm trung bình của nhóm này
    double groupRating = 0;
    if (groupData.feedbacks.isNotEmpty) {
      double sum = 0;
      int count = 0;
      for (var fb in groupData.feedbacks) {
        if (fb.rating > 0) {
          sum += fb.rating;
          count++;
        }
      }
      if (count > 0) groupRating = sum / count;
    }

    // 2. Gom tất cả tags từ các feedbacks lại (unique)
    Set<String> uniqueTags = {};
    for (var fb in groupData.feedbacks) {
      uniqueTags.addAll(fb.content);
    }
    List<String> tags = uniqueTags.toList();

    return Container(
      height: containerHeight,
      padding: EdgeInsets.all(10 * scaleFactor),
      decoration: BoxDecoration(
        color: const Color(0xFFDCC9A7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Group avatar
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: (groupData.groupImageUrl != null && groupData.groupImageUrl!.isNotEmpty)
                    ? NetworkImage(groupData.groupImageUrl!) as ImageProvider
                    : const AssetImage("assets/images/default_group.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          SizedBox(width: 14 * scaleFactor),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Group Name
                Text(
                  groupData.groupName,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: nameFontSize,
                    fontFamily: 'Alumni Sans',
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Rating Star
                Row(
                  children: [
                    Text(
                      groupRating.toStringAsFixed(1),
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: ratingFontSize,
                        fontFamily: 'Alumni Sans',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.star, color: const Color(0xFFFFD700), size: starSize),
                    const SizedBox(width: 4),
                    Text(
                      "(${groupData.feedbacks.length})",
                      style: TextStyle(color: Colors.black54, fontSize: 12 * scaleFactor),
                    )
                  ],
                ),

                const SizedBox(height: 8),

                // === TAGS: QUẸT NGANG (SCROLLABLE ROW) ===
                // Thay Wrap bằng SingleChildScrollView + Row
                tags.isEmpty
                    ? Text("Chưa có nhận xét", style: TextStyle(fontStyle: FontStyle.italic, fontSize: tagFontSize, color: Colors.black54))
                    : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(), // Hiệu ứng nảy khi kéo hết
                  child: Row(
                    children: tags.map((tag) {
                      return Container(
                        margin: EdgeInsets.only(right: 6 * scaleFactor), // Khoảng cách giữa các tag
                        padding: EdgeInsets.symmetric(horizontal: tagPaddingH, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tag.tr(), // Dịch tag
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: tagFontSize,
                            fontFamily: 'Alumni Sans',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}