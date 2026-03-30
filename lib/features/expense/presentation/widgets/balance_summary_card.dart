import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class BalanceSummaryCard extends StatelessWidget {
  final double netBalance;
  final double totalOwedToUser;
  final double totalUserOwes;

  const BalanceSummaryCard({
    super.key,
    required this.netBalance,
    required this.totalOwedToUser,
    required this.totalUserOwes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            'Net Balance',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${netBalance >= 0 ? '+' : ''}RM ${netBalance.toStringAsFixed(2)}',
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            netBalance >= 0 ? 'You are owed' : 'You owe',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBalanceItem(
                theme,
                'You are owed',
                totalOwedToUser,
                AppColors.success,
                Icons.arrow_downward,
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white24,
              ),
              _buildBalanceItem(
                theme,
                'You owe',
                totalUserOwes,
                AppColors.warning,
                Icons.arrow_upward,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(
    ThemeData theme,
    String label,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'RM ${amount.toStringAsFixed(2)}',
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
