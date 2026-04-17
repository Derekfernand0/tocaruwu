import 'power_type.dart';

class SpawnedPower {
  final int id;
  final PowerType type;
  double x;
  double y;
  double life;
  final double maxLife;

  SpawnedPower({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.life,
  }) : maxLife = life;
}