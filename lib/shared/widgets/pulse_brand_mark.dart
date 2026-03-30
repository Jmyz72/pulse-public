import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class PulseBrandMark extends StatelessWidget {
  final double size;
  final double borderRadiusFactor;

  const PulseBrandMark({
    super.key,
    this.size = 100,
    this.borderRadiusFactor = 0.32,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PulseBrandMarkPainter(borderRadiusFactor: borderRadiusFactor),
      ),
    );
  }
}

class _PulseBrandMarkPainter extends CustomPainter {
  final double borderRadiusFactor;

  const _PulseBrandMarkPainter({required this.borderRadiusFactor});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = Radius.circular(size.shortestSide * borderRadiusFactor);
    final rrect = RRect.fromRectAndRadius(rect, radius);

    canvas.save();
    canvas.clipRRect(rrect);

    final backgroundPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primary, AppColors.secondary],
      ).createShader(rect);
    canvas.drawRRect(rrect, backgroundPaint);

    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.55, -0.65),
        radius: 1.05,
        colors: [Colors.white.withValues(alpha: 0.34), Colors.transparent],
      ).createShader(rect);
    canvas.drawRect(rect, glowPaint);

    final beamPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white.withValues(alpha: 0.10), Colors.transparent],
      ).createShader(rect);
    canvas.drawRect(rect, beamPaint);
    canvas.restore();

    final outerBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.016
      ..color = Colors.white.withValues(alpha: 0.14);
    canvas.drawRRect(rrect.deflate(size.shortestSide * 0.008), outerBorder);

    final innerRect = rect.deflate(size.shortestSide * 0.14);
    final innerRRect = RRect.fromRectAndRadius(
      innerRect,
      Radius.circular(size.shortestSide * 0.18),
    );
    final innerBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.014
      ..color = Colors.white.withValues(alpha: 0.18);
    canvas.drawRRect(innerRRect, innerBorder);

    final coreCenter = Offset(size.width * 0.5, size.height * 0.54);
    final coreRadius = size.shortestSide * 0.22;
    final coreRect = Rect.fromCircle(center: coreCenter, radius: coreRadius);
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.backgroundLight.withValues(alpha: 0.96),
          AppColors.background.withValues(alpha: 0.98),
        ],
      ).createShader(coreRect);
    canvas.drawCircle(coreCenter, coreRadius, corePaint);

    final coreBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.016
      ..color = AppColors.primary.withValues(alpha: 0.30);
    canvas.drawCircle(coreCenter, coreRadius, coreBorder);

    final pulsePath = Path()
      ..moveTo(size.width * 0.32, size.height * 0.56)
      ..lineTo(size.width * 0.42, size.height * 0.56)
      ..lineTo(size.width * 0.485, size.height * 0.44)
      ..lineTo(size.width * 0.545, size.height * 0.65)
      ..lineTo(size.width * 0.62, size.height * 0.52)
      ..lineTo(size.width * 0.69, size.height * 0.52);

    final glowStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = AppColors.primary.withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(pulsePath, glowStroke);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.055
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader =
          LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.white.withValues(alpha: 0.95),
              AppColors.primaryLight,
            ],
          ).createShader(
            Rect.fromLTWH(
              size.width * 0.3,
              size.height * 0.42,
              size.width * 0.45,
              size.height * 0.22,
            ),
          );
    canvas.drawPath(pulsePath, strokePaint);

    final dotCenter = Offset(size.width * 0.72, size.height * 0.52);
    final dotRadius = size.shortestSide * 0.043;
    final dotGlow = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(dotCenter, dotRadius * 1.7, dotGlow);

    final dotPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Colors.white, AppColors.primaryLight],
      ).createShader(Rect.fromCircle(center: dotCenter, radius: dotRadius));
    canvas.drawCircle(dotCenter, dotRadius, dotPaint);

    final pingCenter = Offset(size.width * 0.72, size.height * 0.25);
    final pingPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.018;
    canvas.drawCircle(pingCenter, size.shortestSide * 0.055, pingPaint);
    canvas.drawCircle(
      pingCenter,
      size.shortestSide * 0.022,
      Paint()..color = Colors.white.withValues(alpha: 0.72),
    );
  }

  @override
  bool shouldRepaint(covariant _PulseBrandMarkPainter oldDelegate) {
    return oldDelegate.borderRadiusFactor != borderRadiusFactor;
  }
}
