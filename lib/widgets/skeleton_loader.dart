import 'package:flutter/material.dart';
import 'dart:ui';

class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 2000),
    this.baseColor = const Color(0xFF2A2A2A),
    this.highlightColor = const Color(0xFF4A4A4A),
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                0.0,
                _animation.value - 0.5,
                _animation.value + 0.5,
                1.0,
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}

class SongSkeletonLoader extends StatelessWidget {
  const SongSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const SkeletonLoader(
        width: 56,
        height: 56,
        borderRadius: 4,
      ),
      title: SkeletonLoader(
        width: MediaQuery.of(context).size.width * 0.6,
        height: 16,
      ),
      subtitle: SkeletonLoader(
        width: MediaQuery.of(context).size.width * 0.4,
        height: 14,
      ),
    );
  }
}

class AlbumSkeletonLoader extends StatelessWidget {
  const AlbumSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const SkeletonLoader(
        width: 56,
        height: 56,
        borderRadius: 4,
      ),
      title: SkeletonLoader(
        width: MediaQuery.of(context).size.width * 0.6,
        height: 16,
      ),
      subtitle: SkeletonLoader(
        width: MediaQuery.of(context).size.width * 0.4,
        height: 14,
      ),
    );
  }
} 