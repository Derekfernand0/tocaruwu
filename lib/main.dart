import 'package:flutter/material.dart';
import 'screens/game_screen.dart';

void main() {
  runApp(const HyperTapApp());
}

class HyperTapApp extends StatelessWidget {
  const HyperTapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HyperTap Legends',
      theme: ThemeData.dark(),
      home: const GameScreen(),
    );
  }
}