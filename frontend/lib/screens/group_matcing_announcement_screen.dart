import 'package:flutter/material.dart';

class GroupMatchingAnnouncementScreen extends StatelessWidget {
  final String groupName;
  final String groupImageUrl;
  final String billboardBackgroundUrl;
  final VoidCallback? onMessageTap;
  final VoidCallback? onClose;

  const GroupMatchingAnnouncementScreen({
    super.key,
    required this.groupName,
    required this.groupImageUrl,
    this.billboardBackgroundUrl = "https://placehold.co/440x956",
    this.onMessageTap,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(billboardBackgroundUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // Close button
            Positioned(
              left: 26,
              top: 50,
              child: GestureDetector(
                onTap: onClose ?? () => Navigator.of(context).pop(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const ShapeDecoration(
                    color: Color(0xFFF6F6F8),
                    shape: CircleBorder(),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Color(0xFF1B1E28),
                    size: 24,
                  ),
                ),
              ),
            ),

            // Billboard screen with "Vào nhóm thôi" text
            Positioned(
              left: 50,
              top: 120,
              child: Container(
                width: 340,
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5CDB1),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Group image as background
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          groupImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFFE5CDB1),
                              child: const Icon(
                                Icons.group,
                                size: 60,
                                color: Color(0xFFCD7F32),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // Overlay with text
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // "Vào nhóm thôi" text
                    const Positioned(
                      left: 20,
                      top: 20,
                      child: Text(
                        'Vào nhóm thôi!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontFamily: 'DM Serif Display',
                          fontWeight: FontWeight.w600,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 4,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Ground billboard with group invitation message
            Positioned(
              left: 30,
              bottom: 150,
              child: Container(
                width: 380,
                height: 300,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5CDB1),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Group name and invitation text
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: groupName,
                              style: const TextStyle(
                                color: Color(0xFFCD7F32),
                                fontSize: 28,
                                fontFamily: 'Afacad',
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                            const TextSpan(
                              text: ' đã mời bạn vào nhóm',
                              style: TextStyle(
                                color: Color(0xFF2C2C2C),
                                fontSize: 28,
                                fontFamily: 'Afacad',
                                fontWeight: FontWeight.w400,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 32),

                      // Message button
                      GestureDetector(
                        onTap: onMessageTap,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: ShapeDecoration(
                            color: const Color(0xFFDCC9A7),
                            shape: const CircleBorder(),
                            shadows: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.message_rounded,
                            color: Color(0xFFCD7F32),
                            size: 36,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Nhấn để chat với nhóm',
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 14,
                          fontFamily: 'Afacad',
                          fontWeight: FontWeight.w400,
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
    );
  }
}

// Usage example
class GroupAnnouncementWrapper extends StatelessWidget {
  const GroupAnnouncementWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return GroupMatchingAnnouncementScreen(
      groupName: "1 tháng 2 lần",
      groupImageUrl: "https://placehold.co/400x300",
      billboardBackgroundUrl: "https://placehold.co/440x956",
      onMessageTap: () {
        // Navigate to group chat
        print("Navigate to group chat");
      },
      onClose: () {
        Navigator.of(context).pop();
      },
    );
  }
}
