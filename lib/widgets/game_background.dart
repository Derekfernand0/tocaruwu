import 'package:flutter/material.dart';
import '../models/unlockable_background.dart';
import '../painters/background_dots_painter.dart';

class GameBackground extends StatelessWidget {
  final UnlockableBackground background;

  const GameBackground({
    super.key,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.55),
              radius: 1.25,
              colors: background.fallbackColors,
            ),
          ),
        ),
        Positioned.fill(
          child: Opacity(
            opacity: 0.55,
            child: Image.asset(
              background.assetPath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return CustomPaint(
                  painter: BackgroundDotsPainter(),
                  child: Container(),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}