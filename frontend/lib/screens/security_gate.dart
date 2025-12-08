import 'package:flutter/material.dart';
import '../services/security_manager.dart';
import '../services/security_service.dart';
import 'pin_verify_screen.dart'; 
import 'security_setup_screen.dart';
import 'dart:async';

class SecurityGate extends StatefulWidget {
  final Widget child;
  const SecurityGate({required this.child, Key? key}) : super(key: key);

  @override
  State<SecurityGate> createState() => _SecurityGateState();
}

class _SecurityGateState extends State<SecurityGate> with WidgetsBindingObserver {
  Timer? _timer;
  bool _isChecking = false;
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkStatus();
    });

    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkStatus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _checkStatus();
      });
    }
  }

  Future<void> _checkStatus() async {
    if (!mounted || _isChecking || _isDialogShowing) {
      debugPrint('⏭️ SecurityGate: Skipped check (mounted: $mounted, checking: $_isChecking, dialog: $_isDialogShowing)');
      return;
    }
    
    _isChecking = true;
    debugPrint('🔍 SecurityGate: Starting security check...');

    try {
      final isLocked = await SecurityManager.instance.isCurrentlyLocked();
      debugPrint('🔒 SecurityGate: Locked status = $isLocked');

      if (isLocked) {
        if (!mounted) return;
        _isDialogShowing = true;
        debugPrint('🚨 SecurityGate: Showing PIN verify dialog (locked)');
        await showPinVerifyDialog(context);
        _isDialogShowing = false;
        _isChecking = false;
        return;
      }

      debugPrint('📡 SecurityGate: Fetching security status from API...');
      final status = await SecurityApiService.getSecurityStatus();
      debugPrint('✅ SecurityGate: Status received - needsSetup: ${status.needsSetup}, isOverdue: ${status.isOverdueStatus}');

      if (!mounted) return;

      if (status.needsSetup) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const SecuritySetupScreen(),
            settings: const RouteSettings(name: '/security-setup'),
          ),
        );
      } else if (status.isOverdueStatus) {
        _isDialogShowing = true;
        await showPinVerifyDialog(context);
        _isDialogShowing = false;
      }
    } catch (e) {

    } finally {
      _isChecking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}