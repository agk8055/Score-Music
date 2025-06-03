import 'dart:math';
import 'package:flutter/material.dart';

class AudioVisualizer extends StatefulWidget {
  const AudioVisualizer({super.key});

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer> with TickerProviderStateMixin {
  late AnimationController _controller;
  List<double> _amplitudes = List.filled(16, 0.0);
  final Random _random = Random();
  double _beatValue = 0.0;
  double _targetBeat = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..addListener(_updateVisualization)
     ..repeat();
  }

  void _updateVisualization() {
    // Simulate beat detection
    if (_random.nextDouble() < 0.2) {
      _targetBeat = 0.5 + _random.nextDouble() * 0.5;
    } else {
      _targetBeat *= 0.7; // Decay
    }
    
    // Smooth transition to target beat
    _beatValue = _beatValue * 0.8 + _targetBeat * 0.2;
    
    // Create a wave-like pattern based on the beat
    final time = DateTime.now().millisecondsSinceEpoch / 500.0;
    setState(() {
      _amplitudes = List.generate(16, (i) {
        // Base wave pattern
        final wave = sin(time + i * 0.4) * 0.3 + 0.3;
        
        // Apply beat effect with some randomness
        final beatEffect = _beatValue * (0.8 + _random.nextDouble() * 0.4);
        
        // Combine wave and beat
        return min(1.0, wave * beatEffect);
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,  // Increased height
      width: double.infinity,  // Stretch to full width
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),  // Add horizontal padding
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,  // Evenly distribute bars
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(16, (index) {
            final height = 10 + 70 * _amplitudes[index];  // Increased height range
            return _BarElement(
              height: height,
              index: index,
              amplitude: _amplitudes[index],
            );
          }),
        ),
      ),
    );
  }
}

class _BarElement extends StatelessWidget {
  final double height;
  final int index;
  final double amplitude;

  const _BarElement({
    required this.height,
    required this.index,
    required this.amplitude,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate color based on amplitude (more intense yellow for higher amplitude)
    final color = Color.lerp(
      const Color(0xFFF5D505).withOpacity(0.4),
      const Color(0xFFF5D505),
      amplitude,
    )!;
    
    return Container(
      width: 6,  // Wider bars
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),  // Larger border radius
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: amplitude * 10,  // More prominent glow
            spreadRadius: amplitude * 3,  // More spread
          ),
        ],
      ),
    );
  }
}