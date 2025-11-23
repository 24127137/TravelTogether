import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:easy_localization/easy_localization.dart';


// Password changing screen used from Settings
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

  Future<void> _handleSave() async {
    if (_buttonState != ButtonState.idle) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _buttonState = ButtonState.loading);
    _animationController.repeat();

    // Simulate network / processing
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() => _buttonState = ButtonState.success);
    _animationController.stop();
    _confettiController.play();

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mật khẩu đã được thay đổi')));

    // close shortly after success so user sees feedback
    Future.delayed(const Duration(seconds: 2), () { if (mounted) Navigator.of(context).pop(); });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Colors consistent with app theme used elsewhere
    const colorBrown = Color(0xFFA15C20);
    const colorAction = Color(0xFFB64B12);

    return Scaffold(
      backgroundColor: const Color(0xFFB64B12),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(), // fixed screen as requested
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
                                'Đổi mật khẩu',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 18),

                              // Current password
                              _buildLabel('Mật khẩu hiện tại'),
                              const SizedBox(height: 8),
                              _buildPasswordField(
                                controller: _currentController,
                                hintText: 'Nhập mật khẩu hiện tại',
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
                              _buildLabel('Mật khẩu mới'),
                              const SizedBox(height: 8),
                              _buildPasswordField(
                                controller: _newController,
                                hintText: 'Nhập mật khẩu mới',
                                obscure: _obscureNew,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscureNew ? Icons.visibility_off : Icons.visibility,
                                    color: colorBrown,
                                  ),
                                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu mới';
                                  if (v.length < 6) return 'Mật khẩu phải >= 6 ký tự';
                                  return null;
                                },
                              ),

                              const SizedBox(height: 14),

                              // Confirm password
                              _buildLabel('Xác nhận mật khẩu'),
                              const SizedBox(height: 8),
                              _buildPasswordField(
                                controller: _confirmController,
                                hintText: 'Nhập lại mật khẩu mới',
                                obscure: _obscureConfirm,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                                    color: colorBrown,
                                  ),
                                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Vui lòng xác nhận mật khẩu';
                                  if (v != _newController.text) return 'Mật khẩu không khớp';
                                  return null;
                                },
                              ),

                              const SizedBox(height: 20),

                              // Animated confirm button (idle -> loading -> success)
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
          children: const [
            Icon(Icons.save, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Lưu',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
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
          children: const [
            Icon(Icons.check_circle, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Thành công',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        );
    }
  }
}
