import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'messages_screen.dart'; // Import màn hình tin nhắn

class GroupMatchingAnnouncementScreen extends StatefulWidget {
  final String groupName; // Tên nhóm động
  final String? groupId;
  final VoidCallback? onBack;
  final VoidCallback? onGoToChat;

  const GroupMatchingAnnouncementScreen({
    Key? key,
    required this.groupName, // Bắt buộc truyền tên nhóm
    this.groupId,
    this.onBack,
    this.onGoToChat,
  }) : super(key: key);

  @override
  State<GroupMatchingAnnouncementScreen> createState() => _GroupMatchingAnnouncementScreenState();
}

class _GroupMatchingAnnouncementScreenState extends State<GroupMatchingAnnouncementScreen> {
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: 440, // Giữ nguyên kích thước gốc của bạn
        height: 956,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(color: Color(0xFF653516)),
        child: Stack(
          children: [
            // Confetti
            Positioned.fill(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  emissionFrequency: 0.05,
                  numberOfParticles: 30,
                  gravity: 0.25,
                  shouldLoop: false,
                  colors: const [
                    Color(0xFFDCC9A7),
                    Color(0xFF663517),
                    Color(0xFFB64B12),
                    Color(0xFFEDE2CC),
                  ],
                ),
              ),
            ),

            // Text "VÀO THÔI!" - Giữ nguyên tọa độ gốc
            Positioned(
              left: 0,
              top: 80,
              child: SizedBox(
                width: 440,
                child: Text(
                  'VÀO THÔI!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 95,
                    fontFamily: 'Alumni Sans',
                    fontWeight: FontWeight.w700,
                    height: 0.96,
                    letterSpacing: -6.80,
                  ),
                ),
              ),
            ),

            // Background Overlay - Giữ nguyên tọa độ gốc
            Positioned(
              left: -100,
              right: -60,
              bottom: 0,
              child: Container(
                width: 419,
                height: 840,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/overlay.png"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            // Text Thông báo (Tên nhóm + đã mời bạn...) - Giữ nguyên tọa độ gốc
            Positioned(
              left: 22,
              top: 190,
              child: SizedBox(
                width: 194, // Giữ nguyên width gốc để text xuống dòng đúng ý bạn
                height: 214,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: widget.groupName, // <--- CHỈ THAY ĐỔI CHỖ NÀY
                        style: TextStyle(
                          color: const Color(0xFFDCC9A7),
                          fontSize: 40,
                          fontStyle: FontStyle.italic,
                          fontFamily: 'Alumni Sans',
                          fontWeight: FontWeight.w700,
                          overflow: TextOverflow.visible,
                          height: 0.96,
                          letterSpacing: -1.60,
                        ),
                      ),
                      TextSpan(
                        text: ' ',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 40,
                          fontFamily: 'Afacad',
                          fontWeight: FontWeight.w400,
                          height: 0.96,
                          letterSpacing: -1.60,
                        ),
                      ),
                      TextSpan(
                        text: 'đã mời bạn vào nhóm.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontFamily: 'Afacad',
                          fontWeight: FontWeight.w400,
                          height: 0.96,
                          letterSpacing: -1.60,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Icon Chat Bubble - Giữ nguyên tọa độ gốc + Thêm sự kiện Click
            Positioned(
              left: 60,
              top: 380,
              child: GestureDetector( // <--- Thêm GestureDetector để bắt sự kiện
                onTap: () {
                  // SỬA: Gọi callback được truyền từ HomePage xuống
                  if (widget.onGoToChat != null) {
                    widget.onGoToChat!();
                  }
                },
                child: Container(
                  width: 82,
                  height: 82,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFDCC9A7),
                    shape: OvalBorder(
                      side: BorderSide(
                        width: 1,
                        color: Color(0xFFC56734),
                      ),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.chat_bubble,
                      color: Color(0xFF663517),
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),

            // Back Button - Giữ nguyên tọa độ gốc
            Positioned(
              top: 22,
              left: 12,
              child: GestureDetector(
                onTap: () {
                  if (widget.onBack != null) {
                    widget.onBack!();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.black,
                    size: 20,
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