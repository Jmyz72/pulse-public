import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/glass_card.dart';

class VisibilitySelector extends StatelessWidget {
  final String visibility;
  final ValueChanged<String> onChanged;

  const VisibilitySelector({
    super.key,
    required this.visibility,
    required this.onChanged,
  });

  static const List<VisibilityOption> options = [
    VisibilityOption(
      value: 'private',
      label: 'Private',
      description: 'Only you can see this',
      icon: Icons.lock,
    ),
    VisibilityOption(
      value: 'friends',
      label: 'Friends',
      description: 'Your friends can see this',
      icon: Icons.people,
    ),
    VisibilityOption(
      value: 'public',
      label: 'Public',
      description: 'Anyone can see this',
      icon: Icons.public,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Visibility',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppDimensions.spacingSm),
        GlassContainer(
          padding: EdgeInsets.zero,
          borderRadius: AppDimensions.radiusMd,
          borderColor: AppColors.schedule,
          borderOpacity: 0.3,
          child: Column(
            children: options.map((option) {
              final isSelected = option.value == visibility;
              final isLast = option == options.last;

              return Semantics(
                label: '${option.label}: ${option.description}',
                selected: isSelected,
                child: InkWell(
                  onTap: () => onChanged(option.value),
                  borderRadius: BorderRadius.vertical(
                    top: option == options.first
                        ? const Radius.circular(AppDimensions.radiusMd)
                        : Radius.zero,
                    bottom: isLast
                        ? const Radius.circular(AppDimensions.radiusMd)
                        : Radius.zero,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(AppDimensions.spacingMd),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.schedule.withValues(alpha: 0.1)
                          : null,
                      border: isLast
                          ? null
                          : const Border(
                              bottom: BorderSide(color: AppColors.glassBorder),
                            ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          option.icon,
                          size: 20,
                          color: isSelected
                              ? AppColors.schedule
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppDimensions.spacingMd - 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option.label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? AppColors.schedule
                                      : AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                option.description,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.schedule,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class VisibilityOption {
  final String value;
  final String label;
  final String description;
  final IconData icon;

  const VisibilityOption({
    required this.value,
    required this.label,
    required this.description,
    required this.icon,
  });
}
