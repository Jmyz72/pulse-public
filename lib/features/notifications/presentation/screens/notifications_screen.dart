import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../shared/widgets/pulse_lottie.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../domain/entities/notification.dart';
import '../bloc/notification_bloc.dart';

/// Notifications & Alerts Screen
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Completer<void>? _refreshCompleter;

  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(const NotificationLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<NotificationBloc, NotificationState>(
      listener: (context, state) {
        if (_refreshCompleter != null &&
            state.status != NotificationStatus.loading) {
          _refreshCompleter?.complete();
          _refreshCompleter = null;
        }
        if (state.status == NotificationStatus.error &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Notifications${state.unreadCount > 0 ? " (${state.unreadCount})" : ""}',
            ),
            actions: [
              if (state.unreadCount > 0)
                TextButton(
                  onPressed: () {
                    context.read<NotificationBloc>().add(
                      const NotificationMarkAllAsReadRequested(),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All notifications marked as read'),
                      ),
                    );
                  },
                  child: const Text('Mark all read'),
                ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'refresh', child: Text('Refresh')),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Text('Notification settings'),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'refresh') {
                    context.read<NotificationBloc>().add(
                      const NotificationLoadRequested(),
                    );
                  }
                },
              ),
            ],
          ),
          body: _buildContent(theme, state),
        );
      },
    );
  }

  Widget _buildContent(ThemeData theme, NotificationState state) {
    if (state.status == NotificationStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == NotificationStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            const Text('Failed to load notifications'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                context.read<NotificationBloc>().add(
                  const NotificationLoadRequested(),
                );
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.notifications.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.spacingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PulseLottie(
                key: ValueKey('notifications-empty-lottie'),
                assetPath: 'assets/animations/notifications_empty.json',
                width: 180,
                height: 180,
                semanticLabel: 'No notifications animation',
              ),
              SizedBox(height: AppDimensions.spacingMd),
              Text(
                'No notifications',
                style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
              ),
              SizedBox(height: AppDimensions.spacingSm),
              Text(
                'You are all caught up for now.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () {
        _refreshCompleter = Completer<void>();
        context.read<NotificationBloc>().add(const NotificationLoadRequested());
        return _refreshCompleter!.future;
      },
      child: ListView.builder(
        itemCount: state.notifications.length,
        itemBuilder: (context, index) {
          final notif = state.notifications[index];
          return _buildNotificationCard(theme, notif);
        },
      ),
    );
  }

  Widget _buildNotificationCard(ThemeData theme, AppNotification notif) {
    final isRead = notif.isRead;

    return Dismissible(
      key: Key(notif.id),
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: AppColors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        context.read<NotificationBloc>().add(
          NotificationDeleteRequested(id: notif.id),
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Notification deleted')));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isRead
              ? theme.colorScheme.surface
              : theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead
                ? AppColors.grey400.withValues(alpha: 0.2)
                : theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getNotificationColor(notif.type).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getNotificationIcon(notif.type),
              color: _getNotificationColor(notif.type),
            ),
          ),
          title: Text(
            notif.title,
            style: TextStyle(
              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(notif.body),
              const SizedBox(height: 4),
              Text(
                _formatTime(notif.timestamp),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          trailing: !isRead
              ? Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
          onTap: () {
            if (!isRead && notif.id.isNotEmpty) {
              context.read<NotificationBloc>().add(
                NotificationMarkAsReadRequested(id: notif.id),
              );
            }
            _handleNotificationTap(notif);
          },
        ),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.task:
        return Icons.task_alt;
      case NotificationType.event:
        return Icons.event;
      case NotificationType.expense:
        return Icons.attach_money;
      case NotificationType.chat:
        return Icons.message;
      case NotificationType.location:
        return Icons.location_on;
      case NotificationType.system:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.task:
        return AppColors.task;
      case NotificationType.event:
        return AppColors.event;
      case NotificationType.expense:
        return AppColors.expense;
      case NotificationType.chat:
        return AppColors.neonYellow;
      case NotificationType.location:
        return AppColors.location;
      case NotificationType.system:
        return AppColors.grey500;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${time.day}/${time.month}/${time.year}';
  }

  void _handleNotificationTap(AppNotification notif) {
    // Navigate based on notification type
    switch (notif.type) {
      case NotificationType.task:
        Navigator.pushNamed(context, AppRoutes.tasks);
        break;
      case NotificationType.event:
        // No events route yet
        break;
      case NotificationType.expense:
        Navigator.pushNamed(context, AppRoutes.expense);
        break;
      case NotificationType.chat:
        final chatRoomId = notif.data?['chatRoomId'];
        if (chatRoomId != null) {
          Navigator.pushNamed(
            context,
            AppRoutes.groupChat,
            arguments: {
              'id': chatRoomId,
              'name': notif.data?['roomName'] ?? 'Chat',
              'isGroup': notif.data?['isGroup'] == 'true',
            },
          );
        } else {
          // Navigate to home screen's chat tab (index 1)
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
            (route) => false,
          );
          context.read<HomeBloc>().add(
            const HomeTabChangeRequested(tabIndex: 1),
          );
        }
        break;
      case NotificationType.location:
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => false,
        );
        context.read<HomeBloc>().add(const HomeTabChangeRequested(tabIndex: 0));
        break;
      case NotificationType.system:
        // Do nothing for system notifications
        break;
    }
  }
}
