import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'enter_bar.dart';
import '../config/api_config.dart';
import '../services/auth_service.dart';

class OutGroupDialog extends StatelessWidget {
  final VoidCallback? onConfirm;
  final bool isHost;
  final String groupId;

  const OutGroupDialog({
    super.key,
    this.onConfirm,
    this.isHost = false,
    required this.groupId,
  });

  static void show(
    BuildContext context, {
    required String groupId,
    bool isHost = false,
    VoidCallback? onSuccess,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => OutGroupDialog(
        groupId: groupId,
        isHost: isHost,
        onConfirm: onSuccess,
      ),
    );
  }

  Future<void> _handleConfirm(BuildContext context) async {
    Navigator.of(context).pop();

    try {
      final accessToken = await AuthService.getValidAccessToken();
      final endpoint = isHost 
                              ? '/groups/$groupId/dissolve'  // Owner
                              : '/groups/$groupId/leave';     // Member
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');

      print('🔄 Calling $endpoint');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 10));

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Success!');

        if (onConfirm != null) {
          onConfirm!();
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final dialogWidth = screenWidth * 0.95;
    final dialogHeight = screenHeight * 0.5;
    final frameWidth = dialogWidth * 0.85;
    final frameHeight = dialogHeight * 0.45;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.025,
        vertical: screenHeight * 0.25,
      ),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        decoration: ShapeDecoration(
          color: const Color(0xFFCD7F32),
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 3, color: Color(0xFFEDE2CC)),
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Stack(
          children: [
            // Khung text cam đậm (nằm phía sau)
            Positioned(
              left: (dialogWidth - frameWidth) / 2,
              top: dialogHeight * 0.08,
              child: Container(
                width: frameWidth,
                height: frameHeight,
                decoration: ShapeDecoration(
                  color: const Color(0xFFB64B12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: frameWidth * 0.1),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        isHost ? 'BẠN MUỐN\nGIẢI TÁN NHÓM?' : 'BẠN MUỐN\nRỜI KHỎI NHÓM?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.11,
                          fontFamily: 'Alumni Sans',
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Ảnh background che khung text (nằm phía trước)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(27),
                  child: Image.asset(
                    'assets/images/outgroup.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            // Nút Enter (nằm trên cùng)
            Positioned(
              bottom: dialogHeight * 0.08,
              left: (dialogWidth - 243) / 2,
              child: EnterButton(
                onConfirm: () => _handleConfirm(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}