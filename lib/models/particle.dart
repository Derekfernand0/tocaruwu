import 'dart:ui';

class Particle {
  Offset position;
  Offset velocity;
  double life;
  final double maxLife;
  final Color color;
  final double size;

  Particle({
    required this.position,
    required this.velocity,
    required this.life,
    required this.color,
    required this.size,
  }) : maxLife = life;
}