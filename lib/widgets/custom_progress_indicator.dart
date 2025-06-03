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
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background track
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: Container(
            height: height,
            color: backgroundColor,
          ),
        ),
        
        // Progress track with glow effect
        Positioned(
          left: 0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: MediaQuery.of(context).size.width * value.clamp(0.0, 1.0),
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(height / 2),
              gradient: LinearGradient(
                colors: [
                  valueColor,
                  valueColor.withOpacity(0.8),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: valueColor.withOpacity(0.5),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}