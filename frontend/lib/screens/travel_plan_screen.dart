// file: lib/screens/travel_plan_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Để format ngày đẹp
import '../services/auth_service.dart';
import '../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'map_route_screen.dart';

class TravelPlanScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const TravelPlanScreen({super.key, this.onBack});

  @override
  State<TravelPlanScreen> createState() => _TravelPlanScreenState();
}

class _TravelPlanScreenState extends State<TravelPlanScreen> {
  List<Map<String, dynamic>> _plans = []; // Mỗi phần tử là một group plan
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroupPlans();
  }

  Future<void> _loadGroupPlans() async {
    setState(() => _isLoading = true);

    try {
      final token = await AuthService.getValidAccessToken();
      if (token == null) throw Exception("Vui lòng đăng nhập lại");

      final groupsResponse = await http.get(
        ApiConfig.getUri(ApiConfig.myGroup),
        headers: {"Authorization": "Bearer $token"},
      );

      if (groupsResponse.statusCode != 200) throw Exception("Không tải được danh sách nhóm");

      final dynamic rawGroups = jsonDecode(utf8.decode(groupsResponse.bodyBytes));
      List<dynamic> groupsList = rawGroups is List ? rawGroups : (rawGroups is Map ? [rawGroups] : []);

      List<Map<String, dynamic>> tempPlans = [];

      for (var group in groupsList) {
        final groupId = group['id'] ?? group['group_id'];
        if (groupId == null) continue;

        try {
          final planResponse = await http.get(
            Uri.parse('${ApiConfig.baseUrl}/groups/$groupId/public-plan'),
            headers: {"Authorization": "Bearer $token"},
          );

          print(planResponse.body);

          if (planResponse.statusCode == 200) {
            final planData = jsonDecode(utf8.decode(planResponse.bodyBytes));

            final String groupName = planData['group_name']?.toString().trim().isNotEmpty == true
                ? planData['group_name'].toString()
                : 'Nhóm chat';

            final String city = planData['preferred_city']?.toString().trim().isNotEmpty == true
                ? planData['preferred_city'].toString()
                : 'Chưa chọn thành phố';

            final String? groupImageUrl = planData['group_image_url']?.toString().trim().isNotEmpty == true
                ? planData['group_image_url'].toString()
                : null;

            final dynamic travelDatesRaw = planData['travel_dates'];
            final String travelDatesFormatted = _formatTravelDates(travelDatesRaw);

            tempPlans.add({
              "group_id": groupId,
              "group_name": groupName,
              "city": city,
              "travel_dates": travelDatesFormatted,
              "image_url": groupImageUrl,
              "itinerary": Map<String, dynamic>.from(planData['itinerary'] ?? {}),
              "interests": List<String>.from(planData['interests'] ?? []),
            });
          }
        } catch (e) {
          print("Lỗi tải plan cho group $groupId: $e");
          tempPlans.add({
            "group_id": groupId,
            "group_name": group['name']?.toString() ?? 'Nhóm chat',
            "city": 'Chưa có kế hoạch',
            "travel_dates": '',
            "image_url": group['group_image_url']?.toString(),
          });
        }
      }

      if (mounted) {
        setState(() {
          _plans = tempPlans;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading group plans: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTravelDates(dynamic raw) {
    final String? lowerStr = raw['lower'];
    final String? upperStr = raw['upper'];

    if (lowerStr == null || lowerStr.isEmpty) {
      return 'Chưa chọn ngày';
    }

    try {
      final DateTime start = DateTime.parse(lowerStr);

      if (upperStr == null || upperStr.isEmpty || upperStr == lowerStr) {
        return DateFormat('dd/MM/yyyy').format(start);
      }

      final DateTime end = DateTime.parse(upperStr);

      if (start.year == end.year && start.month == end.month) {
        return '${start.day} – ${end.day}/${DateFormat('MM/yyyy').format(end)}';
      }

      return '${DateFormat('dd/MM/yyyy').format(start)} – ${DateFormat('dd/MM/yyyy').format(end)}';
    } catch (e) {
      print('Lỗi parse travel_dates: $e | Raw: $raw');
      return 'Ngày không hợp lệ';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Nền cô gái cầm ống nhòm
          Image.asset(
            'assets/images/happy.jpg',
            fit: BoxFit.cover,
          ),

          // Khung danh sách kế hoạch
          Positioned(
            top: topPadding + 90,
            left: 20,
            right: 20,
            height: size.height * 0.66,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFB64B12), width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "KẾ HOẠCH CỦA TÔI",
                    style: TextStyle(
                      fontFamily: 'Alumni Sans',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF7F3E8),
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(height: 2, width: 40, color: Color(0xFFB64B12)),
                  const SizedBox(height: 16),

                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFFB64B12)))
                        : _plans.isEmpty
                            ? _buildEmptyState()
                            : ListView.separated(
                                padding: EdgeInsets.zero,
                                itemCount: _plans.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final plan = _plans[index];
                                  return _buildPlanCard(plan);
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),

          // Nút back
          Positioned(
            top: topPadding + 10,
            left: 16,
            child: GestureDetector(
              onTap: widget.onBack ?? () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.travel_explore, size: 48, color: Colors.grey[400]),
        const SizedBox(height: 10),
        Text(
          "Bạn chưa có kế hoạch du lịch nào",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[300], fontSize: 15),
        ),
        const SizedBox(height: 5),
        Text(
          "Tham gia nhóm chat để cùng bạn bè lên kế hoạch nhé!",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[400], fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final imageUrl = plan['image_url'] as String?;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MapRouteScreen(
              cityFilter: plan['city'],
              groupId: plan['group_id'], 
            ),
          ),
        );
      },
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // Ảnh nhóm hoặc fallback đẹp
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: hasImage
                  ? Image.network(
                      imageUrl!,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _defaultGroupImage(),
                    )
                  : _defaultGroupImage(),
            ),

            // Thông tin kế hoạch
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      plan['group_name'],
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3E3322),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan['city'],
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFFE37547),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan['travel_dates'],
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultGroupImage() {
    return Container(
      width: 90,
      height: 90,
      color: const Color(0xFFFFE5D9),
      child: const Icon(Icons.groups_2, size: 40, color: Color(0xFFE37547)),
    );
  }
}