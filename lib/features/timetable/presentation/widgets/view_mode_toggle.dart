import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../bloc/timetable_bloc.dart';

/// Compact weekly / daily toggle used in the app bar actions slot.
class ViewModeToggle extends StatelessWidget {
  final ViewMode viewMode;
  final ValueChanged<ViewMode> onChanged;

  const ViewModeToggle({
    super.key,
    required this.viewMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingXs,
        vertical: AppDimensions.spacingXs,
      ),
      borderRadius: AppDimensions.radiusMd,
      borderColor: AppColors.schedule,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: 'Weekly view',
            selected: viewMode == ViewMode.weekly,
            child: _ToggleIcon(
              icon: Icons.calendar_view_week,
              isActive: viewMode == ViewMode.weekly,
              tooltip: 'Weekly View',
              onTap: () => onChanged(ViewMode.weekly),
            ),
          ),
          Semantics(
            label: 'Daily view',
            selected: viewMode == ViewMode.daily,
            child: _ToggleIcon(
              icon: Icons.view_day,
              isActive: viewMode == ViewMode.daily,
              tooltip: 'Daily View',
              onTap: () => onChanged(ViewMode.daily),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final String tooltip;
  final VoidCallback onTap;

  const _ToggleIcon({
    required this.icon,
    required this.isActive,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        icon,
        color: isActive ? AppColors.schedule : AppColors.textTertiary,
      ),
      onPressed: onTap,
      tooltip: tooltip,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      padding: EdgeInsets.zero,
      iconSize: AppDimensions.iconMd,
      style: IconButton.styleFrom(
        backgroundColor: isActive
            ? AppColors.schedule.withValues(alpha: 0.15)
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
      ),
    );
  }
}
