import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../chat/presentation/bloc/chat_bloc.dart';
import '../../../chat/presentation/screens/new_chat_sheet.dart';
import '../../../../shared/widgets/glass_card.dart';

/// A row of 4 equally-spaced creation-first quick action buttons.
///
/// Each button is a small GlassContainer with an icon and short label.
class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QuickAction(
          icon: Icons.add_card,
          label: 'Expense',
          color: AppColors.expense,
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.addExpense,
            arguments: {'chatRooms': context.read<ChatBloc>().state.chatRooms},
          ),
        ),
        const SizedBox(width: AppDimensions.spacingSm),
        _QuickAction(
          icon: Icons.person_add_alt_1,
          label: 'Add Friend',
          color: AppColors.primary,
          onTap: () => Navigator.pushNamed(context, AppRoutes.addFriend),
        ),
        const SizedBox(width: AppDimensions.spacingSm),
        _QuickAction(
          icon: Icons.edit_outlined,
          label: 'New Chat',
          color: AppColors.neonMagenta,
          onTap: () => NewChatSheet.show(context),
        ),
        const SizedBox(width: AppDimensions.spacingSm),
        _QuickAction(
          icon: Icons.calendar_today,
          label: 'Schedule',
          color: AppColors.schedule,
          onTap: () => Navigator.pushNamed(context, AppRoutes.timetable),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Semantics(
        label: label,
        button: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            child: GlassContainer(
              borderRadius: AppDimensions.radiusLg,
              backgroundOpacity: 0.05,
              borderOpacity: 0.3,
              borderColor: color,
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.spacingSm + 4,
                horizontal: AppDimensions.spacingXs,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
