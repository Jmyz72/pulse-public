import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../expense/presentation/widgets/expense_stat_chip.dart';

class GrocerySummaryCard extends StatelessWidget {
  final int totalItems;
  final int neededCount;
  final int purchasedCount;

  const GrocerySummaryCard({
    super.key,
    required this.totalItems,
    required this.neededCount,
    required this.purchasedCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.grocery, AppColors.secondary],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  totalItems == 0
                      ? 'Shopping List'
                      : '$totalItems ${totalItems == 1 ? 'item' : 'items'} total',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$neededCount ${neededCount == 1 ? 'item' : 'items'} to buy',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ExpenseStatChip(
                  count: '$neededCount',
                  label: 'Needed',
                  dotColor: AppColors.warning,
                ),
                const SizedBox(height: 6),
                ExpenseStatChip(
                  count: '$purchasedCount',
                  label: 'Done',
                  dotColor: AppColors.success,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
