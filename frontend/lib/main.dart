import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/onboarding.dart';
import 'screens/first_of_all.dart';
import 'screens/main_app_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart'; // Import notification service

// Global Navigator Key để navigate từ notification
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Initialize date formatting for locales
  await initializeDateFormatting('vi_VN', null);
  await initializeDateFormatting('en_US', null);

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://meuqntvawakdzntewscp.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1ldXFudHZhd2FrZHpudGV3c2NwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE2MzUxOTEsImV4cCI6MjA3NzIxMTE5MX0.w0wtRkKTelo9iHQfLtJ61H5xLCUu2VVMKr8BV4Ljcgw',
  );

  // Set up auth failure callback to navigate to onboarding
  AuthService.onAuthFailure = () {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (route) => false,
    );
  };

  // Initialize Notification Service
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
      navigatorKey: navigatorKey,
      home: const SplashScreen(), 
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }
}

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
    await Future.delayed(const Duration(milliseconds: 400));

    try {
      final token = await AuthService.getValidAccessToken();

      if (token != null) {
        _go(MainAppScreen(accessToken: token));
        return;
      }

      await AuthService.clearTokens();
      _go(const FirstScreen());

    } catch (e, st) {
      debugPrint("Startup error: $e\n$st");

      _go(const FirstScreen());
    }
  }

  void _go(Widget page) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8A724C),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 150,
              height: 150,
            ),
          ],
        ),
      ),
    );
  }
}