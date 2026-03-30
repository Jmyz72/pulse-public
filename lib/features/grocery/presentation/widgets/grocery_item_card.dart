import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../domain/entities/grocery_item.dart';

class GroceryItemCard extends StatelessWidget {
  final GroceryItem item;
  final bool isOwner;
  final String? currentUserId;
  final VoidCallback? onImageTap;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onTap;

  const GroceryItemCard({
    super.key,
    required this.item,
    required this.isOwner,
    this.currentUserId,
    this.onImageTap,
    this.onToggle,
    this.onEdit,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        borderRadius: 24,
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.imageUrl != null && item.imageUrl!.isNotEmpty) ...[
                  GestureDetector(
                    onTap: onImageTap,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(
                        height: 140,
                        width: double.infinity,
                        child: Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.getGlassBackground(0.05),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.textTertiary,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Top row: icon, name, toggle
                Row(
                  children: [
                    IconCircle(
                      icon: _getCategoryIcon(item.category),
                      backgroundColor: AppColors.grocery.withValues(alpha: 0.2),
                      iconColor: AppColors.grocery,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: item.isPurchased
                                  ? AppColors.textTertiary
                                  : AppColors.textPrimary,
                              decoration: item.isPurchased
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _buildSpecChip(
                                theme,
                                label: 'Qty: ${item.quantity}',
                                color: AppColors.grocery,
                              ),
                              if (item.brand != null && item.brand!.isNotEmpty)
                                _buildSpecChip(
                                  theme,
                                  label: item.brand!,
                                  color: AppColors.primary,
                                ),
                              if (item.size != null && item.size!.isNotEmpty)
                                _buildSpecChip(
                                  theme,
                                  label: item.size!,
                                  color: AppColors.warning,
                                ),
                              if (item.variant != null &&
                                  item.variant!.isNotEmpty)
                                _buildSpecChip(
                                  theme,
                                  label: item.variant!,
                                  color: AppColors.secondary,
                                ),
                              if (item.category != null)
                                _buildSpecChip(
                                  theme,
                                  label: item.category!,
                                  color: AppColors.secondary,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Toggle button
                    GestureDetector(
                      onTap: onToggle,
                      child: Opacity(
                        opacity: onToggle != null ? 1.0 : 0.4,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: item.isPurchased
                                  ? AppColors.success
                                  : AppColors.glassBorder,
                              width: 2,
                            ),
                            color: item.isPurchased
                                ? AppColors.success
                                : Colors.transparent,
                          ),
                          child: item.isPurchased
                              ? const Icon(
                                  Icons.check,
                                  size: 18,
                                  color: AppColors.background,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                // Note
                if (item.note != null && item.note!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    item.note!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // Bottom row
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.person_outline,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isOwner
                                    ? 'Added by you'
                                    : 'Added by ${item.addedByName ?? 'unknown'}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (isOwner && onEdit != null) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: onEdit,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppDimensions.radiusMd,
                                      ),
                                    ),
                                    child: Text(
                                      'Edit',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (item.isPurchased &&
                              item.purchasedByName != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.shopping_cart_checkout,
                                  size: 16,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  currentUserId != null &&
                                          item.purchasedBy == currentUserId
                                      ? 'Purchased by you'
                                      : 'Purchased by ${item.purchasedByName}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    StatusBadge(
                      status: item.isPurchased
                          ? BadgeStatus.completed
                          : BadgeStatus.pending,
                      customLabel: item.isPurchased ? 'Purchased' : 'Needed',
                      isSmall: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'Produce':
        return Icons.eco;
      case 'Dairy':
        return Icons.water_drop;
      case 'Meat':
        return Icons.restaurant;
      case 'Bakery':
        return Icons.bakery_dining;
      case 'Frozen':
        return Icons.ac_unit;
      case 'Beverages':
        return Icons.local_cafe;
      case 'Snacks':
        return Icons.cookie;
      case 'Other':
        return Icons.shopping_bag;
      default:
        return Icons.shopping_cart;
    }
  }

  Widget _buildSpecChip(
    ThemeData theme, {
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
