import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
<<<<<<< HEAD

import 'screens/onboarding.dart';
import 'screens/first_of_all.dart';
import 'screens/main_app_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart'; // === THÊM MỚI: Import notification service ===

// === THÊM MỚI: Global Navigator Key để navigate từ notification ===
=======
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screens/first_of_all.dart';
import 'screens/main_app_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/security_manager.dart';
import 'services/security_service.dart';
import 'screens/pin_verify_screen.dart';      
import 'screens/security_setup_screen.dart';  
import 'screens/security_gate.dart';
import 'dart:async';

// Global Navigator Key
>>>>>>> week10
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
<<<<<<< HEAD

  // Initialize date formatting for locales
  await initializeDateFormatting('vi_VN', null);
  await initializeDateFormatting('en_US', null);

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://meuqntvawakdzntewscp.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1ldXFudHZhd2FrZHpudGV3c2NwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE2MzUxOTEsImV4cCI6MjA3NzIxMTE5MX0.w0wtRkKTelo9iHQfLtJ61H5xLCUu2VVMKr8BV4Ljcgw',
  );

  // === THÊM MỚI: Initialize Notification Service ===
=======
  await SecurityManager.instance.init();

  await initializeDateFormatting('vi_VN', null);
  await initializeDateFormatting('en_US', null);

  try {
    await dotenv.load(fileName: ".env");
    debugPrint('✅ Loaded .env file successfully');
  } catch (e) {
    debugPrint('⚠️ Warning: Could not load .env file: $e');
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  AuthService.onAuthFailure = () {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const FirstScreen()),
      (route) => false,
    );
  };

>>>>>>> week10
  try {
    await NotificationService().initialize();
    debugPrint('✅ Notification service initialized successfully');
  } catch (e) {
    debugPrint('❌ Error initializing notification service: $e');
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('vi')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('vi'),
      useOnlyLangCode: true,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
<<<<<<< HEAD
      navigatorKey: navigatorKey, // === THÊM MỚI: Global navigator key ===
      home: const SplashScreen(), // === SỬA: Dùng SplashScreen để check token ===
=======
      navigatorKey: navigatorKey,
      home: const AuthChecker(), 
      routes: {
        '/security-setup': (_) => const SecuritySetupScreen(),
        '/pin-verify-dialog': (_) => const PinVerifyDialog(), 
      },
>>>>>>> week10
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }
}

<<<<<<< HEAD
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// Add a small TestMode switch so you can control startup behavior during development.
enum TestMode { full, bypassMain, onboarding }

class _SplashScreenState extends State<SplashScreen> {
  // Set desired mode here:
  // - TestMode.full: run the original flow (check onboarding flag, validate token)
  // - TestMode.bypassMain: go straight to MainAppScreen with a test token
  // - TestMode.onboarding: go straight to OnboardingScreen
  static const TestMode _testMode = TestMode.full;

  @override
  void initState() {
    super.initState();
    _initFlow();
  }

  Future<void> _initFlow() async {
    await Future.delayed(const Duration(milliseconds: 500));

    switch (_testMode) {
      case TestMode.bypassMain:
        _go(MainAppScreen(accessToken: 'test_token'));
        return;
      case TestMode.onboarding:
        _go(const OnboardingScreen());
        return;
      case TestMode.full:
      // continue to the normal flow below
        break;
    }

    // Normal app startup flow: check onboarding flag and try to obtain a valid token
    try {
      final prefs = await SharedPreferences.getInstance();
      final onboardingSeen = prefs.getBool('hasSeenOnboarding') ?? false;

      if (!onboardingSeen) {
        _go(const OnboardingScreen());
        return;
      }

      final token = await AuthService.getValidAccessToken();

      if (token != null) {
        _go(MainAppScreen(accessToken: token));
      } else {
        await AuthService.clearTokens();
        _go(const OnboardingScreen());
      }
    } catch (e, st) {
      // If anything fails during startup, log and send user to onboarding for a clean start.
      // This prevents crashes during development when services aren't available.
      // ignore: avoid_print
      print('Startup flow failed: $e\n$st');
      _go(const OnboardingScreen());
    }
  }

  void _go(Widget page) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => page),
    );
=======
class AuthChecker extends StatefulWidget {
  const AuthChecker({Key? key}) : super(key: key);

  @override
  State<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> with WidgetsBindingObserver {
  Timer? _securityTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _navigateBasedOnAuth(); 
  }

  @override
  void dispose() {
    _securityTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSecurityImmediately();
    }
  }

  Future<void> _checkSecurityImmediately() async {
    if (!mounted) return;

    try {
      final currentContext = navigatorKey.currentContext;
      if (currentContext == null) return;

      if (await SecurityManager.instance.isCurrentlyLocked()) {
        await showPinVerifyDialog(currentContext);
        return;
      }

      final status = await SecurityApiService.getSecurityStatus();

      if (status.needsSetup) {
        navigatorKey.currentState?.pushNamed('/security-setup');
      } else if (status.isOverdueStatus) {
        await showPinVerifyDialog(currentContext);
      }
    } catch (e) {
      debugPrint('❌ AuthChecker: Error checking security: $e');
    }
  }

  Future<void> _navigateBasedOnAuth() async {
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final token = await AuthService.getValidAccessToken();

      if (token != null) {
        await _checkSecurityImmediately();
        
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SecurityGate( 
              child: MainAppScreen(accessToken: token),
            ),
          ),
        );
        return;
      }

      await AuthService.clearTokens();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FirstScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FirstScreen()),
      );
    }
>>>>>>> week10
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8A724C),
      body: Center(
<<<<<<< HEAD
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 150,
              height: 150,
            ), // đến đây thôi
          ],
        ),
=======
        child: Image.asset('assets/images/logo.png', width: 150, height: 150),
>>>>>>> week10
      ),
    );
  }
}