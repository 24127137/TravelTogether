import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/feedback_service.dart';
import '../models/feedback_models.dart';
import '../services/user_service.dart';
import '../services/group_service.dart'; // Import GroupService để lấy ảnh
import '../services/auth_service.dart';  // Import AuthService để lấy token

class ReputationScreen extends StatefulWidget {
  const ReputationScreen({super.key});

  @override
  State<ReputationScreen> createState() => _ReputationScreenState();
}

class _ReputationScreenState extends State<ReputationScreen> {
  final FeedbackService _feedbackService = FeedbackService();
  final UserService _userService = UserService();

  bool _isLoading = true;
  MyReputationResponse? _reputationData;

  // Biến lưu thông tin User
  String _userName = "User";
  String _userEmail = "";
  String? _userAvatar;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = await AuthService.getValidAccessToken(); // Lấy token chuẩn

    if (token != null) {
      // Gọi song song 2 API: Lấy uy tín & Lấy thông tin cá nhân
      final results = await Future.wait([
        _feedbackService.getMyReputation(token), // index 0
        _userService.getUserProfile(),           // index 1
      ]);

      final reputationData = results[0] as MyReputationResponse?;
      final profileData = results[1] as Map<String, dynamic>?;

      if (mounted) {
        setState(() {
          _reputationData = reputationData;

          // Cập nhật thông tin User từ API
          if (profileData != null) {
            _userName = profileData['fullname'] ?? "User";
            _userEmail = profileData['email'] ?? "";
            _userAvatar = profileData['avatar_url'];

            // Cache lại để dùng cho lần sau
            prefs.setString('user_fullname', _userName);
            if (_userAvatar != null) {
              prefs.setString('user_avatar', _userAvatar!);
            }
          } else {
            // Fallback: Dùng cache cũ nếu API lỗi
            _userName = prefs.getString('user_fullname') ?? "User";
            _userEmail = prefs.getString('user_email') ?? "";
            _userAvatar = prefs.getString('user_avatar');
          }

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
          // Background
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
                    // Header (Back Button)
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
                          // Card Nội dung chính
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
                                  // 1. Thông tin User & Rating tổng
                                  _UserInfoCard(
                                      userName: _userName,
                                      userEmail: _userEmail,
                                      avatarUrl: _userAvatar,
                                      userRating: _reputationData?.averageRating ?? 0.0,
                                      totalReviews: _reputationData?.totalFeedbacks ?? 0,
                                      scaleFactor: scaleFactor
                                  ),

                                  SizedBox(height: userCardGap),

                                  // 2. Danh sách đánh giá các nhóm
                                  if (_reputationData != null && _reputationData!.groups.isNotEmpty)
                                    ..._reputationData!.groups.map((group) => Padding(
                                      padding: EdgeInsets.only(bottom: 16 * scaleFactor),
                                      // Sử dụng Widget mới có khả năng tự load ảnh
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

                          // Tiêu đề "UY TÍN" (Reputation)
                          Positioned(
                            top: 0, left: 0, right: 0,
                            child: Transform.translate(
                              offset: Offset(0, titleOffset),
                              child: Center(
                                child: Stack(
                                  children: [
                                    Text(
                                      'reputation'.tr(),
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

// Widget hiển thị thông tin User (Stateless)
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

    return Column(
        children: [
          Row(
              children: [
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
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: TextStyle(color: Colors.white, fontSize: 24 * scaleFactor, fontFamily: 'Alegreya', fontWeight: FontWeight.w800),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4 * scaleFactor),
                          Text(
                            userEmail,
                            style: TextStyle(color: Colors.white70, fontSize: 16 * scaleFactor, fontFamily: 'Alegreya', fontWeight: FontWeight.w500),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "$totalReviews reviews",
                            style: TextStyle(color: Colors.orangeAccent, fontSize: 14 * scaleFactor, fontFamily: 'Alegreya'),
                          )
                        ]
                    )
                )
              ]
          ),
          SizedBox(height: 20 * scaleFactor),
          // Total Rating Bar
          Container(
            height: 47.0 * scaleFactor,
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
                      size: 32.0 * scaleFactor,
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
        ]
    );
  }
}

// Widget hiển thị từng Nhóm đánh giá (Stateful để tự load ảnh)
class _GroupRatingCard extends StatefulWidget {
  final GroupReputationSummary groupData;
  final double scaleFactor;

  const _GroupRatingCard({required this.groupData, this.scaleFactor = 1.0});

  @override
  State<_GroupRatingCard> createState() => _GroupRatingCardState();
}

class _GroupRatingCardState extends State<_GroupRatingCard> {
  final GroupService _groupService = GroupService();
  String? _fetchedImageUrl; // Biến chứa ảnh lấy từ API phụ

  @override
  void initState() {
    super.initState();
    // Nếu model chính chưa có ảnh -> Gọi API lấy bù
    if (widget.groupData.groupImageUrl == null || widget.groupData.groupImageUrl!.isEmpty) {
      _loadGroupImage();
    }
  }

  Future<void> _loadGroupImage() async {
    String? token = await AuthService.getValidAccessToken();
    if (token != null) {
      try {
        final data = await _groupService.getGroupPlanById(token, widget.groupData.groupId);
        if (data != null && data['group_image_url'] != null && mounted) {
          setState(() {
            _fetchedImageUrl = data['group_image_url'];
          });
        }
      } catch (_) {
        // Lỗi thì thôi, dùng ảnh mặc định
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupData = widget.groupData;
    final scaleFactor = widget.scaleFactor;

    // Ưu tiên: Ảnh lấy được > Ảnh có sẵn > Mặc định
    final displayImage = _fetchedImageUrl ?? groupData.groupImageUrl;
    final hasImage = displayImage != null && displayImage.isNotEmpty;

    final containerHeight = 128.0 * scaleFactor;
    final avatarSize = 105.0 * scaleFactor;
    final nameFontSize = 15.0 * scaleFactor;
    final ratingFontSize = 14.0 * scaleFactor;
    final starSize = 16.0 * scaleFactor;
    final tagFontSize = 12.0 * scaleFactor;
    final tagPaddingH = 10.0 * scaleFactor;

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

    Set<String> uniqueTags = {};
    for (var fb in groupData.feedbacks) {
      uniqueTags.addAll(fb.content);
    }
    List<String> tags = uniqueTags.toList();

    return Container(
      height: containerHeight,
      padding: EdgeInsets.all(10 * scaleFactor),
      decoration: BoxDecoration(
        color: const Color(0xFFEFE7DA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFB29079),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Ảnh nhóm
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: hasImage
                    ? NetworkImage(displayImage!) as ImageProvider
                    : const AssetImage("assets/images/default_group.jpg"),
                fit: BoxFit.cover,
                onError: (_, __) {}, // Bắt lỗi load ảnh để không crash
              ),
            ),
          ),

          SizedBox(width: 14 * scaleFactor),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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

                tags.isEmpty
                    ? Text("Chưa có nhận xét", style: TextStyle(fontStyle: FontStyle.italic, fontSize: tagFontSize, color: Colors.black54))
                    : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: tags.map((tag) {
                      return Container(
                        margin: EdgeInsets.only(right: 6 * scaleFactor),
                        padding: EdgeInsets.symmetric(horizontal: tagPaddingH, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tag.tr(), // Dịch tag nếu cần
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