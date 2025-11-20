import 'package:flutter/material.dart';

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
        groupAvatar: 'https://placehold.co/64x64',
        rating: 4.5,
        keywords: ['Friendly', 'Punctual', 'Helpful'],
      ),
      GroupRating(
        groupName: 'TÊN NHÓM 2',
        groupAvatar: 'https://placehold.co/64x64',
        rating: 4.8,
        keywords: ['Professional', 'Fun'],
      ),
      GroupRating(
        groupName: 'TÊN NHÓM 3',
        groupAvatar: 'https://placehold.co/64x64',
        rating: 4.2,
        keywords: ['Organized', 'Friendly'],
      ),
      GroupRating(
        groupName: 'TÊN NHÓM 4',
        groupAvatar: 'https://placehold.co/64x64',
        rating: 4.7,
        keywords: ['Reliable', 'Enthusiastic'],
      ),
    ];

    return Scaffold(
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
            child: Column(
              children: [
                // Header
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
                    ],
                  ),
                ),

                // Title
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    'UY TÍN',
                    style: TextStyle(
                      color: Color(0xFFF49B57),
                      fontSize: 96,
                      fontFamily: 'Alumni Sans',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Content card
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 19),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.40),
                      border: Border.all(color: const Color(0xFFEDE2CC), width: 6),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        // User info section
                        _UserInfoCard(userRating: userRating),

                        const SizedBox(height: 40),

                        // Group ratings list
                        ...groupRatings.map((rating) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _GroupRatingCard(groupRating: rating),
                        )),
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

// User info card with avatar, name, email and star rating
class _UserInfoCard extends StatelessWidget {
  final double userRating;

  const _UserInfoCard({required this.userRating});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar and user details
        Row(
          children: [
            // Avatar
            Container(
              width: 77,
              height: 77,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage("https://placehold.co/77x77"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 26),
            // Name and email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Nguyễn Khánh Toàn',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontFamily: 'Alegreya',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'abc@gmail.com',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Alegreya',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Star rating container
        Container(
          height: 47,
          decoration: BoxDecoration(
            color: const Color(0xFFB64B12),
            border: Border.all(color: const Color(0xFFB64B12), width: 3),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  index < userRating.floor()
                      ? Icons.star
                      : (index < userRating ? Icons.star_half : Icons.star_border),
                  color: const Color(0xFFFFD700),
                  size: 32,
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

  const _GroupRatingCard({required this.groupRating});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFDCC9A7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Group avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: NetworkImage(groupRating.groupAvatar),
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Group info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Group name
                Text(
                  groupRating.groupName,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
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
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontFamily: 'Alumni Sans',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.star,
                      color: Color(0xFFFFD700),
                      size: 14,
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Keywords tags
                Wrap(
                  spacing: 6,
                  children: groupRating.keywords.map((keyword) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        keyword,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
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
