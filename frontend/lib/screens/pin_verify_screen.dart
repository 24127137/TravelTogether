import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/security_service.dart';
import '../services/security_manager.dart';
import '../widgets/pin_grid_dialog.dart';
import 'dart:async';
import 'package:device_info_plus/device_info_plus.dart';

bool _isPinDialogShowing = false;

Future<bool> showPinVerifyDialog(BuildContext context) async {
  if (_isPinDialogShowing) return false;
  _isPinDialogShowing = true;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.92),
    builder: (_) => const PinVerifyDialog(),
  );

  _isPinDialogShowing = false;
  return result ?? false;
}

class PinVerifyDialog extends StatefulWidget {
  const PinVerifyDialog({super.key});

  @override
  State<PinVerifyDialog> createState() => _PinVerifyDialogState();
}

class _PinVerifyDialogState extends State<PinVerifyDialog> with TickerProviderStateMixin {
  final controller = TextEditingController();
  final focusNode = FocusNode();
  String pin = '';
  String message = 'Nhập mã PIN để tiếp tục';
  String lockMessage = '';
  bool isLocked = false;
  bool isVerifying = false;
  bool isSuccess = false;
  bool isDangerPin = false;
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _rotateAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _checkAndStartLockCountdown();

    controller.addListener(() {
      if (isVerifying || isSuccess) return;
      setState(() => pin = controller.text);
      if (pin.length == 6 && !isLocked) {
        Future.delayed(const Duration(milliseconds: 250), _verifyPin);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isLocked && !isSuccess) {
        focusNode.requestFocus();
      }
    });
  }

  Future<void> _checkAndStartLockCountdown() async {
    isLocked = await SecurityManager.instance.isCurrentlyLocked();
    if (isLocked) {
      _startCountdown();
    }
    if (mounted) setState(() {});
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final remaining = await SecurityManager.instance.getRemainingLockSeconds();

      if (remaining == null || remaining <= 0) {
        isLocked = false;
        message = 'Nhập mã PIN để tiếp tục';
        lockMessage = '';
        _timer?.cancel();
        if (mounted) setState(() {});
        return;
      }

      final min = remaining ~/ 60;
      final sec = remaining % 60;
      lockMessage = 'Khóa tạm thời\nCòn $min:${sec.toString().padLeft(2, '0')}';

      if (mounted) setState(() {});
    });
  }

  void _triggerShake() {
    _shakeController.forward(from: 0).then((_) {
      _shakeController.reverse();
    });
  }

  Future<void> _verifyPin() async {
    if (isVerifying) return;

    setState(() {
      isVerifying = true;
      message = 'Đang xác minh...';
    });

    try {
      final location = await _getLocation();
      final res = await SecurityApiService.verifyPin(pin, location: location);

      await SecurityManager.instance.resetWrongAttempt();

      if (mounted) {
        setState(() {
          isVerifying = false;
          isSuccess = true;
          isDangerPin = res.isDanger;
        });

        _animationController.forward();

        await Future.delayed(const Duration(seconds: 3));

        if (mounted) Navigator.of(context).pop(true);
      }
    } on PinVerifyException catch (e) {
      await SecurityManager.instance.incrementWrongAttempt();
      if (mounted) {
        _triggerShake();
        setState(() {
          isVerifying = false;
          message = e.message;
        });
        controller.clear();
        pin = '';
        await _checkAndStartLockCountdown();
      }
    } catch (e) {
      if (mounted) {
        _triggerShake();
        setState(() {
          isVerifying = false;
          message = 'Đã xảy ra lỗi. Vui lòng thử lại';
        });
        controller.clear();
        pin = '';
      }
    }
  }

  Future<String> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Theme.of(context).platform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        return '${androidInfo.brand} ${androidInfo.model}';
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return '${iosInfo.name} ${iosInfo.model}';
      }
      return 'Unknown Device';
    } catch (_) {
      return 'Unknown Device';
    }
  }

  Future<LocationData?> _getLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final deviceInfo = await _getDeviceInfo();

      return LocationData(
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracy: pos.accuracy,
        deviceInfo: deviceInfo,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    _timer?.cancel();
    _animationController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        backgroundColor: const Color(0xFFF5EFE6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: screenWidth * 0.88,
            maxHeight: screenHeight * 0.65,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: isSuccess ? _buildSuccessView() : _buildInputView(),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Padding(
      key: const ValueKey('success'),
      padding: const EdgeInsets.fromLTRB(20, 42, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          ScaleTransition(
            scale: _scaleAnimation,
            child: RotationTransition(
              turns: _rotateAnimation,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            "Xác minh thành công!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'WorkSans',
              color: Color(0xFF2D1409),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Cảm ơn bạn đã xác nhận danh tính",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInputView() {
    return Padding(
      key: const ValueKey('input'),
      padding: const EdgeInsets.fromLTRB(20, 42, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Icon(
            isLocked ? Icons.lock_clock_rounded : Icons.lock_outline_rounded,
            size: 64,
            color: isLocked ? Colors.orange.shade700 : Colors.red.shade700,
          ),
          const SizedBox(height: 18),
          Text(
            isLocked ? "Tạm thời bị khóa" : "Xác minh danh tính",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'WorkSans',
              color: Color(0xFF2D1409),
            ),
          ),
          const SizedBox(height: 12),
          if (isLocked)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                lockMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange.shade800,
                  height: 1.3,
                ),
              ),
            ),
          if (!isLocked) ...[
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: isVerifying
                  ? Row(
                      key: const ValueKey('loading'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          message,
                          style: TextStyle(
                            fontSize: 14.5,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      key: const ValueKey('message'),
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.5,
                        color: message.contains('sai')
                            ? Colors.red.shade700
                            : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            const SizedBox(height: 24),
          ],
          if (isLocked) const SizedBox(height: 32),
          if (!isLocked) ...[
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shakeAnimation.value * 
                    (_shakeController.value < 0.5 ? 1 : -1), 0),
                  child: child,
                );
              },
              child: GestureDetector(
                onTap: () {
                  if (!isVerifying) {
                    focusNode.requestFocus();
                  }
                },
                child: IgnorePointer(
                  ignoring: isVerifying,
                  child: AnimatedOpacity(
                    opacity: isVerifying ? 0.4 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: PinGridDialog(
                      pin: pin,
                      fillColor: const Color(0xFF8A724C),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.number,
            maxLength: 6,
            enabled: !isVerifying && !isSuccess,
            autofocus: true,
            style: const TextStyle(color: Colors.transparent),
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            cursorColor: Colors.transparent,
            showCursor: false,
          ),
        ],
      ),
    );
  }
}