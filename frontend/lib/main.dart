import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

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
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await SecurityManager.instance.init();

  await initializeDateFormatting('vi_VN', null);
  await initializeDateFormatting('en_US', null);

  await Supabase.initialize(
    url: 'https://meuqntvawakdzntewscp.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1ldXFudHZhd2FrZHpudGV3c2NwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE2MzUxOTEsImV4cCI6MjA3NzIxMTE5MX0.w0wtRkKTelo9iHQfLtJ61H5xLCUu2VVMKr8BV4Ljcgw',
  );

  AuthService.onAuthFailure = () {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const FirstScreen()),
      (route) => false,
    );
  };

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
      home: const AuthChecker(), 
      routes: {
        '/security-setup': (_) => const SecuritySetupScreen(),
        '/pin-verify-dialog': (_) => const PinVerifyDialog(), 
      },
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }
}

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8A724C),
      body: Center(
        child: Image.asset('assets/images/logo.png', width: 150, height: 150),
      ),
    );
  }
}