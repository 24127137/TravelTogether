import 'package:flutter/material.dart';

class OldPinPage extends StatefulWidget {
  const OldPinPage({super.key});

  @override
  State<OldPinPage> createState() => _OldPinPageState();
}

class _OldPinPageState extends State<OldPinPage> {
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();
  String pin = "";
  String errorMessage = "";
  bool showError = false;

  bool get _isValid => pin.length == 6;

  void _nextStep() {
    // pin test = 123456
    if (pin != "123456") {
      _showError("Mã PIN không đúng! Vui lòng thử lại.");
      return;
    }
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const NewPinPage(oldPin: "")));
  }

  void _showError(String message) {
    setState(() {
      errorMessage = message;
      showError = true;
      pin = "";
    });
    controller.clear();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _hideError();
      }
    });
  }

  void _hideError() {
    setState(() {
      showError = false;
    });
  }

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      setState(() {
        pin = controller.text;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    focusNode.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      appBar: AppBar(
        title: const Text(
          "Bảo mật",
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600, fontFamily: 'WorkSans'),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF5EFE6),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => focusNode.requestFocus(),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8A724C).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pin_outlined,
                      size: 60,
                      color: const Color(0xFF8A724C),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "Nhập mã PIN hiện tại",
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600, fontFamily: 'WorkSans'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Mã giúp bảo mật tài khoản của bạn",
                    style: TextStyle(fontSize: 15, color: Colors.black54, fontFamily: 'WorkSans'),
                  ),
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: () => focusNode.requestFocus(),
                    child: PinGrid(pin: pin),
                  ),
                  const SizedBox(height: 60),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isValid ? _nextStep : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isValid
                            ? const Color(0xFF8A724C)
                            : const Color.fromARGB(255, 73, 73, 73),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "Tiếp tục",
                        style: TextStyle(
                          fontSize: 22,
                          fontFamily: 'WorkSans',
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(flex: 3),
                  Offstage(
                    offstage: true,
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        counterText: "",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ErrorNotification(
            show: showError,
            message: errorMessage,
            onDismiss: _hideError,
          ),
        ],
      ),
    );
  }
}

class NewPinPage extends StatefulWidget {
  final String oldPin;
  const NewPinPage({super.key, required this.oldPin});

  @override
  State<NewPinPage> createState() => _NewPinPageState();
}

class _NewPinPageState extends State<NewPinPage> {
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();
  String pin = "";
  bool get _isValid => pin.length == 6;

  void _nextStep() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConfirmPinPage(newPin: pin, oldPin: widget.oldPin),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      setState(() {
        pin = controller.text;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    focusNode.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      appBar: AppBar(
        title: const Text(
          "Bảo mật",
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500, fontFamily: 'WorkSans'),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF5EFE6),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => focusNode.requestFocus(),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const Text(
                "Nhập mã PIN mới",
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600, fontFamily: 'WorkSans'),
              ),
              const SizedBox(height: 8),
              const Text(
                "Tạo mã PIN bảo mật mới",
                style: TextStyle(fontSize: 15, color: Colors.black54, fontFamily: 'WorkSans'),
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: () => focusNode.requestFocus(),
                child: PinGrid(pin: pin),
              ),
              const SizedBox(height: 60),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isValid ? _nextStep : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isValid
                        ? const Color(0xFF8A724C)
                        : const Color.fromARGB(255, 73, 73, 73),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Tiếp tục",
                    style: TextStyle(
                      fontSize: 22,
                      fontFamily: 'WorkSans',
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 3),
              Offstage(
                offstage: true,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    counterText: "",
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ConfirmPinPage extends StatefulWidget {
  final String newPin;
  final String oldPin;
  const ConfirmPinPage({super.key, required this.newPin, required this.oldPin});

  @override
  State<ConfirmPinPage> createState() => _ConfirmPinPageState();
}

class _ConfirmPinPageState extends State<ConfirmPinPage> {
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();
  String pin = "";
  String errorMessage = "";
  bool showError = false;

  bool get _isValid => pin.length == 6;

  void _nextStep() {
    if (pin != widget.newPin) {
      _showError("Xác nhận mã PIN không khớp!");
      controller.clear();
      setState(() {
        pin = "";
      });
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SuccessPage()),
    );
  }

  void _showError(String message) {
    setState(() {
      errorMessage = message;
      showError = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _hideError();
      }
    });
  }

  void _hideError() {
    setState(() {
      showError = false;
    });
  }

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      setState(() {
        pin = controller.text;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    focusNode.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      appBar: AppBar(
        title: const Text(
          "Bảo mật",
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500, fontFamily: 'WorkSans'),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF5EFE6),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => focusNode.requestFocus(),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  const Text(
                    "Xác nhận mã PIN mới",
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600, fontFamily: 'WorkSans'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Nhập lại mã PIN để xác nhận",
                    style: TextStyle(fontSize: 15, color: Colors.black54, fontFamily: 'WorkSans'),
                  ),
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: () => focusNode.requestFocus(),
                    child: PinGrid(pin: pin),
                  ),
                  const SizedBox(height: 60),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isValid ? _nextStep : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isValid
                            ? const Color(0xFF8A724C)
                            : const Color.fromARGB(255, 73, 73, 73),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "Tiếp tục",
                        style: TextStyle(
                          fontSize: 22,
                          fontFamily: 'WorkSans',
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(flex: 3),
                  Offstage(
                    offstage: true,
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        counterText: "",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ErrorNotification(
            show: showError,
            message: errorMessage,
            onDismiss: _hideError,
          ),
        ],
      ),
    );
  }
}

class SuccessPage extends StatelessWidget {
  const SuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const Icon(Icons.lock_open_rounded, size: 100, color: Color(0xFF8A724C)),
              const SizedBox(height: 20),
              const Text(
                "Đổi mã PIN thành công!",
                style: TextStyle(
                  fontFamily: "WorkSans",
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Bạn có thể sử dụng mã PIN mới",
                style: TextStyle(fontFamily: "WorkSans", fontSize: 16),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8A724C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text(
                    "Hoàn tất",
                    style: TextStyle(
                      fontFamily: "WorkSans",
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

class PinGrid extends StatelessWidget {
  final String pin;

  const PinGrid({super.key, required this.pin});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        bool filled = index < pin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 7),
          width: 44,
          height: 50,
          decoration: BoxDecoration(
            color: filled ? const Color(0xFF8A724C) : Colors.transparent,
            border: Border.all(
              color: const Color(0xFF8A724C),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: filled
                ? const Icon(Icons.circle, size: 10, color: Colors.white)
                : null,
          ),
        );
      }),
    );
  }
}

class ErrorNotification extends StatefulWidget {
  final bool show;
  final String message;
  final VoidCallback onDismiss;

  const ErrorNotification({
    super.key,
    required this.show,
    required this.message,
    required this.onDismiss,
  });

  @override
  State<ErrorNotification> createState() => _ErrorNotificationState();
}

class _ErrorNotificationState extends State<ErrorNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  double _dragDistance = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didUpdateWidget(ErrorNotification oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _controller.forward();
    } else if (!widget.show && oldWidget.show) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragDistance += details.primaryDelta ?? 0;
      if (_dragDistance < 0) {
        _controller.value = 1 + (_dragDistance / 100).clamp(-1.0, 0.0);
      }
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_dragDistance < -50) {
      widget.onDismiss();
    }
    setState(() {
      _dragDistance = 0;
    });
    if (widget.show) {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show && _controller.status == AnimationStatus.dismissed) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: Padding(
        padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
        child: GestureDetector(
          onVerticalDragUpdate: _onVerticalDragUpdate,
          onVerticalDragEnd: _onVerticalDragEnd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'WorkSans',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}