import 'package:flutter/material.dart';
import '../models/power_type.dart';

class PowerIcon extends StatelessWidget {
  final PowerType type;
  final double size;
  final double opacity;

  const PowerIcon({
    super.key,
    required this.type,
    this.size = 46,
    this.opacity = 1,
  });

  String _asset() {
    switch (type) {
      case PowerType.time:
        return 'assets/icons/power_time.png';
      case PowerType.freeze:
        return 'assets/icons/power_freeze.png';
      case PowerType.doubleBall:
        return 'assets/icons/power_double_ball.png';
      case PowerType.x2:
        return 'assets/icons/power_x2.png';
      case PowerType.magnet:
        return 'assets/icons/power_magnet.png';
      case PowerType.slowmo:
        return 'assets/icons/power_slowmo.png';
    }
  }

  Color _color() {
    switch (type) {
      case PowerType.time:
        return Colors.greenAccent;
      case PowerType.freeze:
        return Colors.lightBlueAccent;
      case PowerType.doubleBall:
        return Colors.purpleAccent;
      case PowerType.x2:
        return Colors.orangeAccent;
      case PowerType.magnet:
        return Colors.cyanAccent;
      case PowerType.slowmo:
        return Colors.indigoAccent;
    }
  }

  IconData _fallbackIcon() {
    switch (type) {
      case PowerType.time:
        return Icons.access_time;
      case PowerType.freeze:
        return Icons.ac_unit;
      case PowerType.doubleBall:
        return Icons.blur_on;
      case PowerType.x2:
        return Icons.exposure_plus_2;
      case PowerType.magnet:
        return Icons.blur_circular;
      case PowerType.slowmo:
        return Icons.slow_motion_video;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();

    return Opacity(
      opacity: opacity,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white.withOpacity(0.20),
              color.withOpacity(0.25),
              Colors.transparent,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.55),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            _asset(),
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) {
              return Container(
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                alignment: Alignment.center,
                child: Icon(_fallbackIcon(), color: Colors.white, size: 22),
              );
            },
          ),
        ),
      ),
    );
  }
}
