  // dart
  import 'package:flutter/material.dart';
  import 'package:confetti/confetti.dart';

  class GroupMatchingAnnouncementScreen extends StatefulWidget {
    final String groupName;
    final String? groupId;
    final VoidCallback? onBack;

    const GroupMatchingAnnouncementScreen({
      Key? key,
      required this.groupName,
      this.groupId,
      this.onBack,
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
          width: 440,
          height: 956,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(color: Color(0xFF653516)),
          child: Stack(
            children: [
              // Confetti positioned at top center, explosive style
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
              Positioned(
                left: 22,
                top: 190,
                child: SizedBox(
                  width: 194,
                  height: 214,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '1 tháng 2 lần',
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

              Positioned(
                left: 60,
                top: 380,
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

    /* unused functions
    Widget _buildChatButton(BuildContext context) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToGroupChat(context),
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFDCC9A7),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFC56734),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.chat_bubble,
              color: Color(0xFF663517),
              size: 32,
            ),
          ),
        ),
      );
    }

    void _navigateToGroupChat(BuildContext context) {
      if (widget.groupId == null) {
        debugPrint('Group ID is null, cannot navigate to chat');
        return;
      }
      debugPrint('Navigating to chat for group: ${widget.groupId}');
    } */
  }