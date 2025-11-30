import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/destination.dart';
import '../data/mock_destinations.dart';
import '../screens/destination_explore_screen.dart';
import '../widgets/enter_bar.dart';
import '../config/api_config.dart';
import '../services/auth_service.dart';

class DestinationDetailScreen extends StatefulWidget {
  final Destination? destination;
  final VoidCallback? onBack;
  final VoidCallback? onContinue;
  const DestinationDetailScreen({Key? key, this.destination, this.onBack, this.onContinue}) : super(key: key);

  @override
  State<DestinationDetailScreen> createState() => _DestinationDetailScreenState();
}

class _DestinationDetailScreenState extends State<DestinationDetailScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final dest = widget.destination ?? mockDestinations.firstWhere((d) => d.name == 'Đà Lạt');
    final size = MediaQuery.of(context).size;
    final double imageHeight = size.height * 0.55;

    return PopScope(
      canPop: widget.onBack == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && widget.onBack != null) {
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
              // Ảnh nền
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Image.asset(
                  dest.imagePath,
                  width: size.width,
                  height: imageHeight,
                  fit: BoxFit.cover,
                ),
              ),

              // Hiệu ứng mờ
              Positioned(
                left: 0,
                right: 0,
                top: imageHeight - 50,
                bottom: 0,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
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

              // Nút Quay lại
              Positioned(
                top: 12,
                left: 12,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
                  ),
                ),
              ),

              // Nội dung
              Positioned(
                left: 16,
                right: 16,
                top: imageHeight - 120, // ← Thêm top để fix vị trí
                bottom: kBottomNavigationBarHeight + 90,
                child: Container(
                  padding: const EdgeInsets.only(top: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dest.name,
                        style: const TextStyle(
                          color: Color(0xFFDCC9A7),
                          fontSize: 48,
                          fontFamily: 'Jaro',
                          fontWeight: FontWeight.w400,
                          shadows: [
                            Shadow(
                              blurRadius: 8,
                              color: Colors.black54,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dest.province,
                        style: const TextStyle(
                          color: Color(0xFFF7F3E8),
                          fontSize: 18,
                          fontFamily: 'Jaro',
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'description'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Text(
                          dest.getDescription(context.locale.languageCode),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontFamily: 'Poppins',
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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