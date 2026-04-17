import 'package:flutter/material.dart';
import '../models/unlockable_background.dart';
import '../models/unlockable_skin.dart';

class GameData {
  static const List<UnlockableSkin> skins = [
    UnlockableSkin(
      key: 'default',
      name: 'Default',
      price: 0,
      assetPath: 'assets/skins/skin_default.png',
      colors: [Color(0xFF55F5FF), Color(0xFF1B7CFF)],
    ),
    UnlockableSkin(
      key: 'plasma',
      name: 'Plasma',
      price: 180,
      assetPath: 'assets/skins/skin_plasma.png',
      colors: [Color(0xFFFF5FD7), Color(0xFF8A2BE2)],
    ),
    UnlockableSkin(
      key: 'gold',
      name: 'Gold',
      price: 380,
      assetPath: 'assets/skins/skin_gold.png',
      colors: [Color(0xFFFFF176), Color(0xFFFFA000)],
    ),
    UnlockableSkin(
      key: 'void',
      name: 'Void',
      price: 620,
      assetPath: 'assets/skins/skin_void.png',
      colors: [Color(0xFF9C27B0), Color(0xFF111111)],
    ),
    UnlockableSkin(
      key: 'ice',
      name: 'Ice',
      price: 900,
      assetPath: 'assets/skins/skin_ice.png',
      colors: [Color(0xFFB3E5FC), Color(0xFF00BCD4)],
    ),
  ];

  static const List<UnlockableBackground> backgrounds = [
    UnlockableBackground(
      key: 'stars',
      name: 'Stars',
      price: 0,
      assetPath: 'assets/backgrounds/bg_stars.png',
      fallbackColors: [Color(0xFF0E1730), Color(0xFF090D18), Colors.black],
    ),
    UnlockableBackground(
      key: 'nebula',
      name: 'Nebula',
      price: 260,
      assetPath: 'assets/backgrounds/bg_nebula.png',
      fallbackColors: [Color(0xFF251145), Color(0xFF0B1020), Colors.black],
    ),
    UnlockableBackground(
      key: 'grid',
      name: 'Grid',
      price: 480,
      assetPath: 'assets/backgrounds/bg_grid.png',
      fallbackColors: [Color(0xFF0A2030), Color(0xFF05070F), Colors.black],
    ),
    UnlockableBackground(
      key: 'void',
      name: 'Void',
      price: 760,
      assetPath: 'assets/backgrounds/bg_void.png',
      fallbackColors: [Color(0xFF140720), Color(0xFF05020A), Colors.black],
    ),
    UnlockableBackground(
      key: 'sunset',
      name: 'Sunset',
      price: 1100,
      assetPath: 'assets/backgrounds/bg_sunset.png',
      fallbackColors: [Color(0xFF3A1026), Color(0xFF120814), Colors.black],
    ),
  ];
}