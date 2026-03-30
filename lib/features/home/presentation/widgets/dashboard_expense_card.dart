import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Full-width expense summary card showing Total and Your Share side by side.
///
/// Displays the group expense total and the user's personal share
/// within a GlassContainer with the expense feature color border.
class DashboardExpenseCard extends StatelessWidget {
  final double totalExpenses;
  final double userShare;
  final VoidCallback onTap;

  const DashboardExpenseCard({
    super.key,
    required this.totalExpenses,
    required this.userShare,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RepaintBoundary(
      child: Semantics(
      label: 'Expenses, total RM ${totalExpenses.toStringAsFixed(2)}, '
          'your share RM ${userShare.toStringAsFixed(2)}',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          child: GlassContainer(
            borderRadius: AppDimensions.radiusXl,
            backgroundOpacity: 0.05,
            borderOpacity: 0.4,
            borderColor: AppColors.expense,
            padding: const EdgeInsets.all(AppDimensions.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section header
                Text(
                  'EXPENSES',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.expense,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingMd),
                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: _buildStat(
                        theme,
                        icon: Icons.account_balance_wallet,
                        label: 'Total',
                        value: 'RM ${totalExpenses.toStringAsFixed(2)}',
                        valueColor: AppColors.primary,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: AppColors.secondary.withValues(alpha: 0.2),
                    ),
                    const SizedBox(width: AppDimensions.spacingMd),
                    Expanded(
                      child: _buildStat(
                        theme,
                        icon: Icons.person,
                        label: 'Your Share',
                        value: 'RM ${userShare.toStringAsFixed(2)}',
                        valueColor: AppColors.neonGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildStat(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
