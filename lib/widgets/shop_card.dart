import 'package:flutter/material.dart';

class ShopCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool unlocked;
  final bool selected;
  final VoidCallback onTap;
  final Widget preview;

  const ShopCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.unlocked,
    required this.selected,
    required this.onTap,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 125,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withOpacity(0.05),
          border: Border.all(
            color: selected
                ? Colors.cyanAccent
                : unlocked
                    ? Colors.white24
                    : Colors.white10,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Center(child: preview)),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: unlocked ? Colors.greenAccent : Colors.amberAccent,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}