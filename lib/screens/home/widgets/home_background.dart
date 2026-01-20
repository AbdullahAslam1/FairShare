// ============================================
// FILE: lib/screens/home/widgets/home_background.dart
// Animated Background Widget
// ============================================

import 'dart:math' as math;
import 'package:flutter/material.dart';

class HomeBackground extends StatelessWidget {
  final Size size;
  final AnimationController animationController;

  const HomeBackground({
    Key? key,
    required this.size,
    required this.animationController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base dark gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A0E27), Color(0xFF1A1F3A), Color(0xFF0D1B2A)],
            ),
          ),
        ),

        // Animated orbs
        Positioned(
          top: -size.height * 0.2,
          left: -size.width * 0.3,
          child: AnimatedOrb(
            controller: animationController,
            size: size.width * 1.3,
            colors: [
              const Color(0xFF14B8A6).withOpacity(0.3),
              const Color(0xFF0D9488).withOpacity(0.1),
            ],
          ),
        ),
        Positioned(
          top: size.height * 0.1,
          right: -size.width * 0.3,
          child: AnimatedOrb(
            controller: animationController,
            size: size.width * 1.0,
            colors: [
              const Color(0xFF8B5CF6).withOpacity(0.25),
              const Color(0xFF7C3AED).withOpacity(0.1),
            ],
            reversed: true,
          ),
        ),

        // Noise texture overlay
        Positioned.fill(
          child: Opacity(
            opacity: 0.03,
            child: CustomPaint(painter: NoisePainter()),
          ),
        ),
      ],
    );
  }
}

class AnimatedOrb extends StatelessWidget {
  final AnimationController controller;
  final double size;
  final List<Color> colors;
  final bool reversed;

  const AnimatedOrb({
    Key? key,
    required this.controller,
    required this.size,
    required this.colors,
    this.reversed = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: controller.value * 2 * math.pi * (reversed ? -1 : 1),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: colors, stops: const [0.0, 1.0]),
            ),
          ),
        );
      },
    );
  }
}

class NoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;

    final random = math.Random(42);
    for (var i = 0; i < 1000; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
