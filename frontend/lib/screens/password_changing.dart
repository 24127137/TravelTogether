import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:confetti/confetti.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../services/auth_service.dart';

class PasswordChangingScreen extends StatefulWidget {
  const PasswordChangingScreen({Key? key}) : super(key: key);

  @override
  State<PasswordChangingScreen> createState() => _PasswordChangingScreenState();
}

enum ButtonState { idle, loading, success }

class _PasswordChangingScreenState extends State<PasswordChangingScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  late AnimationController _animationController;
  late ConfettiController _confettiController;
  ButtonState _buttonState = ButtonState.idle;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  double _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;

    double strength = 0;

    final hasLetters = RegExp(r'[a-zA-Z]').hasMatch(password);
    final hasDigits = RegExp(r'[0-9]').hasMatch(password);
    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasSpecial = RegExp(r'[!@#\$&*~.,;:_^%+-]').hasMatch(password);

    if (password.length < 8 || !hasLetters || !hasDigits) {
      return 0.25;
    }

    strength = 0.5;

    if (hasUpper) strength += 0.25;
    if (hasSpecial) strength += 0.25;

    if (strength > 1) strength = 1;

    return strength;
  }

  Future<void> _handleSave() async {
    if (_buttonState != ButtonState.idle) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final newPass = _newController.text;
    final strength = _calculatePasswordStrength(newPass);

    if (strength < 0.5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mật khẩu mới quá yếu! Gợi ý: Thêm độ dài, chữ hoa, hoặc ký tự đặc biệt.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _buttonState = ButtonState.loading);
    _animationController.repeat();

    try {
      final token = await AuthService.getValidAccessToken();
      
      print('🔐 Đang gọi API change-password...');
      print('📍 URL: ${ApiConfig.baseUrl}/auth/change-password');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'old_password': _currentController.text,
          'new_password': newPass,
        }),
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() => _buttonState = ButtonState.success);
        _animationController.stop();
        _confettiController.play();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đổi mật khẩu thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop();
        });
      } else {
        // Parse error message từ backend
        String errorMsg = 'Không thể đổi mật khẩu';
        
        try {
          final errorData = json.decode(response.body);
          errorMsg = errorData['detail'] ?? errorData['message'] ?? errorMsg;
        } catch (e) {
          errorMsg = response.body;
        }

        throw Exception(errorMsg);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _buttonState = ButtonState.idle);
      _animationController.stop();
      
      // Hiển thị lỗi chi tiết
      String displayError = e.toString().replaceFirst('Exception: ', '');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $displayError'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      
      print('❌ Chi tiết lỗi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const colorBrown = Color(0xFFA15C20);

    return Scaffold(
      backgroundColor: const Color(0xFFB64B12),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top row with back button
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.black,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 0),

                      // Centered security image
                      SizedBox(
                        width: screenWidth * 0.42,
                        height: screenWidth * 0.42,
                        child: Image.asset(
                          'assets/images/security.png',
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) => const SizedBox.shrink(),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Card container with title and inputs
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(0, 0, 0, 0.38),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFEDE2CC), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromRGBO(0, 0, 0, 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Title
                              Text(
                                'change_password_title'.tr(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Alumni Sans',
                                ),
                              ),

                              const SizedBox(height: 18),

                              // Current password
                              _buildLabel('current_password'.tr()),
                              const SizedBox(height: 8),
                              _buildPasswordField(
                                controller: _currentController,
                                hintText: 'enter_current_password'.tr(),
                                obscure: _obscureCurrent,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscureCurrent ? Icons.visibility_off : Icons.visibility,
                                    color: colorBrown,
                                  ),
                                  onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                                ),
                              ),

                              const SizedBox(height: 14),

                              // New password
                              _buildLabel('new_password'.tr()),
                              const SizedBox(height: 8),
                              _buildPasswordField(
                                controller: _newController,
                                hintText: 'enter_new_password'.tr(),
                                obscure: _obscureNew,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscureNew ? Icons.visibility_off : Icons.visibility,
                                    color: colorBrown,
                                  ),
                                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'password_required'.tr();
                                  if (v.length < 6) return 'password_min_length'.tr();
                                  return null;
                                },
                              ),

                              const SizedBox(height: 14),

                              // Confirm password
                              _buildLabel('confirm_password'.tr()),
                              const SizedBox(height: 8),
                              _buildPasswordField(
                                controller: _confirmController,
                                hintText: 'enter_confirm_password'.tr(),
                                obscure: _obscureConfirm,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                                    color: colorBrown,
                                  ),
                                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'confirm_password'.tr();
                                  if (v != _newController.text) return 'pin_mismatch'.tr();
                                  return null;
                                },
                              ),

                              const SizedBox(height: 20),

                              // Animated confirm button
                              Center(child: _buildSaveButton()),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            // Confetti overlay
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.02,
                numberOfParticles: 20,
                maxBlastForce: 100,
                minBlastForce: 60,
                gravity: 0.3,
                shouldLoop: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: 'Alegreya',
        ),
      );

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscure,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: const Color(0xFFEDE2CC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFA15C20), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB64B12), width: 2),
        ),
        suffixIcon: suffix,
      ),
    );
  }

  Widget _buildSaveButton() {
    final bool loading = _buttonState == ButtonState.loading;
    final bool success = _buttonState == ButtonState.success;

    return GestureDetector(
      onTap: _handleSave,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: loading ? 80 : 250,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: success
                ? [Colors.green.shade400, Colors.green.shade700]
                : [const Color(0xFFB64B12), const Color(0xFFCD7F32)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: success ? Color.fromRGBO(0, 128, 0, 0.4) : const Color.fromRGBO(205, 127, 50, 0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(child: _buildSaveButtonContent()),
      ),
    );
  }

  Widget _buildSaveButtonContent() {
    switch (_buttonState) {
      case ButtonState.idle:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.save, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'save'.tr(),
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Alegreya'),
            ),
          ],
        );

      case ButtonState.loading:
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final delay = index * 0.2;
                final value = (_animationController.value - delay).clamp(0.0, 1.0);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Transform.translate(
                    offset: Offset(0, -10 * (0.5 - (value - 0.5).abs()) * 2),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        );

      case ButtonState.success:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Text(
              'success'.tr(),
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Alegreya'),
            ),
          ],
        );
    }
  }
}