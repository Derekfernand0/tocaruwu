import 'package:flutter/material.dart';

class GlowingBall extends StatelessWidget {
  final double size;
  final Color primary;
  final Color secondary;
  final VoidCallback onTap;
  final String? skinAssetPath;

  const GlowingBall({
    super.key,
    required this.size,
    required this.primary,
    required this.secondary,
    required this.onTap,
    this.skinAssetPath,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(0.55),
              blurRadius: 20,
              spreadRadius: 3,
            ),
            BoxShadow(
              color: secondary.withOpacity(0.30),
              blurRadius: 30,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipOval(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.25, -0.3),
                    radius: 0.98,
                    colors: [
                      Colors.white.withOpacity(0.92),
                      primary,
                      secondary,
                    ],
                    stops: const [0.04, 0.45, 1.0],
                  ),
                ),
              ),
              if (skinAssetPath != null)
                Positioned.fill(
                  child: Image.asset(
                    skinAssetPath!,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.low,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
              Positioned(
                top: size * 0.14,
                left: size * 0.14,
                child: Container(
                  width: size * 0.16,
                  height: size * 0.16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.75),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
