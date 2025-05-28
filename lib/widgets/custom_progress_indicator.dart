import 'package:flutter/material.dart';

class CustomLinearProgressIndicator extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double height;
  final Color backgroundColor;
  final Color valueColor;

  const CustomLinearProgressIndicator({
    Key? key,
    required this.value,
    this.height = 4.0,
    this.backgroundColor = const Color(0xFF2A2A2A),
    this.valueColor = const Color(0xFFF5D505),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: Container(
        height: height,
        color: backgroundColor,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              height: height,
              color: valueColor,
            ),
          ),
        ),
      ),
    );
  }
} 