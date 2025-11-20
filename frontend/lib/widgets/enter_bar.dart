import 'package:flutter/material.dart';

class EnterButton extends StatefulWidget {
  final VoidCallback onConfirm;

  const EnterButton({
    super.key,
    required this.onConfirm,
  });

  @override
  State<EnterButton> createState() => _EnterButtonState();
}

class _EnterButtonState extends State<EnterButton>
    with SingleTickerProviderStateMixin {
  bool _isPressing = false;
  bool _isConfirmed = false;

  late AnimationController _controller;
  late Animation<double> _fillWidth;
  late Animation<double> _iconScale;
  late Animation<double> _textOpacity;

  final double fullWidth = 243;
  final double height = 55;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Animation mở rộng phần màu từ 55 (kích thước nút tròn) đến full width
    _fillWidth = Tween<double>(begin: 55, end: 243).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    // Animation scale cho icon
    _iconScale = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    // Animation fade cho text
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePressStart() {
    setState(() {
      _isPressing = true;
      _isConfirmed = false;
    });
    _controller.forward();
  }

  void _handlePressEnd() {
    if (_isPressing) {
      setState(() => _isConfirmed = true);

      Future.delayed(const Duration(milliseconds: 300), () {
        widget.onConfirm();
      });
    }
  }

  void _handlePressCancel() {
    setState(() {
      _isPressing = false;
      _isConfirmed = false;
    });
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _handlePressStart(),
      onTapUp: (_) => _handlePressEnd(),
      onTapCancel: _handlePressCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Container(
            width: fullWidth,
            height: height,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Stack(
              children: [
                // Phần màu tràn từ trái sang phải khi nhấn
// Thay thế phần "Phần màu tràn từ trái sang phải khi nhấn"
                if (_isPressing && !_isConfirmed)
                  Positioned(
                    left: 0,
                    top: 0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          width: _fillWidth.value,
                          height: height,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Color(0xFFB64B12), Color(0xFFCD7F32)],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),


                // Container confirmed với gradient ngược
                if (_isConfirmed)
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      width: fullWidth,
                      height: height,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0xFFCD7F32), Color(0xFFB64B12)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),

                // Hình tròn ban đầu với màu nền B64B12
                if (!_isPressing && !_isConfirmed)
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      width: 55,
                      height: 55,
                      decoration: const BoxDecoration(
                        color: Color(0xFFB64B12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/images/arrow_initial.png',
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                // Text Tiếp tục với fade in/out
                if (!_isConfirmed)
                  Center(
                    child: Transform.translate(
                      offset: const Offset(20, 0),
                      child: AnimatedOpacity(
                        opacity: _isPressing ? _textOpacity.value : 1.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        child: const Text(
                          'Tiếp tục',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontFamily: 'REM',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Icon mũi tên khi đang nhấn
                if (_isPressing && !_isConfirmed)
                  Positioned(
                    left: 5,
                    top: 2.5,
                    child: Transform.scale(
                      scale: _iconScale.value,
                      child: Image.asset(
                        'assets/images/arrow_pressing.png',
                        width: 60,
                        height: 60,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                // Icon xác nhận
                if (_isConfirmed)
                  Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        final double safeOpacity = value.clamp(0.0, 1.0);
                        return Transform.scale(
                          scale: value,
                          child: Opacity(
                            opacity: safeOpacity,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Color(0xFFB64B12),
                                size: 32,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
