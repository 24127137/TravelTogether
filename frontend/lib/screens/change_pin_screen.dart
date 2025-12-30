import 'package:flutter/material.dart';
import '../../services/security_service.dart';
import '../widgets/pin_grid.dart';
import '../services/auth_service.dart';
import 'main_app_screen.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final controller = TextEditingController();
  final focusNode = FocusNode();
  String pin = '';

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      setState(() => pin = controller.text);
      if (pin.length == 6) _verifyOldPin();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => focusNode.requestFocus());
  }

  Future<void> _verifyOldPin() async {
    try {
      final res = await SecurityApiService.verifyPin(pin);

      if (res.isDanger) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Không thể đổi PIN bằng mã khẩn cấp!'),
          ),
        );
        controller.clear();
        pin = '';
        return;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NewPinForChange(oldPin: pin),
          ),
        );
      }
    } on PinVerifyException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mã PIN cũ không đúng')),
      );
      controller.clear();
      pin = '';
    }
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      appBar: AppBar(
        title: const Text("Đổi mã PIN", style: TextStyle(fontFamily: 'WorkSans')),
        centerTitle: true,
        backgroundColor: const Color(0xFFF5EFE6),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 60),
              const Icon(Icons.lock_outline, size: 100, color: Color(0xFF8A724C)),
              const SizedBox(height: 40),
              const Text(
                "Nhập mã PIN hiện tại",
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600, fontFamily: 'WorkSans'),
              ),
              const SizedBox(height: 60),
              PinGrid(pin: pin),
              const SizedBox(height: 100),
              Offstage(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  autofocus: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NewPinForChange extends StatefulWidget {
  final String oldPin;
  const NewPinForChange({super.key, required this.oldPin});

  @override
  State<NewPinForChange> createState() => _NewPinForChangeState();
}

class _NewPinForChangeState extends State<NewPinForChange> {
  final controller = TextEditingController();
  final focusNode = FocusNode();
  String pin = "";

  @override
  void initState() {
    super.initState();
    controller.addListener(() => setState(() => pin = controller.text));
    WidgetsBinding.instance.addPostFrameCallback((_) => focusNode.requestFocus());
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      appBar: AppBar(
        title: const Text("Mã PIN mới"),
        backgroundColor: const Color(0xFFF5EFE6),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height -
                AppBar().preferredSize.height -
                MediaQuery.of(context).padding.top,
          ),
          child: IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  const Text(
                      "Nhập mã PIN mới",
                      style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600)
                  ),
                  const SizedBox(height: 40),
                  PinGrid(pin: pin),
                  const SizedBox(height: 60),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: pin.length == 6
                          ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ConfirmNewPinPage(newPin: pin)
                          )
                      )
                          : null,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8A724C),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)
                          )
                      ),
                      child: const Text(
                          "Tiếp tục",
                          style: TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.w600
                          )
                      ),
                    ),
                  ),
                  const Spacer(flex: 3),
                  Offstage(
                      child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          keyboardType: TextInputType.number,
                          maxLength: 6
                      )
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ConfirmNewPinPage extends StatefulWidget {
  final String newPin;
  const ConfirmNewPinPage({super.key, required this.newPin});

  @override
  State<ConfirmNewPinPage> createState() => _ConfirmNewPinPageState();
}

class _ConfirmNewPinPageState extends State<ConfirmNewPinPage> {
  final controller = TextEditingController();
  final focusNode = FocusNode();
  String pin = "";

  @override
  void initState() {
    super.initState();
    controller.addListener(() => setState(() => pin = controller.text));
    WidgetsBinding.instance.addPostFrameCallback((_) => focusNode.requestFocus());
  }

  void _complete() async {
    if (pin != widget.newPin) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mã PIN không khớp!'))
      );
      controller.clear();
      pin = '';
      return;
    }

    try {
      await SecurityApiService.setSafePin(widget.newPin);
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SuccessPage()),
              (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      appBar: AppBar(
        title: const Text("Xác nhận mã PIN mới"),
        backgroundColor: const Color(0xFFF5EFE6),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height -
                AppBar().preferredSize.height -
                MediaQuery.of(context).padding.top,
          ),
          child: IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  const Text(
                      "Xác nhận mã PIN mới",
                      style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600)
                  ),
                  const SizedBox(height: 40),
                  PinGrid(pin: pin),
                  const SizedBox(height: 60),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: pin.length == 6 ? _complete : null,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8A724C),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)
                          )
                      ),
                      child: const Text(
                          "Hoàn tất",
                          style: TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.w600
                          )
                      ),
                    ),
                  ),
                  const Spacer(flex: 3),
                  Offstage(
                      child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          keyboardType: TextInputType.number,
                          maxLength: 6
                      )
                  ),
                ],
              ),
            ),
          ),
        ),
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
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  const Icon(
                      Icons.lock_open_rounded,
                      size: 100,
                      color: Color(0xFF8A724C)
                  ),
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
                      onPressed: () async {
                        final token = await AuthService.getValidAccessToken();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => MainAppScreen(accessToken: token!)
                          ),
                              (route) => false,
                        );
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
        ),
      ),
    );
  }
}