import 'package:flutter/material.dart';

class BackgroundDotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    final dots = [
      const Offset(40, 90),
      const Offset(110, 180),
      const Offset(260, 120),
      const Offset(320, 240),
      const Offset(80, 350),
      const Offset(280, 420),
      const Offset(150, 500),
      const Offset(340, 620),
      const Offset(30, 680),
      const Offset(200, 760),
    ];

    for (final dot in dots) {
      paint.color = Colors.white.withOpacity(0.08);
      canvas.drawCircle(dot, 2.2, paint);

      paint.color = Colors.cyanAccent.withOpacity(0.04);
      canvas.drawCircle(dot, 6.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}