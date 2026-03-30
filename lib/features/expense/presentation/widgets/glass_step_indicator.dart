import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class GlassStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;

  const GlassStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(totalSteps * 2 - 1, (index) {
          if (index.isOdd) {
            // Connecting line
            final stepBefore = index ~/ 2;
            final isCompleted = stepBefore < currentStep;
            return Expanded(
              child: Container(
                height: 2,
                color: isCompleted
                    ? AppColors.primary
                    : AppColors.textTertiary,
              ),
            );
          }

          final stepIndex = index ~/ 2;
          final isCompleted = stepIndex < currentStep;
          final isCurrent = stepIndex == currentStep;

          return _buildStepCircle(
            context,
            stepIndex: stepIndex,
            isCompleted: isCompleted,
            isCurrent: isCurrent,
          );
        }),
      ),
    );
  }

  Widget _buildStepCircle(
    BuildContext context, {
    required int stepIndex,
    required bool isCompleted,
    required bool isCurrent,
  }) {
    final label = stepIndex < stepLabels.length ? stepLabels[stepIndex] : '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? AppColors.primary
                : isCurrent
                    ? Colors.transparent
                    : Colors.transparent,
            border: Border.all(
              color: isCompleted || isCurrent
                  ? AppColors.primary
                  : AppColors.textTertiary,
              width: 2,
            ),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(
                    Icons.check,
                    size: 18,
                    color: AppColors.background,
                  )
                : Text(
                    '${stepIndex + 1}',
                    style: TextStyle(
                      color: isCurrent
                          ? AppColors.primary
                          : AppColors.textTertiary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isCompleted || isCurrent
                ? AppColors.primary
                : AppColors.textTertiary,
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
