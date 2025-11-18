import 'package:flutter/material.dart';
import 'login.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  int _step = 0;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  DateTime? _birthDate;
  String? _gender;

  bool _obscurePassword = true;
  double _passwordStrength = 0;

  final List<Map<String, String>> _allInterests = [
    {'title': 'Văn hóa', 'image': 'assets/images/interests/culture.jpg'},
    {'title': 'Ẩm thực', 'image': 'assets/images/interests/food.jpg'},
    {'title': 'Nhiếp ảnh', 'image': 'assets/images/interests/photo.jpg'},
    {'title': 'Leo núi', 'image': 'assets/images/interests/trekking.jpg'},
    {'title': 'Tắm biển', 'image': 'assets/images/interests/beach.jpg'},
    {'title': 'Mua sắm', 'image': 'assets/images/interests/shopping.jpg'},
    {'title': 'Tham quan', 'image': 'assets/images/interests/sightseeing.jpg'},
    {'title': 'Nghỉ dưỡng', 'image': 'assets/images/interests/resort.jpg'},
    {'title': 'Lễ hội', 'image': 'assets/images/interests/festival.jpg'},
    {'title': 'Cafe', 'image': 'assets/images/interests/cafe.jpg'},
    {'title': 'Homestay', 'image': 'assets/images/interests/homestay.jpg'},
    {'title': 'Ngắm cảnh', 'image': 'assets/images/interests/view.jpg'},
    {'title': 'Cắm trại', 'image': 'assets/images/interests/camping.jpg'},
    {'title': 'Du thuyền', 'image': 'assets/images/interests/cruise.jpg'},
    {'title': 'Động vật', 'image': 'assets/images/interests/animals.jpg'},
    {'title': 'Mạo hiểm', 'image': 'assets/images/interests/thrilling.jpg'},  
    {'title': 'Phượt', 'image': 'assets/images/interests/backpacking.jpg'},
    {'title': 'Đặc sản', 'image': 'assets/images/interests/specialty.jpg'},
    {'title': 'Vlog', 'image': 'assets/images/interests/vlog.jpg'},
    {'title': 'Chèo sup', 'image': 'assets/images/interests/rowing.jpg'},
    {'title': 'Khác', 'image': ''},
  ];

  final List<String> _selectedInterests = [];
  int _visibleCount = 12;
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        setState(() {
          _visibleCount = (_visibleCount + 9).clamp(0, _allInterests.length);
        });
      }
    });
  }

  bool get _isValid {
    switch (_step) {
      case 0:
        final email = _emailController.text.trim();
        final isValid = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(email);
        print('Step 0 (Email): $email -> Valid: $isValid');
        return isValid;

      case 1:
        final password = _passwordController.text;
        final hasMinLength = password.length >= 8;
        final hasLetters = RegExp(r'[a-zA-Z]').hasMatch(password);
        final hasDigits = RegExp(r'[0-9]').hasMatch(password);
        final isValid = hasMinLength && hasLetters && hasDigits;
        print('Step 1 (Password): length=${password.length}, hasLetters=$hasLetters, hasDigits=$hasDigits -> Valid: $isValid');
        return isValid;

      case 2:
        final isValid = _nameController.text.trim().isNotEmpty;
        print('Step 2 (Name): ${_nameController.text} -> Valid: $isValid');
        return isValid;

      case 3:
        final isValid = _birthDate != null;
        print('Step 3 (Birth Date): $_birthDate -> Valid: $isValid');
        return isValid;

      case 4:
        final isValid = _gender != null;
        print('Step 4 (Gender): $_gender -> Valid: $isValid');
        return isValid;

      case 5:
        final isValid = _selectedInterests.length >= 3;
        print('Step 5 (Interests): ${_selectedInterests.length} selected -> Valid: $isValid');
        return isValid;

      default:
        print('Step $_step: Invalid step');
        return false;
    }
  }

  void _nextStep() {
    print('Current step: $_step, isValid: $_isValid'); // Debug log
    if (_isValid && _step < 6) {
      setState(() => _step++);
      print('Moving to step: $_step'); // Debug log
    } else {
      print('Cannot move to next step. Step: $_step, Valid: $_isValid'); // Debug log
    }
  }

  void _prevStep() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      Navigator.pop(context);
    }
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: const Color(0xFF8A724C),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF8A724C),
                textStyle: const TextStyle(
                  fontFamily: 'WorkSans',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(
                fontFamily: 'WorkSans',
                fontWeight: FontWeight.w500,
                fontSize: 18,
                color: Colors.black
              ),
              labelLarge: TextStyle(
                fontFamily: 'WorkSans',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black
              ),
              titleLarge: TextStyle(
                fontFamily: 'WorkSans',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: Colors.black
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  void _fadeToLogin(BuildContext context) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 150),
      ),
    );
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

  Future<void> _submitSignup() async {
    final url = ApiConfig.getUri(ApiConfig.createProfile);

    final body = jsonEncode({
      "fullname": _nameController.text.trim(),
      "email": _emailController.text.trim(),
      "password": _passwordController.text,
      "interests": _selectedInterests,
      "preferred_city": "",
    });

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      Navigator.pop(context); 

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đăng ký thành công!")),
        );
        _fadeToLogin(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: ${response.body}")),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi kết nối server: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/saigon.jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.3)),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 26),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                          onPressed: _prevStep,
                        ),
                        Expanded(
                          child: Center(
                            child: _buildStepIndicators(),
                          ),
                        ),
                        const SizedBox(width: 48), 
                      ],
                    ),
                  ),

                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: _buildStepContent(_step),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(int step) {
    Widget content;
    switch (step) {
      case 0:
        content = _buildTextField(
          controller: _emailController,
          hint: "Nhập email của bạn",
          icon: Icons.email_outlined,
        );
        break;
      case 1:
        content = Column(
          children: [
            _buildTextField(
              controller: _passwordController,
              hint: "Tạo mật khẩu",
              icon: Icons.lock_outline,
              obscure: true,
            ),
            const SizedBox(height: 12),
            if (_passwordController.text.isNotEmpty)
              _buildPasswordStrengthBar(), 
          ],
        );
        break;
      case 2:
        content = _buildTextField(
          controller: _nameController,
          hint: "Nhập tên hiển thị",
          icon: Icons.person_outline,
        );
        break;
      case 3:
        content = GestureDetector(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined),
                const SizedBox(width: 10),
                Text(
                  _birthDate == null
                      ? "Chọn ngày sinh"
                      : "${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontFamily: 'WorkSans',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
        break;
      case 4:
        content = Column(
          children: [
            _buildGenderTile("Nam"),
            _buildGenderTile("Nữ"),
            _buildGenderTile("Khác"),
          ],
        );
        break;
      case 5:
        content = _buildInterestsPicker();
        break;
      default:
        content = const Icon(Icons.check_circle, color: Colors.white, size: 0);
    }

    return Padding(
      key: ValueKey(step),
      padding: const EdgeInsets.only(top: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 110,
            child: Center(
              child: Text(
                step == 6
                    ? "Tất cả đã sẵn sàng!"
                    : [
                        "Email của bạn là",
                        "Tạo một mật khẩu",
                        "Tên bạn là",
                        "Ngày sinh của bạn",
                        "Bạn là",
                        "Bạn đang tìm kiếm điều gì?"
                      ][step],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 36,
                  fontFamily: 'WorkSans',
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          content,
          const SizedBox(height: 30),

          if (_step < 6)
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isValid ? _nextStep : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isValid ? const Color(0xFF8A724C) : const Color.fromARGB(255, 73, 73, 73),
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
            )
          else
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _submitSignup, 
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8A724C),
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

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Bạn đã có tài khoản? ",
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'WorkSans',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              GestureDetector(
                onTap: () {
                  _fadeToLogin(context);
                },
                child: const Text(
                  "Đăng nhập",
                  style: TextStyle(
                    color: Color.fromARGB(255, 255, 225, 176),
                    fontFamily: 'WorkSans',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure ? _obscurePassword : false,
      onChanged: (value) {
        setState(() {
          if (obscure) {
            _passwordStrength = _calculatePasswordStrength(value);
          }
        });
      },
      style: const TextStyle(
        fontSize: 18,
        fontFamily: 'WorkSans',
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        hintText: hint,
        hintStyle: const TextStyle(fontFamily: 'WorkSans'),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        suffixIcon: obscure
            ? IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
      ),
    );
  }

  Widget _buildPasswordStrengthBar() {
    Color getColor(double strength) {
      if (strength <= 0.25) return Colors.redAccent;
      if (strength <= 0.5) return Colors.orangeAccent;
      if (strength <= 0.75) return Colors.greenAccent;
      return Colors.lightBlueAccent;
    }

    String getLabel(double strength) {
      if (strength <= 0.25) return "Yếu";
      if (strength <= 0.5) return "Trung bình";
      if (strength <= 0.75) return "Mạnh";
      return "Rất tốt!";
    }

    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: _passwordStrength),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 15,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                color: getColor(value),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: _passwordStrength),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          builder: (context, value, _) {
            return Align(
              alignment: Alignment.centerRight,
              child: Text(
                getLabel(value),
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'WorkSans',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildGenderTile(String value) {
    final isSelected = _gender == value;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isSelected
              ? const Color(0xFF8A724C)
              : Colors.transparent,
          width: 3,
        ),
      ),
      child: RadioListTile<String>(
        title: Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'WorkSans',
            fontWeight: FontWeight.w500,
            color: isSelected ? const Color(0xFF8A724C) : Colors.black,
          ),
        ),
        value: value,
        groupValue: _gender,
        activeColor: const Color(0xFF8A724C),
        onChanged: (v) => setState(() => _gender = v),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  Widget _buildInterestsPicker() {
    return Expanded(
      child: Column(
        children: [
          const Text(
            "Chọn ít nhất 3 sở thích của bạn",
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'WorkSans',
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              controller: _scrollController,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemCount: _visibleCount,
              itemBuilder: (context, index) {
                final interest = _allInterests[index];
                final isSelected =
                    _selectedInterests.contains(interest['title']);
                final imagePath = (interest['image'] ?? '').trim();
                final hasImage = imagePath.isNotEmpty;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedInterests.remove(interest['title']);
                      } else {
                        _selectedInterests.add(interest['title']!);
                      }
                    });
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected
                                ? Color.fromARGB(255, 255, 225, 176)
                                : Colors.transparent,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        height: 105,
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: hasImage
                                  ? Image.asset(
                                      imagePath,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.black.withValues(alpha: 0.6),
                                          alignment: Alignment.center,
                                          child: Text(
                                            interest['title']!,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontFamily: 'WorkSans',
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : Container(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      alignment: Alignment.center,
                                      child: Text(
                                        interest['title']!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontFamily: 'WorkSans',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                            ),

                            if (isSelected)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Color.fromARGB(255, 255, 225, 176),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          interest['title']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'WorkSans',
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Color.fromARGB(255, 255, 225, 176)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(7, (index) {
        final isActive = index == _step;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: isActive ? 16 : 12,
          height: isActive ? 16 : 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? Color.fromARGB(255, 255, 225, 176)
                : Colors.white.withValues(alpha: 0.4),
          ),
        );
      }),
    );
  }
}
