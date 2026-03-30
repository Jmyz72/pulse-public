import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../domain/entities/expense.dart';
import '../../../../core/utils/date_formatter.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final splitCount = expense.splits.isNotEmpty ? expense.splits.length : 1;
    final isSettled = expense.status == ExpenseStatus.settled;
    final paidCount = expense.paidSplitsCount;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        borderRadius: 24,
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconCircle(
                      icon: _getTypeIcon(expense.type),
                      backgroundColor: AppColors.expense.withValues(alpha: 0.2),
                      iconColor: AppColors.expense,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expense.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormatter.formatDate(expense.date),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'RM ${expense.totalAmount.toStringAsFixed(2)}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        if (splitCount > 1)
                          Text(
                            '${(expense.totalAmount / splitCount).toStringAsFixed(2)} each',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                if (expense.description != null &&
                    expense.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    expense.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.people,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          splitCount > 1
                              ? '$splitCount people'
                              : 'Personal expense',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (!isSettled && splitCount > 1) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$paidCount/$splitCount paid',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    StatusBadge(
                      status: isSettled
                          ? BadgeStatus.paid
                          : BadgeStatus.pending,
                      customLabel: isSettled ? 'Settled' : 'Pending',
                    ),
                  ],
                ),
                // Progress bar for payment
                if (!isSettled && splitCount > 1) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: paidCount / splitCount,
                      backgroundColor: AppColors.progressTrack,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        paidCount == splitCount - 1
                            ? AppColors.warning
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static IconData _getTypeIcon(ExpenseType type) {
    switch (type) {
      case ExpenseType.group:
        return Icons.groups;
      case ExpenseType.oneOnOne:
        return Icons.people;
      case ExpenseType.adHoc:
        return Icons.swap_horiz;
    }
  }
}
