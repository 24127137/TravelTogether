import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/destination.dart';
import '../data/mock_destinations.dart';
import '../screens/destination_explore_screen.dart';
import '../widgets/enter_bar.dart';
<<<<<<< HEAD
import '../services/user_service.dart';
=======
import '../config/api_config.dart';
import '../services/auth_service.dart';
>>>>>>> 3ee7efe (done all groupapis)

class DestinationDetailScreen extends StatefulWidget {
  final Destination? destination;
  final VoidCallback? onBack;
  final VoidCallback? onContinue;

  const DestinationDetailScreen({
    Key? key,
    this.destination,
    this.onBack,
    this.onContinue
  }) : super(key: key);

  @override
  State<DestinationDetailScreen> createState() => _DestinationDetailScreenState();
}

class _DestinationDetailScreenState extends State<DestinationDetailScreen> {
  final UserService _userService = UserService();
  bool _isSaving = false;

  Future<void> _handleContinue(Destination dest) async {
    // 1. Chặn người dùng click nhiều lần
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      // 2. Lấy thành phố cũ để backup (Logic mượn)
      String? previousCity = await _userService.getPreferredCity();
      print("📝 [Detail] Thành phố cũ là: $previousCity. Chuẩn bị đổi sang: ${dest.cityId}");

      // 3. GỌI API UPDATE VÀ CHỜ (QUAN TRỌNG)
      // Phải có await ở đây để code dừng lại chờ Backend xử lý xong
      bool success = await _userService.updatePreferredCity(dest.cityId);

      if (success) {
        print("✅ [Detail] Đã update preferred_city thành công!");
      } else {
        print("⚠️ [Detail] Update thất bại hoặc ID thành phố sai map. Vẫn tiếp tục chuyển trang.");
      }

      // 4. Mẹo: Thêm delay 300ms để đảm bảo DB bên Backend đã commit transaction xong
      // Tránh trường hợp trang sau gọi API quá nhanh khi DB chưa kịp lưu
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;
      setState(() => _isSaving = false);

      // 5. Chuyển sang Explore Screen (Mang theo previousCity để restore nếu cần)
      if (widget.onContinue != null) {
        widget.onContinue!();
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DestinationExploreScreen(
              cityId: dest.cityId,
              restoreCityRawName: previousCity, // Truyền backup vào đây
            ),
          ),
        );
      }
    } catch (e) {
      print("❌ [Detail] Lỗi nghiêm trọng khi lưu city: $e");
      if (mounted) setState(() => _isSaving = false);

      // Fallback: Vẫn cho người dùng đi tiếp để không bị kẹt app
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DestinationExploreScreen(cityId: dest.cityId),
        ),
      );
    }
  }

  @override
  State<DestinationDetailScreen> createState() => _DestinationDetailScreenState();
}

class _DestinationDetailScreenState extends State<DestinationDetailScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    // Logic build giữ nguyên, chỉ thay đổi _handleContinue ở trên
=======
>>>>>>> 3ee7efe (done all groupapis)
    final dest = widget.destination ?? mockDestinations.firstWhere((d) => d.name == 'Đà Lạt');
    final size = MediaQuery.of(context).size;
    final double imageHeight = size.height * 0.55;

    return PopScope(
<<<<<<< HEAD
      canPop: !_isSaving && widget.onBack == null, // Không cho back khi đang save
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && widget.onBack != null && !_isSaving) {
=======
      canPop: widget.onBack == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && widget.onBack != null) {
>>>>>>> 3ee7efe (done all groupapis)
          widget.onBack!();
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: const Color(0xFF7B4A22),
        body: SafeArea(
          child: SizedBox.expand(
            child: Stack(
              children: [
                Positioned(
                  left: 0, right: 0, top: 0,
                  child: Image.asset(dest.imagePath, width: size.width, height: imageHeight, fit: BoxFit.cover),
                ),
                Positioned(
                  left: 0, right: 0, top: imageHeight - 50, bottom: 0,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter, end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withAlpha((0.15 * 255).toInt()),
                              const Color(0xFF7B4A22).withAlpha((0.95 * 255).toInt()),
                              const Color(0xFF7B4A22),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
<<<<<<< HEAD
                Positioned(
                  top: 12, left: 12,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: _isSaving ? null : (widget.onBack ?? () => Navigator.of(context).pop()),
                    ),
=======
              ),

              // Nút Quay lại
              Positioned(
                top: 12,
                left: 12,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
>>>>>>> 3ee7efe (done all groupapis)
                  ),
                ),
                Positioned(
                  left: 16, right: 16, top: imageHeight - 120, bottom: kBottomNavigationBarHeight + 90,
                  child: Container(
                    padding: const EdgeInsets.only(top: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(dest.name, style: const TextStyle(color: Color(0xFFDCC9A7), fontSize: 48, fontFamily: 'Jaro', fontWeight: FontWeight.w400, shadows: [Shadow(blurRadius: 8, color: Colors.black54, offset: Offset(2, 2))])),
                        const SizedBox(height: 6),
                        Text(dest.province, style: const TextStyle(color: Color(0xFFF7F3E8), fontSize: 18, fontFamily: 'Jaro')),
                        const SizedBox(height: 18),
                        Text('description'.tr(), style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(dest.getDescription(context.locale.languageCode), style: const TextStyle(color: Colors.white, fontSize: 15, fontFamily: 'Poppins', height: 1.5)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
<<<<<<< HEAD
                Positioned(
                  left: 0, right: 0, bottom: kBottomNavigationBarHeight + 35,
                  child: Center(
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Color(0xFFDCC9A7))
                        : EnterButton(onConfirm: () => _handleContinue(dest)),
=======
              ),

              // EnterButton thay thế nút cũ
              Positioned(
                left: 0,
                right: 0,
                bottom: kBottomNavigationBarHeight + 35, // ← Đặt ngay trên thanh bar
                child: Center(
                  child: Opacity(
                    opacity: _isLoading ? 0.5 : 1.0,
                    child: IgnorePointer(
                      ignoring: _isLoading,
                      child: EnterButton(
                        onConfirm: () => _handleSelectDestination(dest),
                      ),
                    ),
>>>>>>> 3ee7efe (done all groupapis)
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSelectDestination(Destination dest) async {
    setState(() => _isLoading = true);

    try {
      final token = await AuthService.getValidAccessToken();
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('session_expired'.tr())),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final userData = await _fetchUserProfile(token);
      if (userData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('cannot_fetch_profile'.tr())),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final success = await _updatePreferredCity(token, dest.name, userData);
      
      if (mounted) {
        if (success) {
          // Navigate to explore screen
          if (widget.onContinue != null) {
            widget.onContinue!();
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DestinationExploreScreen(cityId: dest.cityId),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('update_city_failed'.tr())),
          );
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      debugPrint('Error selecting destination: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('cannot_connect_server'.tr())),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Map<String, dynamic>?> _fetchUserProfile(String token) async {
    try {
      final url = ApiConfig.getUri(ApiConfig.userProfile);
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Fetch profile status: ${response.statusCode}');
      debugPrint('Fetch profile body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        await AuthService.clearTokens();
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      return null;
    }
  }

  Future<bool> _updatePreferredCity(
    String token,
    String cityName,
    Map<String, dynamic> userData,
  ) async {
    try {
      final url = ApiConfig.getUri(ApiConfig.userProfile);

      final body = {
        'fullname': userData['fullname'] ?? '',
        'email': userData['email'] ?? '',
        'gender': userData['gender'] ?? '',
        'birth_date': userData['birth_date'] ?? '',
        'description': userData['description'] ?? '',
        'interests': userData['interests'] ?? [],
        'preferred_city': cityName,
      };

      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      debugPrint('Update city status: ${response.statusCode}');
      debugPrint('Update city body: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Error updating city: $e');
      return false;
    }
  }
}