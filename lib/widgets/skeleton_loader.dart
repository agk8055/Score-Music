import 'package:flutter/material.dart';

class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.baseColor = const Color(0xFF2A2A2A),
    this.highlightColor = const Color(0xFF4A4A4A),
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
    
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
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
              stops: const [0.0, 0.35, 0.5, 0.65],
              transform: _GradientTransform(_animation.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _GradientTransform extends GradientTransform {
  final double position;

  const _GradientTransform(this.position);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * position,
      bounds.height * position,
      0.0,
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
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: ShimmerEffect(
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(borderRadius),
          ),
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
        borderRadius: 8,
      ),
      title: SkeletonLoader(
        width: MediaQuery.of(context).size.width * 0.6,
        height: 16,
        borderRadius: 4,
      ),
      subtitle: SkeletonLoader(
        width: MediaQuery.of(context).size.width * 0.4,
        height: 14,
        borderRadius: 4,
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
        borderRadius: 8,
      ),
      title: SkeletonLoader(
        width: MediaQuery.of(context).size.width * 0.6,
        height: 16,
        borderRadius: 4,
      ),
      subtitle: SkeletonLoader(
        width: MediaQuery.of(context).size.width * 0.4,
        height: 14,
        borderRadius: 4,
      ),
    );
  }
}