import 'package:flutter/material.dart';

class PinGridDialog extends StatelessWidget {
  final String pin;
  final Color fillColor;

  const PinGridDialog({
    super.key,
    required this.pin,
    this.fillColor = const Color(0xFF8A724C),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final bool isFilled = index < pin.length;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: 36,
          height: 44,
          decoration: BoxDecoration(
            color: isFilled ? fillColor : Colors.transparent,
            border: Border.all(
              color: fillColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: isFilled
                ? Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
          ),
        );
      }),
    );
  }
}