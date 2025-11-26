// dart
import 'package:flutter/material.dart';
import 'onboarding.dart';
import 'welcome.dart';

class FirstScreen extends StatelessWidget {
  const FirstScreen({super.key});

  static const Color primaryBrown = Color(0xFF8A724C);
  static const Color accentSand = Color(0xFFDCC9A7);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final double textToButtonSpacing = screenHeight * 0.02;
    final double bottomPadding = screenHeight * 0.03;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/first.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.25)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // align left
                children: [
                  // Title that wraps to next line when too wide
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'TRAVEL TOGETHER',
                      style: TextStyle(
                        color: accentSand,
                        fontSize: screenWidth * 0.16, // large but will wrap
                        fontFamily: 'Antonio',
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      textAlign: TextAlign.left,
                    ),
                  ),

                  Expanded(child: Container()),

                  // Paragraph aligned to same left margin as button
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Hãy lên \ný tưởng cho\n',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.055,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w400,
                            height: 1.25,
                          ),
                        ),
                        TextSpan(
                          text: 'Kỳ nghỉ của bạn',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.09,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w500,
                            height: 1.13,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.left,
                  ),

                  SizedBox(height: textToButtonSpacing),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBrown,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Khám phá',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontFamily: 'Alegreya',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.015),

                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: accentSand,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                        child: const Text(
                          'Bỏ qua',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: bottomPadding),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
