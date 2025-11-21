import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

// Data models
class GroupRating {
  final String groupName;
  final String groupAvatar;
  final double rating;
  final List<String> keywords;

  GroupRating({
    required this.groupName,
    required this.groupAvatar,
    required this.rating,
    required this.keywords,
  });
}

class ReputationScreen extends StatelessWidget {
  const ReputationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample data
    final userRating = 4.5;
    final groupRatings = [
      GroupRating(
        groupName: 'TÊN NHÓM 1',
        groupAvatar: 'assets/images/dalat.jpg',
        rating: 4.5,
        keywords: ['Friendly', 'Punctual', 'Helpful'],
      ),
      GroupRating(
        groupName: 'TÊN NHÓM 2',
        groupAvatar: 'assets/images/sapa.jpg',
        rating: 4.8,
        keywords: ['Professional', 'Fun'],
      ),
      GroupRating(
        groupName: 'TÊN NHÓM 3',
        groupAvatar: 'assets/images/saigon.jpg',
        rating: 4.2,
        keywords: ['Organized', 'Friendly'],
      ),
      GroupRating(
        groupName: 'TÊN NHÓM 4',
        groupAvatar: 'assets/images/halong.jpg',
        rating: 4.7,
        keywords: ['Reliable', 'Enthusiastic'],
      ),
    ];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Background with decorative stripes
          Container(
            color: const Color(0xFFB64B12),
            child: Column(
              children: [
                // Decorative stripes
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

          // Main content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Responsive scaling dựa trên chiều cao màn hình
                final screenHeight = constraints.maxHeight;

                // Scale factor: baseline 800px = 1.0, 600px = 0.75
                final scaleFactor = (screenHeight / 800).clamp(0.65, 1.0);

                // Language scale: shorten big title in English because English word can be longer
                final langScale = context.locale.languageCode == 'en' ? 0.65 : 1.0;

                // Tất cả sizes scale theo tỷ lệ
                final titleFontSize = 96.0 * scaleFactor * langScale;
                final titleOffset = -55.0 * scaleFactor;
                final contentTopPosition = 50.0 * scaleFactor;
                final contentTopPadding = 60.0 * scaleFactor;
                final headerVerticalPadding = 15.0 * scaleFactor;
                final bottomPadding = 20.0 * scaleFactor;
                final listPaddingH = 24.0 * scaleFactor;
                final listPaddingBottom = 24.0 * scaleFactor;
                final itemSpacing = 16.0 * scaleFactor;
                final userCardGap = 40.0 * scaleFactor;
                final strokeWidth = 5.0 * scaleFactor;

                return Column(
                  children: [
                    // Header với nút back
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
                        ],
                      ),
                    ),

                    SizedBox(height: 10 * scaleFactor),

                    // Stack để đặt chữ UY TÍN chồng lên viền khung (giống GÓP Ý)
                    Expanded(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Content card - bắt đầu từ giữa chữ UY TÍN
                          Positioned(
                            top: contentTopPosition,
                            left: 20,
                            right: 20,
                            bottom: bottomPadding,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.27),
                                border: Border.all(color: const Color(0xFFEDE2CC), width: 6),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: ListView(
                                padding: EdgeInsets.fromLTRB(
                                  listPaddingH,
                                  contentTopPadding,
                                  listPaddingH,
                                  listPaddingBottom
                                ),
                                children: [
                                  // User info section
                                  _UserInfoCard(userRating: userRating, scaleFactor: scaleFactor),

                                  SizedBox(height: userCardGap),

                                  // Group ratings list
                                  ...groupRatings.map((rating) => Padding(
                                    padding: EdgeInsets.only(bottom: itemSpacing),
                                    child: _GroupRatingCard(groupRating: rating, scaleFactor: scaleFactor),
                                  )),
                                ],
                              ),
                            ),
                          ),

                          // Chữ UY TÍN với viền màu F7912D (giống GÓP Ý)
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
                                      'reputation'.tr(),
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

// User info card with avatar, name, email and star rating
class _UserInfoCard extends StatelessWidget {
  final double userRating;
  final double scaleFactor;

  const _UserInfoCard({required this.userRating, this.scaleFactor = 1.0});

  @override
  Widget build(BuildContext context) {
    // Tất cả sizes scale theo tỷ lệ màn hình
    final avatarSize = 77.0 * scaleFactor;
    final nameFontSize = 24.0 * scaleFactor;
    final emailFontSize = 16.0 * scaleFactor;
    final starSize = 32.0 * scaleFactor;
    final starContainerHeight = 47.0 * scaleFactor;
    final starSpacing = 6.0 * scaleFactor;
    final spaceBetween = 26.0 * scaleFactor;
    final verticalGap = 20.0 * scaleFactor;
    final nameEmailGap = 4.0 * scaleFactor;

    return Column(
      children: [
        // Avatar and user details
        Row(
          children: [
            // Avatar
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage("assets/images/avatar.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: spaceBetween),
            // Name and email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nguyễn Khánh Toàn',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: nameFontSize,
                      fontFamily: 'Alegreya',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: nameEmailGap),
                  Text(
                    'abc@gmail.com',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: emailFontSize,
                      fontFamily: 'Alegreya',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: verticalGap),

        // Star rating container
        Container(
          height: starContainerHeight,
          decoration: BoxDecoration(
            color: const Color(0xFFB64B12),
            border: Border.all(color: const Color(0xFFB64B12), width: 3),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: starSpacing),
                child: Icon(
                  index < userRating.floor()
                      ? Icons.star
                      : (index < userRating ? Icons.star_half : Icons.star_border),
                  color: const Color(0xFFFFD700),
                  size: starSize,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// Group rating card with avatar, name, rating and keywords
class _GroupRatingCard extends StatelessWidget {
  final GroupRating groupRating;
  final double scaleFactor;

  const _GroupRatingCard({required this.groupRating, this.scaleFactor = 1.0});

  @override
  Widget build(BuildContext context) {
    // Tất cả sizes scale theo tỷ lệ màn hình
    final containerHeight = 128.0 * scaleFactor;
    final avatarSize = 105.0 * scaleFactor;
    final nameFontSize = 15.0 * scaleFactor;
    final ratingFontSize = 12.0 * scaleFactor;
    final starSize = 14.0 * scaleFactor;
    final tagFontSize = 10.0 * scaleFactor;
    final tagPaddingH = 8.0 * scaleFactor;
    final cardPadding = 10.0 * scaleFactor;
    final spaceBetween = 14.0 * scaleFactor;

    return Container(
      height: containerHeight,
      padding: EdgeInsets.all(cardPadding),
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
                image: AssetImage(groupRating.groupAvatar),
                fit: BoxFit.cover,
              ),
            ),
          ),

          SizedBox(width: spaceBetween),

          // Group info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Group name
                Text(
                  groupRating.groupName,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: nameFontSize,
                    fontFamily: 'Alumni Sans',
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 2),

                // Rating with star
                Row(
                  children: [
                    Text(
                      groupRating.rating.toStringAsFixed(1),
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: ratingFontSize,
                        fontFamily: 'Alumni Sans',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.star,
                      color: const Color(0xFFFFD700),
                      size: starSize,
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Keywords tags
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: groupRating.keywords.map((keyword) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: tagPaddingH, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        keyword.tr(),
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: tagFontSize,
                          fontFamily: 'Alumni Sans',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}