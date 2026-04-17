import 'package:flutter/material.dart';

class FloatingText {
  final int id;
  Offset position;
  final String text;
  final Color color;
  double life;
  final double maxLife;

  FloatingText({
    required this.id,
    required this.position,
    required this.text,
    required this.color,
    required this.life,
  }) : maxLife = life;
}