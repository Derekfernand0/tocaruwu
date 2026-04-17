import 'package:flutter/material.dart';

class UnlockableSkin {
  final String key;
  final String name;
  final int price;
  final List<Color> colors;
  final String assetPath;

  const UnlockableSkin({
    required this.key,
    required this.name,
    required this.price,
    required this.colors,
    required this.assetPath,
  });
}