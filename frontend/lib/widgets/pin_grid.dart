import 'package:flutter/material.dart';

class PinGrid extends StatelessWidget {
  final String pin;
  final double? size;
  final double? spacing;
  
  const PinGrid({
    super.key, 
    required this.pin,
    this.size,
    this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final boxSize = size ?? 50.0;
    final margin = spacing ?? 7.0;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (i) {
        bool filled = i < pin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: EdgeInsets.symmetric(horizontal: margin),
          width: boxSize * 0.8,
          height: boxSize,
          decoration: BoxDecoration(
            color: filled ? const Color(0xFF8A724C) : Colors.transparent,
            border: Border.all(color: const Color(0xFF8A724C), width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: filled 
                ? Icon(Icons.circle, size: boxSize * 0.24, color: Colors.white) 
                : null
          ),
        );
      }),
    );
  }
}