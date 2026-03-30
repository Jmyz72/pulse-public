import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/entities/expense_item.dart';

class ExpenseItemCard extends StatelessWidget {
  final ExpenseItem item;
  final List<String> selectedByNames;
  final List<String> paidByNames;

  const ExpenseItemCard({
    super.key,
    required this.item,
    this.selectedByNames = const [],
    this.paidByNames = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final assignedCount = item.assignedUserIds.length;
    final hasPaidUsers = paidByNames.any((name) => name.trim().isNotEmpty);
    final selectedLabel = _formatNames(
      prefix: 'Selected by',
      names: hasPaidUsers ? const [] : selectedByNames,
    );
    final paidLabel = _formatNames(prefix: 'Paid by', names: paidByNames);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Quantity badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${item.quantity}x',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name + details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'RM ${item.price.toStringAsFixed(2)} each',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (selectedLabel != null)
                    Text(
                      selectedLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontSize: 12,
                      ),
                    ),
                  if (paidLabel != null)
                    Text(
                      paidLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'RM ${item.subtotal.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                if (assignedCount > 0)
                  Text(
                    'RM ${item.costPerPerson.toStringAsFixed(2)}/person',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _formatNames({required String prefix, required List<String> names}) {
    final sanitizedNames = names
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
    if (sanitizedNames.isEmpty) {
      return null;
    }
    return '$prefix ${sanitizedNames.join(', ')}';
  }
}
