import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import 'auth_gradient_background.dart';
import 'auth_logo.dart';

class AuthFlowScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? eyebrow;
  final Widget child;
  final Widget? footer;
  final bool showBackButton;
  final VoidCallback? onBack;
  final double maxWidth;

  const AuthFlowScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.eyebrow,
    this.footer,
    this.showBackButton = false,
    this.onBack,
    this.maxWidth = 480,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthGradientBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth > 680
                  ? constraints.maxWidth * 0.14
                  : AppDimensions.spacingLg;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  AppDimensions.spacingSm,
                  horizontalPadding,
                  AppDimensions.spacingLg,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showBackButton)
                          IconButton(
                            alignment: Alignment.centerLeft,
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: AppColors.textPrimary,
                            ),
                            onPressed:
                                onBack ?? () => Navigator.of(context).pop(),
                          ),
                        _AuthFlowHeader(
                          eyebrow: eyebrow,
                          title: title,
                          subtitle: subtitle,
                        ),
                        const SizedBox(height: AppDimensions.spacingLg),
                        child,
                        if (footer != null) ...[
                          const SizedBox(height: AppDimensions.spacingLg),
                          footer!,
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AuthFlowHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? eyebrow;

  const _AuthFlowHeader({
    required this.title,
    required this.subtitle,
    this.eyebrow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingSm),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.24),
              ),
            ),
            child: const AuthLogo(size: 28),
          ),
          const SizedBox(width: AppDimensions.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) ...[
                  Text(
                    eyebrow!,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
