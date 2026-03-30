import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/entities/expense_split.dart';

class ExpenseSplitCard extends StatelessWidget {
  final ExpenseSplit split;
  final bool isCurrentUser;
  final bool isOwner;
  final bool isExpenseOwner;
  final bool isPending;
  final bool hasItems;
  final VoidCallback? onActionPressed;
  final String? actionLabel;

  const ExpenseSplitCard({
    super.key,
    required this.split,
    required this.isCurrentUser,
    required this.isOwner,
    this.isExpenseOwner = false,
    this.isPending = true,
    this.hasItems = false,
    this.onActionPressed,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _statusPresentation(split.paymentStatus);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        borderRadius: 24,
        backgroundOpacity: isCurrentUser ? 0.1 : 0.05,
        borderColor: isCurrentUser ? AppColors.primary : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: status.color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(status.icon, color: status.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    split.userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (isCurrentUser || isExpenseOwner) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (isCurrentUser) _buildBadge(label: 'You'),
                        if (isExpenseOwner)
                          _buildBadge(
                            label: 'Owner',
                            backgroundColor: AppColors.secondary.withValues(
                              alpha: 0.2,
                            ),
                            textColor: AppColors.secondary,
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _subtitle(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _subtitleColor(),
                    ),
                  ),
                  if (split.isRejected &&
                      (split.proofRejectionReason?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 4),
                    Text(
                      split.proofRejectionReason!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'RM ${split.amount.toStringAsFixed(2)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    status.label,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: status.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (actionLabel != null &&
                      actionLabel!.isNotEmpty &&
                      onActionPressed != null) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: onActionPressed,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(actionLabel!),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _subtitle() {
    if (split.hasSelectedItems) {
      return '${split.itemIds.length} items selected';
    }
    if (hasItems) {
      return 'Items not selected';
    }
    if (split.needsReview) {
      return 'Payment proof submitted';
    }
    if (split.isRejected) {
      return 'Payment proof rejected';
    }
    if (split.isPaid) {
      return 'Payment received';
    }
    return 'Awaiting payment proof';
  }

  Color _subtitleColor() {
    if (split.hasSelectedItems) {
      return AppColors.textSecondary;
    }
    if (hasItems) {
      return AppColors.warning;
    }
    if (split.isRejected) {
      return AppColors.error;
    }
    if (split.needsReview) {
      return AppColors.warning;
    }
    if (split.isPaid) {
      return AppColors.success;
    }
    return AppColors.textSecondary;
  }

  Widget _buildBadge({
    required String label,
    Color backgroundColor = AppColors.primary,
    Color textColor = AppColors.background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  _SplitStatusPresentation _statusPresentation(ExpensePaymentStatus status) {
    switch (status) {
      case ExpensePaymentStatus.proofSubmitted:
        return const _SplitStatusPresentation(
          label: 'Pending Review',
          color: AppColors.warning,
          icon: Icons.pending_actions,
        );
      case ExpensePaymentStatus.paid:
        return const _SplitStatusPresentation(
          label: 'Paid',
          color: AppColors.success,
          icon: Icons.check,
        );
      case ExpensePaymentStatus.proofRejected:
        return const _SplitStatusPresentation(
          label: 'Rejected',
          color: AppColors.error,
          icon: Icons.cancel_outlined,
        );
      case ExpensePaymentStatus.unpaid:
        return const _SplitStatusPresentation(
          label: 'Unpaid',
          color: AppColors.warning,
          icon: Icons.schedule,
        );
    }
  }
}

class _SplitStatusPresentation {
  final String label;
  final Color color;
  final IconData icon;

  const _SplitStatusPresentation({
    required this.label,
    required this.color,
    required this.icon,
  });
}
