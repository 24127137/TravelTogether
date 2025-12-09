import 'package:flutter/material.dart';
import '../services/security_service.dart';
import '../services/auth_service.dart';
import '../widgets/pin_grid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import 'main_app_screen.dart';

class SecuritySetupScreen extends StatefulWidget {
  const SecuritySetupScreen({super.key});

  @override
  State<SecuritySetupScreen> createState() => _SecuritySetupScreenState();
}

class _SecuritySetupScreenState extends State<SecuritySetupScreen> {
  final pageController = PageController();
  String safePin = '';
  String dangerPin = '';

  Future<void> _onSafePinComplete(String pin) async {
    safePin = pin;
    pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
  }

  Future<void> _onDangerPinConfirmed(String pin) async {
    dangerPin = pin;

    if (dangerPin == safePin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Mã PIN khẩn cấp không được trùng với mã PIN thường!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
  }

  Future<void> _onFinalComplete(String emergencyEmail) async {
    if (emergencyEmail.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emergencyEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập email hợp lệ!'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      await SecurityApiService.setSafePin(safePin);
      await SecurityApiService.setDangerPin(dangerPin);

      final token = await AuthService.getValidAccessToken();
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'emergency_contact': emergencyEmail}),
      );

      if (response.statusCode != 200) throw Exception('Cập nhật thất bại');

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SetupSuccessScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      body: PageView(
        controller: pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          PinSetupPage(onComplete: _onSafePinComplete),
          DangerPinSetupPage(onConfirmed: _onDangerPinConfirmed),
          EmergencyContactMandatoryPage(onComplete: _onFinalComplete),
        ],
      ),
    );
  }
}

class PinSetupPage extends StatefulWidget {
  final Function(String) onComplete;
  const PinSetupPage({super.key, required this.onComplete});

  @override
  State<PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends State<PinSetupPage> {
  final controller = TextEditingController();
  final focusNode = FocusNode();
  String pin = '';
  String confirmPin = '';
  int step = 0;

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      setState(() => pin = controller.text);
      if (pin.length == 6) {
        if (step == 0) {
          confirmPin = pin;
          setState(() => step = 1);
          controller.clear();
          pin = '';
        } else if (pin == confirmPin) {
          widget.onComplete(confirmPin);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mã PIN không khớp!'), backgroundColor: Colors.red),
          );
          setState(() => step = 0);
          controller.clear();
          pin = '';
        }
      }
    });
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
    return GestureDetector(
      onTap: () => focusNode.requestFocus(),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(step == 0 ? "Tạo mã PIN bảo mật" : "Xác nhận mã PIN", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'WorkSans')),
            const SizedBox(height: 12),
            Text(step == 0 ? "Dùng để mở app bình thường" : "Nhập lại để xác nhận", textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.black54)),
            const SizedBox(height: 60),
            PinGrid(pin: pin), 
            const SizedBox(height: 100),
            Offstage(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(counterText: ''),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DangerPinSetupPage extends StatefulWidget {
  final Function(String) onConfirmed;
  const DangerPinSetupPage({super.key, required this.onConfirmed});

  @override
  State<DangerPinSetupPage> createState() => _DangerPinSetupPageState();
}

class _DangerPinSetupPageState extends State<DangerPinSetupPage> {
  final controller = TextEditingController();
  final focusNode = FocusNode();
  String pin = '';
  String confirmPin = '';
  int step = 0;

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      setState(() => pin = controller.text);
      if (pin.length == 6) {
        if (step == 0) {
          confirmPin = pin;
          setState(() => step = 1);
          controller.clear();
          pin = '';
        } else if (pin == confirmPin) {
          widget.onConfirmed(confirmPin);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mã PIN khẩn cấp không khớp!'), backgroundColor: Colors.red),
          );
          setState(() => step = 0);
          controller.clear();
          pin = '';
        }
      }
    });
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
    return GestureDetector(
      onTap: () => focusNode.requestFocus(),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emergency, size: 100, color: Colors.red),
            const SizedBox(height: 32),
            Text(step == 0 ? "Tạo mã PIN khẩn cấp" : "Xác nhận mã PIN khẩn cấp", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'WorkSans')),
            const SizedBox(height: 12),
            Text(
              step == 0 
                  ? "Dùng khi gặp nguy hiểm – hệ thống sẽ gửi cảnh báo ngầm" 
                  : "Nhập lại mã PIN khẩn cấp",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 60),
            PinGrid(pin: pin),
            const SizedBox(height: 100),
            Offstage(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(counterText: ''),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmergencyContactMandatoryPage extends StatefulWidget {
  final Function(String) onComplete;
  const EmergencyContactMandatoryPage({super.key, required this.onComplete});

  @override
  State<EmergencyContactMandatoryPage> createState() => _EmergencyContactMandatoryPageState();
}

class _EmergencyContactMandatoryPageState extends State<EmergencyContactMandatoryPage> {
  final _emailController = TextEditingController();
  bool _isValidEmail = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() {
      setState(() {
        _isValidEmail = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const SizedBox(height: 60),
          const Icon(Icons.email_outlined, size: 90, color: Colors.red),
          const SizedBox(height: 32),
          const Text("Email liên hệ khẩn cấp", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text(
            "Bắt buộc – người này sẽ nhận cảnh báo khi bạn nhập mã khẩn cấp",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 40),

          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: "Email người thân",
              hintText: "nguoithan@gmail.com",
              prefixIcon: const Icon(Icons.email),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              errorText: _emailController.text.isNotEmpty && !_isValidEmail ? "Email không hợp lệ" : null,
            ),
          ),

          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _isValidEmail ? () => widget.onComplete(_emailController.text) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isValidEmail ? Colors.red : Colors.grey,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text("Hoàn tất thiết lập", style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }
}

class SetupSuccessScreen extends StatelessWidget {
  const SetupSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 120, color: Colors.green),
              const SizedBox(height: 32),
              const Text("Thiết lập thành công!", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'WorkSans')),
              const SizedBox(height: 16),
              const Text("Bảo mật khẩn cấp đã được kích hoạt", textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
              const SizedBox(height: 60),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8A724C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () async {
                    final token = await AuthService.getValidAccessToken();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => MainAppScreen(accessToken: token!)),
                      (route) => false,
                    );
                  },
                  child: const Text(
                    "Vào ứng dụng ngay",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'WorkSans'),
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