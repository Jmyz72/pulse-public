import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? eyebrow;
  final TextAlign textAlign;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.eyebrow,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final isCentered = textAlign == TextAlign.center;

    return Column(
      crossAxisAlignment: isCentered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.28),
              ),
            ),
            child: Text(
              eyebrow!,
              textAlign: textAlign,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],
        Text(
          title,
          textAlign: textAlign,
          style: const TextStyle(
            fontSize: 34,
            height: 1.05,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(
            subtitle,
            textAlign: textAlign,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
