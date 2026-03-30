import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class GlassBottomBar extends StatelessWidget {
  final Widget child;

  const GlassBottomBar({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        border: Border(
          top: BorderSide(
            color: AppColors.glassBorder,
            width: 1.5,
          ),
        ),
      ),
      child: SafeArea(
        child: child,
      ),
    );
  }
}
