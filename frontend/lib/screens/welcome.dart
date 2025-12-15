// Screen ĐĂNG NHẬP KÝ
import 'package:flutter/material.dart';
<<<<<<< HEAD
=======
import 'package:easy_localization/easy_localization.dart';
>>>>>>> week10
import 'signup.dart';
import 'login.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _fadeTo(BuildContext context, Widget page) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 150),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/login.png',
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.25),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                 children: [
                  Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.cover,
                    width: 125,
                    height: 125,
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: 320,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () => _fadeTo(context, const SignUpScreen()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7.83),
                          side: const BorderSide(
                            color: const Color(0xFF8A724C),
                            width: 1,
                          ),
                        ),
                      ),
<<<<<<< HEAD
                      child: const Text(
                        'Đăng ký',
                        style: TextStyle(
=======
                      child: Text(
                        'signup_title'.tr(),
                        style: const TextStyle(
>>>>>>> week10
                            color: const Color(0xFFDCC9A7),
                            fontSize: 16,
                            fontFamily: 'Alegreya',
                            fontWeight: FontWeight.w600
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: 320,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () => _fadeTo(context, const LoginScreen()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8A724C),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7.83),
                        ),
                      ),
<<<<<<< HEAD
                      child: const Text(
                        'Đăng nhập',
                        style: TextStyle(
=======
                      child: Text(
                        'login_title'.tr(),
                        style: const TextStyle(
>>>>>>> week10
                            fontSize: 16,
                            color: const Color(0xFFF7F3E8),
                            fontFamily: 'Alegreya',
                            fontWeight: FontWeight.w600
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}