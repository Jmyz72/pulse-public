import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/notification.dart';
import '../../domain/usecases/delete_notification.dart';
import '../../domain/usecases/get_notifications.dart';
import '../../domain/usecases/mark_all_as_read.dart';
import '../../domain/usecases/mark_as_read.dart';

part 'notification_event.dart';
part 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final GetNotifications getNotifications;
  final MarkAsRead markAsRead;
  final MarkAllAsRead markAllAsRead;
  final DeleteNotification deleteNotification;

  NotificationBloc({
    required this.getNotifications,
    required this.markAsRead,
    required this.markAllAsRead,
    required this.deleteNotification,
  }) : super(const NotificationState()) {
    on<NotificationLoadRequested>(_onLoadRequested, transformer: droppable());
    on<NotificationClearRequested>(_onCleared);
    on<NotificationMarkAsReadRequested>(
      _onMarkAsRead,
      transformer: droppable(),
    );
    on<NotificationMarkAllAsReadRequested>(
      _onMarkAllAsRead,
      transformer: droppable(),
    );
    on<NotificationDeleteRequested>(_onDeleted, transformer: droppable());
  }

  Future<void> _onLoadRequested(
    NotificationLoadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(status: NotificationStatus.loading));

    final result = await getNotifications(const NoParams());

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: NotificationStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (notifications) => emit(
        state.copyWith(
          status: NotificationStatus.loaded,
          notifications: notifications,
        ),
      ),
    );
  }

  void _onCleared(
    NotificationClearRequested event,
    Emitter<NotificationState> emit,
  ) {
    emit(const NotificationState());
  }

  Future<void> _onMarkAsRead(
    NotificationMarkAsReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    // Optimistic update
    final previousNotifications = state.notifications;
    final updated = state.notifications.map((n) {
      if (n.id == event.id) return n.copyWith(isRead: true);
      return n;
    }).toList();
    emit(state.copyWith(notifications: updated));

    final result = await markAsRead(MarkAsReadParams(id: event.id));

    result.fold((failure) {
      // Rollback on failure
      emit(
        state.copyWith(
          status: NotificationStatus.loaded, // Return to loaded even on fail
          notifications: previousNotifications,
          errorMessage: failure.message,
        ),
      );
    }, (_) {});
  }

  Future<void> _onMarkAllAsRead(
    NotificationMarkAllAsReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    // Optimistic update
    final previousNotifications = state.notifications;
    final updated = state.notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    emit(state.copyWith(notifications: updated));

    final result = await markAllAsRead(const NoParams());

    result.fold((failure) {
      // Rollback on failure
      emit(
        state.copyWith(
          status: NotificationStatus.loaded,
          notifications: previousNotifications,
          errorMessage: failure.message,
        ),
      );
    }, (_) {});
  }

  Future<void> _onDeleted(
    NotificationDeleteRequested event,
    Emitter<NotificationState> emit,
  ) async {
    // Optimistic update
    final previousNotifications = state.notifications;
    final updated = state.notifications.where((n) => n.id != event.id).toList();
    emit(state.copyWith(notifications: updated));

    final result = await deleteNotification(
      DeleteNotificationParams(id: event.id),
    );

    result.fold((failure) {
      // Rollback on failure
      emit(
        state.copyWith(
          status: NotificationStatus.loaded,
          notifications: previousNotifications,
          errorMessage: failure.message,
        ),
      );
    }, (_) {});
  }
}
