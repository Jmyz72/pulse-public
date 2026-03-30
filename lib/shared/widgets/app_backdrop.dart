import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class AppBackdrop extends StatelessWidget {
  final Widget child;

  const AppBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.backdropTop,
            AppColors.background,
            AppColors.backdropBottom,
          ],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(
            top: -140,
            left: -110,
            child: _BackdropGlow(
              size: 360,
              color: AppColors.backdropGlowA,
              opacity: 0.22,
            ),
          ),
          const Positioned(
            top: 120,
            right: -120,
            child: _BackdropGlow(
              size: 320,
              color: AppColors.backdropGlowB,
              opacity: 0.16,
            ),
          ),
          const Positioned(
            bottom: -180,
            left: 10,
            child: _BackdropGlow(
              size: 430,
              color: AppColors.backdropGlowC,
              opacity: 0.14,
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _BackdropPainter())),
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x22FFFFFF),
                      Colors.transparent,
                      Color(0x22000000),
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

class _BackdropGlow extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _BackdropGlow({
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
            color.withValues(alpha: opacity * 0.45),
            Colors.transparent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: opacity * 0.75),
            blurRadius: 110,
            spreadRadius: 12,
          ),
        ],
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sweepPaint = Paint()
      ..shader =
          const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0x26FFFFFF),
              Colors.transparent,
              Color(0x1AFFFFFF),
            ],
          ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final topArc = Path()
      ..moveTo(size.width * -0.1, size.height * 0.18)
      ..quadraticBezierTo(
        size.width * 0.32,
        size.height * 0.02,
        size.width * 0.82,
        size.height * 0.18,
      )
      ..quadraticBezierTo(
        size.width * 1.05,
        size.height * 0.26,
        size.width * 1.1,
        size.height * 0.22,
      );

    final bottomArc = Path()
      ..moveTo(size.width * -0.05, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.62,
        size.width * 0.62,
        size.height * 0.74,
      )
      ..quadraticBezierTo(
        size.width * 0.9,
        size.height * 0.84,
        size.width * 1.08,
        size.height * 0.68,
      );

    canvas.drawPath(topArc, sweepPaint);
    canvas.drawPath(bottomArc, sweepPaint);

    final linePaint = Paint()
      ..color = AppColors.backdropLine
      ..strokeWidth = 1;

    for (double x = -size.width * 0.2; x < size.width * 1.1; x += 64) {
      canvas.drawLine(
        Offset(x, size.height * 0.86),
        Offset(x + 120, size.height * 0.66),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
