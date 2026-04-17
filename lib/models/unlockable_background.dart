import 'package:flutter/material.dart';

class UnlockableBackground {
  final String key;
  final String name;
  final int price;
  final List<Color> fallbackColors;
  final String assetPath;

  const UnlockableBackground({
    required this.key,
    required this.name,
    required this.price,
    required this.fallbackColors,
    required this.assetPath,
  });
}