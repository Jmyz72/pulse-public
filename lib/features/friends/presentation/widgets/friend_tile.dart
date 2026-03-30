import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../../../shared/widgets/glass_card.dart';

class FriendTile extends StatelessWidget {
  final String name;
  final String email;
  final String? username;
  final String? imageUrl;
  final String? statusLabel;
  final Color? statusColor;
  final String? helperText;
  final Widget? trailing;
  final List<Widget> actions;
  final VoidCallback? onTap;
  final bool showChevron;

  const FriendTile({
    super.key,
    required this.name,
    required this.email,
    this.username,
    this.imageUrl,
    this.statusLabel,
    this.statusColor,
    this.helperText,
    this.trailing,
    this.actions = const [],
    this.onTap,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedStatusColor = statusColor ?? AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingMd),
      child: GlassCard(
        onTap: onTap,
        borderRadius: 28,
        backgroundOpacity: 0.06,
        borderOpacity: 0.45,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AvatarWidget(imageUrl: imageUrl, name: name, size: 54),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (username != null && username!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '@$username',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (helperText != null && helperText!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          helperText!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textTertiary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (statusLabel != null && statusLabel!.isNotEmpty ||
                    trailing != null ||
                    (actions.isEmpty && showChevron))
                  const SizedBox(width: 12),
                if (statusLabel != null && statusLabel!.isNotEmpty ||
                    trailing != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (statusLabel != null && statusLabel!.isNotEmpty)
                        _StatusPill(
                          label: statusLabel!,
                          color: resolvedStatusColor,
                        ),
                      if (trailing != null) ...[
                        if (statusLabel != null && statusLabel!.isNotEmpty)
                          const SizedBox(height: 8),
                        trailing!,
                      ],
                    ],
                  )
                else if (actions.isEmpty && showChevron)
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppColors.textTertiary.withValues(alpha: 0.9),
                  ),
              ],
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Divider(
                color: AppColors.secondary.withValues(alpha: 0.18),
                height: 1,
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: actions,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
