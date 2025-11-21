import 'package:flutter/material.dart';
import 'enter_bar.dart';

class OutGroupDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final bool isHost;

  const OutGroupDialog({
    super.key,
    required this.onConfirm,
    this.isHost = false,
  });

  static void show(BuildContext context, VoidCallback onConfirm, {bool isHost = false}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => OutGroupDialog(onConfirm: onConfirm, isHost: isHost),
    );
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
                padding: const EdgeInsets.all(3), // Tránh đè lên border
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(27), // Nhỏ hơn border một chút
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
                onConfirm: () {
                  Navigator.of(context).pop();
                  onConfirm();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
