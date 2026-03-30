import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class AuthGradientBackground extends StatelessWidget {
  final Widget child;

  const AuthGradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF041015), Color(0xFF071B22), AppColors.background],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(
            top: -120,
            right: -80,
            child: _GlowOrb(size: 320, color: AppColors.primary, opacity: 0.18),
          ),
          const Positioned(
            top: 180,
            left: -120,
            child: _GlowOrb(
              size: 260,
              color: AppColors.neonMagenta,
              opacity: 0.12,
            ),
          ),
          const Positioned(
            bottom: -150,
            right: -30,
            child: _GlowOrb(
              size: 360,
              color: AppColors.secondary,
              opacity: 0.16,
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _GridPainter())),
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x08FFFFFF),
                      Colors.transparent,
                      Color(0x38050C10),
                    ],
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _GlowOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: opacity * 0.42),
            Colors.transparent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: opacity * 0.75),
            blurRadius: 90,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    const spacing = 38.0;

    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }

    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final beamPaint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.14),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromLTWH(size.width * 0.55, 0, size.width * 0.35, size.height),
          );

    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.55, 0, size.width * 0.35, size.height),
      beamPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
