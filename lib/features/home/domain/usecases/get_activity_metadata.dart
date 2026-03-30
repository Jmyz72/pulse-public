import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../entities/dashboard_data.dart';

class ResolvedActivityPresentation {
  final IconData icon;
  final Color color;
  final String? routeName;
  final Map<String, dynamic>? arguments;

  const ResolvedActivityPresentation({
    required this.icon,
    required this.color,
    this.routeName,
    this.arguments,
  });

  VoidCallback? buildOnTap(BuildContext context) {
    if (routeName == null) {
      return null;
    }

    return () => Navigator.pushNamed(context, routeName!, arguments: arguments);
  }
}

class ActivityMetadata {
  ActivityMetadata._();

  static bool isSupported(RecentActivity activity) {
    switch (activity.type) {
      case DashboardActivityType.expense:
      case DashboardActivityType.task:
      case DashboardActivityType.grocery:
      case DashboardActivityType.bill:
      case DashboardActivityType.chat:
        return true;
      case DashboardActivityType.event:
      case DashboardActivityType.location:
      case DashboardActivityType.timetable:
        return false;
    }
  }

  static ResolvedActivityPresentation resolve(RecentActivity activity) {
    switch (activity.type) {
      case DashboardActivityType.expense:
        final hasSourceId = activity.sourceId.isNotEmpty;
        return ResolvedActivityPresentation(
          icon: Icons.shopping_bag,
          color: AppColors.expense,
          routeName: hasSourceId ? AppRoutes.expenseDetails : AppRoutes.expense,
          arguments: hasSourceId ? {'expenseId': activity.sourceId} : null,
        );
      case DashboardActivityType.task:
        return const ResolvedActivityPresentation(
          icon: Icons.task_alt,
          color: AppColors.task,
          routeName: AppRoutes.tasks,
        );
      case DashboardActivityType.event:
        return const ResolvedActivityPresentation(
          icon: Icons.event,
          color: AppColors.event,
        );
      case DashboardActivityType.location:
        return const ResolvedActivityPresentation(
          icon: Icons.location_on,
          color: AppColors.location,
        );
      case DashboardActivityType.grocery:
        return const ResolvedActivityPresentation(
          icon: Icons.add_shopping_cart,
          color: AppColors.grocery,
          routeName: AppRoutes.grocery,
        );
      case DashboardActivityType.bill:
        return const ResolvedActivityPresentation(
          icon: Icons.payment,
          color: AppColors.bill,
          routeName: AppRoutes.livingTools,
        );
      case DashboardActivityType.chat:
        final chatRoomId = activity.chatRoomId;
        return ResolvedActivityPresentation(
          icon: Icons.chat_bubble,
          color: AppColors.neonMagenta,
          routeName: chatRoomId == null || chatRoomId.isEmpty
              ? null
              : AppRoutes.groupChat,
          arguments: chatRoomId == null || chatRoomId.isEmpty
              ? null
              : {'id': chatRoomId, 'name': activity.title, 'isGroup': true},
        );
      case DashboardActivityType.timetable:
        return const ResolvedActivityPresentation(
          icon: Icons.calendar_today,
          color: AppColors.schedule,
        );
    }
  }
}
