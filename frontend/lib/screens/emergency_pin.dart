import 'package:flutter/material.dart';

class EmergencyPinSetupScreen extends StatefulWidget {
  const EmergencyPinSetupScreen({super.key});

  @override
  State<EmergencyPinSetupScreen> createState() => _EmergencyPinSetupScreenState();
}

class _EmergencyPinSetupScreenState extends State<EmergencyPinSetupScreen> {
  int _currentStep = 0;
  String _newEmergencyPin = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      appBar: AppBar(
        title: const Text(
          "Mã PIN khẩn cấp",
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600, fontFamily: 'WorkSans'),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF5EFE6),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _currentStep == 0
          ? EmergencyPinInfoScreen(
              onContinue: () {
                setState(() {
                  _currentStep = 1;
                });
              },
            )
          : _currentStep == 1
              ? EmergencyPinInputScreen(
                  onPinEntered: (pin) {
                    setState(() {
                      _newEmergencyPin = pin;
                      _currentStep = 2;
                    });
                  },
                )
              : _currentStep == 2
                  ? EmergencyPinConfirmScreen(
                      emergencyPin: _newEmergencyPin,
                      onConfirmed: () {
                        setState(() {
                          _currentStep = 3;
                        });
                      },
                    )
                  : EmergencyContactScreen(emergencyPin: _newEmergencyPin),
    );
  }
}

class EmergencyPinInfoScreen extends StatelessWidget {
  final VoidCallback onContinue;

  const EmergencyPinInfoScreen({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emergency,
              size: 60,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            "Mã PIN khẩn cấp",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'WorkSans',
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Thiết lập mã PIN khẩn cấp để bảo vệ bạn trong tình huống nguy hiểm",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
              fontFamily: 'WorkSans',
            ),
          ),
          const SizedBox(height: 32),
          _buildFeatureItem(
            Icons.notifications_active,
            "Gửi thông báo SOS",
            "Tự động gửi tin nhắn cảnh báo đến người thân",
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            Icons.location_on,
            "Chia sẻ vị trí",
            "Gửi vị trí GPS hiện tại cho liên hệ khẩn cấp",
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            Icons.visibility_off,
            "Chế độ ẩn danh",
            "App hoạt động bình thường để không lộ tình huống",
          ),
          const Spacer(flex: 2),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "Thiết lập ngay",
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'WorkSans',
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.red, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'WorkSans',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontFamily: 'WorkSans',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EmergencyPinInputScreen extends StatefulWidget {
  final Function(String) onPinEntered;

  const EmergencyPinInputScreen({super.key, required this.onPinEntered});

  @override
  State<EmergencyPinInputScreen> createState() => _EmergencyPinInputScreenState();
}

class _EmergencyPinInputScreenState extends State<EmergencyPinInputScreen> {
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();
  String pin = "";
  bool get _isValid => pin.length == 6;

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
    return GestureDetector(
      onTap: () => focusNode.requestFocus(),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emergency,
                size: 40,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Tạo mã PIN khẩn cấp",
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600, fontFamily: 'WorkSans'),
            ),
            const SizedBox(height: 8),
            const Text(
              "Chọn mã PIN khác với mã PIN thường",
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
                onPressed: _isValid ? () => widget.onPinEntered(pin) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isValid ? Colors.red : const Color.fromARGB(255, 73, 73, 73),
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
    );
  }
}

class EmergencyPinConfirmScreen extends StatefulWidget {
  final String emergencyPin;
  final VoidCallback onConfirmed;

  const EmergencyPinConfirmScreen({
    super.key,
    required this.emergencyPin,
    required this.onConfirmed,
  });

  @override
  State<EmergencyPinConfirmScreen> createState() => _EmergencyPinConfirmScreenState();
}

class _EmergencyPinConfirmScreenState extends State<EmergencyPinConfirmScreen> {
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();
  String pin = "";
  String errorMessage = "";
  bool showError = false;

  bool get _isValid => pin.length == 6;

  void _confirm() {
    if (pin != widget.emergencyPin) {
      _showError("Mã PIN không khớp!");
      controller.clear();
      setState(() {
        pin = "";
      });
      return;
    }
    widget.onConfirmed();
  }

  void _showError(String message) {
    setState(() {
      errorMessage = message;
      showError = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          showError = false;
        });
      }
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
    return Stack(
      children: [
        GestureDetector(
          onTap: () => focusNode.requestFocus(),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 32),
                const Text(
                  "Xác nhận mã PIN khẩn cấp",
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600, fontFamily: 'WorkSans'),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Nhập lại để xác nhận",
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
                    onPressed: _isValid ? _confirm : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isValid ? Colors.red : const Color.fromARGB(255, 73, 73, 73),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "Xác nhận",
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
          onDismiss: () => setState(() => showError = false),
        ),
      ],
    );
  }
}

class EmergencyContactScreen extends StatefulWidget {
  final String emergencyPin;

  const EmergencyContactScreen({super.key, required this.emergencyPin});

  @override
  State<EmergencyContactScreen> createState() => _EmergencyContactScreenState();
}

class _EmergencyContactScreenState extends State<EmergencyContactScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveEmergencySettings() {
    // call api to save emergency contact and settings
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const EmergencySetupSuccessScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.contacts,
                size: 40,
                color: Colors.red,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              "Liên hệ khẩn cấp",
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w600,
                fontFamily: 'WorkSans',
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              "Người này sẽ nhận thông báo khi bạn dùng mã PIN khẩn cấp",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
                fontFamily: 'WorkSans',
              ),
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: "Tên người thân",
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: "Số điện thoại",
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: "Email liên hệ (nếu có)",
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _saveEmergencySettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "Hoàn tất",
                style: TextStyle(
                  fontSize: 22,
                  fontFamily: 'WorkSans',
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class EmergencySetupSuccessScreen extends StatelessWidget {
  const EmergencySetupSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 60,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Thiết lập thành công!",
                style: TextStyle(
                  fontFamily: "WorkSans",
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Mã PIN khẩn cấp đã được kích hoạt\nHy vọng bạn không bao giờ phải dùng đến",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: "WorkSans",
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red, size: 24),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        "Khi nhập mã PIN khẩn cấp, hệ thống sẽ tự động gửi thông báo đến người thân của bạn",
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'WorkSans',
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
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
              const SizedBox(height: 20),
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