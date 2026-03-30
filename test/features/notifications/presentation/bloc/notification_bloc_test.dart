import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/core/usecases/usecase.dart';
import 'package:pulse/features/notifications/domain/entities/notification.dart';
import 'package:pulse/features/notifications/domain/usecases/delete_notification.dart';
import 'package:pulse/features/notifications/domain/usecases/get_notifications.dart';
import 'package:pulse/features/notifications/domain/usecases/mark_all_as_read.dart';
import 'package:pulse/features/notifications/domain/usecases/mark_as_read.dart';
import 'package:pulse/features/notifications/presentation/bloc/notification_bloc.dart';

class MockGetNotifications extends Mock implements GetNotifications {}
class MockMarkAsRead extends Mock implements MarkAsRead {}
class MockMarkAllAsRead extends Mock implements MarkAllAsRead {}
class MockDeleteNotification extends Mock implements DeleteNotification {}

void main() {
  late NotificationBloc bloc;
  late MockGetNotifications mockGetNotifications;
  late MockMarkAsRead mockMarkAsRead;
  late MockMarkAllAsRead mockMarkAllAsRead;
  late MockDeleteNotification mockDeleteNotification;

  setUp(() {
    mockGetNotifications = MockGetNotifications();
    mockMarkAsRead = MockMarkAsRead();
    mockMarkAllAsRead = MockMarkAllAsRead();
    mockDeleteNotification = MockDeleteNotification();

    bloc = NotificationBloc(
      getNotifications: mockGetNotifications,
      markAsRead: mockMarkAsRead,
      markAllAsRead: mockMarkAllAsRead,
      deleteNotification: mockDeleteNotification,
    );
  });

  tearDown(() {
    bloc.close();
  });

  final tNotification1 = AppNotification(
    id: 'notif-1',
    userId: 'user-1',
    title: 'Task Assigned',
    body: 'You have been assigned a new task',
    type: NotificationType.task,
    relatedId: 'task-1',
    timestamp: DateTime(2024, 1, 1, 10, 0),
    isRead: false,
    actionUrl: '/tasks/task-1',
    data: const {'taskId': 'task-1'},
  );

  final tNotification2 = AppNotification(
    id: 'notif-2',
    userId: 'user-1',
    title: 'Event Reminder',
    body: 'Your event is starting soon',
    type: NotificationType.event,
    relatedId: 'event-1',
    timestamp: DateTime(2024, 1, 1, 11, 0),
    isRead: false,
  );

  final tNotification3 = AppNotification(
    id: 'notif-3',
    userId: 'user-1',
    title: 'Expense Added',
    body: 'A new expense was added to your group',
    type: NotificationType.expense,
    relatedId: 'expense-1',
    timestamp: DateTime(2024, 1, 1, 12, 0),
    isRead: true,
  );

  final tNotifications = [tNotification1, tNotification2, tNotification3];

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const MarkAsReadParams(id: 'notif-1'));
    registerFallbackValue(const DeleteNotificationParams(id: 'notif-1'));
  });

  group('NotificationLoadRequested', () {
    blocTest<NotificationBloc, NotificationState>(
      'emits [loading, loaded] when GetNotifications returns successfully',
      build: () {
        when(() => mockGetNotifications(any()))
            .thenAnswer((_) async => Right(tNotifications));
        return bloc;
      },
      act: (bloc) => bloc.add(const NotificationLoadRequested()),
      expect: () => [
        const NotificationState(status: NotificationStatus.loading),
        NotificationState(
          status: NotificationStatus.loaded,
          notifications: tNotifications,
        ),
      ],
      verify: (_) {
        verify(() => mockGetNotifications(any())).called(1);
      },
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits [loading, loaded] with empty list when no notifications exist',
      build: () {
        when(() => mockGetNotifications(any()))
            .thenAnswer((_) async => const Right([]));
        return bloc;
      },
      act: (bloc) => bloc.add(const NotificationLoadRequested()),
      expect: () => [
        const NotificationState(status: NotificationStatus.loading),
        const NotificationState(
          status: NotificationStatus.loaded,
          notifications: [],
        ),
      ],
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits [loading, error] when GetNotifications fails with ServerFailure',
      build: () {
        when(() => mockGetNotifications(any()))
            .thenAnswer((_) async => const Left(ServerFailure(message: 'Server error')));
        return bloc;
      },
      act: (bloc) => bloc.add(const NotificationLoadRequested()),
      expect: () => [
        const NotificationState(status: NotificationStatus.loading),
        const NotificationState(
          status: NotificationStatus.error,
          errorMessage: 'Server error',
        ),
      ],
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits [loading, error] when GetNotifications fails with NetworkFailure',
      build: () {
        when(() => mockGetNotifications(any()))
            .thenAnswer((_) async => const Left(NetworkFailure()));
        return bloc;
      },
      act: (bloc) => bloc.add(const NotificationLoadRequested()),
      expect: () => [
        const NotificationState(status: NotificationStatus.loading),
        const NotificationState(
          status: NotificationStatus.error,
          errorMessage: 'No internet connection',
        ),
      ],
    );
  });

  group('NotificationMarkAsReadRequested', () {
    final tNotification1AsRead = tNotification1.copyWith(isRead: true);

    blocTest<NotificationBloc, NotificationState>(
      'emits optimistic update with notification marked as read when MarkAsRead succeeds',
      build: () {
        when(() => mockMarkAsRead(any()))
            .thenAnswer((_) async => const Right(null));
        return bloc;
      },
      seed: () => NotificationState(
        status: NotificationStatus.loaded,
        notifications: tNotifications,
      ),
      act: (bloc) => bloc.add(const NotificationMarkAsReadRequested(id: 'notif-1')),
      expect: () => [
        NotificationState(
          status: NotificationStatus.loaded,
          notifications: [tNotification1AsRead, tNotification2, tNotification3],
        ),
      ],
      verify: (_) {
        verify(() => mockMarkAsRead(any())).called(1);
      },
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits optimistic update then rolls back on MarkAsRead failure',
      build: () {
        when(() => mockMarkAsRead(any()))
            .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to mark as read')));
        return bloc;
      },
      seed: () => NotificationState(
        status: NotificationStatus.loaded,
        notifications: tNotifications,
      ),
      act: (bloc) => bloc.add(const NotificationMarkAsReadRequested(id: 'notif-1')),
      expect: () => [
        // Optimistic update
        NotificationState(
          status: NotificationStatus.loaded,
          notifications: [tNotification1AsRead, tNotification2, tNotification3],
        ),
        // Rollback
        NotificationState(
          status: NotificationStatus.error,
          notifications: tNotifications,
          errorMessage: 'Failed to mark as read',
        ),
      ],
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits optimistic update then rolls back on MarkAsRead NetworkFailure',
      build: () {
        when(() => mockMarkAsRead(any()))
            .thenAnswer((_) async => const Left(NetworkFailure()));
        return bloc;
      },
      seed: () => NotificationState(
        status: NotificationStatus.loaded,
        notifications: tNotifications,
      ),
      act: (bloc) => bloc.add(const NotificationMarkAsReadRequested(id: 'notif-1')),
      expect: () => [
        // Optimistic update
        NotificationState(
          status: NotificationStatus.loaded,
          notifications: [tNotification1AsRead, tNotification2, tNotification3],
        ),
        // Rollback
        NotificationState(
          status: NotificationStatus.error,
          notifications: tNotifications,
          errorMessage: 'No internet connection',
        ),
      ],
    );
  });

  group('NotificationMarkAllAsReadRequested', () {
    final tAllReadNotifications = [
      tNotification1.copyWith(isRead: true),
      tNotification2.copyWith(isRead: true),
      tNotification3.copyWith(isRead: true),
    ];

    blocTest<NotificationBloc, NotificationState>(
      'emits optimistic update with all notifications marked as read when MarkAllAsRead succeeds',
      build: () {
        when(() => mockMarkAllAsRead(any()))
            .thenAnswer((_) async => const Right(null));
        return bloc;
      },
      seed: () => NotificationState(
        status: NotificationStatus.loaded,
        notifications: tNotifications,
      ),
      act: (bloc) => bloc.add(const NotificationMarkAllAsReadRequested()),
      expect: () => [
        NotificationState(
          status: NotificationStatus.loaded,
          notifications: tAllReadNotifications,
        ),
      ],
      verify: (_) {
        verify(() => mockMarkAllAsRead(any())).called(1);
      },
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits optimistic update then rolls back on MarkAllAsRead failure',
      build: () {
        when(() => mockMarkAllAsRead(any()))
            .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to mark all as read')));
        return bloc;
      },
      seed: () => NotificationState(
        status: NotificationStatus.loaded,
        notifications: tNotifications,
      ),
      act: (bloc) => bloc.add(const NotificationMarkAllAsReadRequested()),
      expect: () => [
        // Optimistic update
        NotificationState(
          status: NotificationStatus.loaded,
          notifications: tAllReadNotifications,
        ),
        // Rollback
        NotificationState(
          status: NotificationStatus.error,
          notifications: tNotifications,
          errorMessage: 'Failed to mark all as read',
        ),
      ],
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits optimistic update then rolls back on MarkAllAsRead NetworkFailure',
      build: () {
        when(() => mockMarkAllAsRead(any()))
            .thenAnswer((_) async => const Left(NetworkFailure()));
        return bloc;
      },
      seed: () => NotificationState(
        status: NotificationStatus.loaded,
        notifications: tNotifications,
      ),
      act: (bloc) => bloc.add(const NotificationMarkAllAsReadRequested()),
      expect: () => [
        // Optimistic update
        NotificationState(
          status: NotificationStatus.loaded,
          notifications: tAllReadNotifications,
        ),
        // Rollback
        NotificationState(
          status: NotificationStatus.error,
          notifications: tNotifications,
          errorMessage: 'No internet connection',
        ),
      ],
    );
  });

  group('NotificationDeleteRequested', () {
    blocTest<NotificationBloc, NotificationState>(
      'emits optimistic update without deleted notification when DeleteNotification succeeds',
      build: () {
        when(() => mockDeleteNotification(any()))
            .thenAnswer((_) async => const Right(null));
        return bloc;
      },
      seed: () => NotificationState(
        status: NotificationStatus.loaded,
        notifications: tNotifications,
      ),
      act: (bloc) => bloc.add(const NotificationDeleteRequested(id: 'notif-1')),
      expect: () => [
        NotificationState(
          status: NotificationStatus.loaded,
          notifications: [tNotification2, tNotification3],
        ),
      ],
      verify: (_) {
        verify(() => mockDeleteNotification(any())).called(1);
      },
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits empty list when last notification is deleted',
      build: () {
        when(() => mockDeleteNotification(any()))
            .thenAnswer((_) async => const Right(null));
        return bloc;
      },
      seed: () => NotificationState(
        status: NotificationStatus.loaded,
        notifications: [tNotification1],
      ),
      act: (bloc) => bloc.add(const NotificationDeleteRequested(id: 'notif-1')),
      expect: () => [
        const NotificationState(
          status: NotificationStatus.loaded,
          notifications: [],
        ),
      ],
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits optimistic update then rolls back on DeleteNotification failure',
      build: () {
        when(() => mockDeleteNotification(any()))
            .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to delete')));
        return bloc;
      },
      seed: () => NotificationState(
        status: NotificationStatus.loaded,
        notifications: tNotifications,
      ),
      act: (bloc) => bloc.add(const NotificationDeleteRequested(id: 'notif-1')),
      expect: () => [
        // Optimistic update
        NotificationState(
          status: NotificationStatus.loaded,
          notifications: [tNotification2, tNotification3],
        ),
        // Rollback
        NotificationState(
          status: NotificationStatus.error,
          notifications: tNotifications,
          errorMessage: 'Failed to delete',
        ),
      ],
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits optimistic update then rolls back on DeleteNotification NetworkFailure',
      build: () {
        when(() => mockDeleteNotification(any()))
            .thenAnswer((_) async => const Left(NetworkFailure()));
        return bloc;
      },
      seed: () => NotificationState(
        status: NotificationStatus.loaded,
        notifications: tNotifications,
      ),
      act: (bloc) => bloc.add(const NotificationDeleteRequested(id: 'notif-1')),
      expect: () => [
        // Optimistic update
        NotificationState(
          status: NotificationStatus.loaded,
          notifications: [tNotification2, tNotification3],
        ),
        // Rollback
        NotificationState(
          status: NotificationStatus.error,
          notifications: tNotifications,
          errorMessage: 'No internet connection',
        ),
      ],
    );
  });

  group('NotificationState', () {
    test('unreadCount returns correct count of unread notifications', () {
      // arrange
      final state = NotificationState(
        status: NotificationStatus.loaded,
        notifications: tNotifications,
      );

      // assert
      expect(state.unreadCount, 2);
    });

    test('unreadNotifications returns only unread notifications', () {
      // arrange
      final state = NotificationState(
        status: NotificationStatus.loaded,
        notifications: tNotifications,
      );

      // assert
      expect(state.unreadNotifications.length, 2);
      expect(state.unreadNotifications.every((n) => !n.isRead), true);
    });

    test('initial state has correct default values', () {
      // assert
      expect(bloc.state.status, NotificationStatus.initial);
      expect(bloc.state.notifications, isEmpty);
      expect(bloc.state.errorMessage, isNull);
    });

    test('copyWith preserves unchanged values', () {
      // arrange
      final state = NotificationState(
        status: NotificationStatus.loaded,
        notifications: tNotifications,
        errorMessage: 'test error',
      );

      // act
      final newState = state.copyWith(status: NotificationStatus.error);

      // assert
      expect(newState.status, NotificationStatus.error);
      expect(newState.notifications, tNotifications);
      expect(newState.errorMessage, isNull); // errorMessage is cleared when not provided
    });
  });

  group('AppNotification copyWith', () {
    test('copyWith returns new instance with updated fields', () {
      final updated = tNotification1.copyWith(isRead: true);
      expect(updated.isRead, true);
      expect(updated.id, tNotification1.id);
      expect(updated.title, tNotification1.title);
      expect(updated.body, tNotification1.body);
    });

    test('copyWith preserves all fields when no changes', () {
      final copy = tNotification1.copyWith();
      expect(copy, equals(tNotification1));
    });
  });

  group('NotificationEvent equality', () {
    test('NotificationLoadRequested instances are equal', () {
      expect(const NotificationLoadRequested(), equals(const NotificationLoadRequested()));
    });

    test('NotificationMarkAsReadRequested instances with same id are equal', () {
      expect(
        const NotificationMarkAsReadRequested(id: 'notif-1'),
        equals(const NotificationMarkAsReadRequested(id: 'notif-1')),
      );
    });

    test('NotificationMarkAsReadRequested instances with different ids are not equal', () {
      expect(
        const NotificationMarkAsReadRequested(id: 'notif-1'),
        isNot(equals(const NotificationMarkAsReadRequested(id: 'notif-2'))),
      );
    });

    test('NotificationMarkAllAsReadRequested instances are equal', () {
      expect(const NotificationMarkAllAsReadRequested(), equals(const NotificationMarkAllAsReadRequested()));
    });

    test('NotificationDeleteRequested instances with same id are equal', () {
      expect(
        const NotificationDeleteRequested(id: 'notif-1'),
        equals(const NotificationDeleteRequested(id: 'notif-1')),
      );
    });

    test('NotificationDeleteRequested instances with different ids are not equal', () {
      expect(
        const NotificationDeleteRequested(id: 'notif-1'),
        isNot(equals(const NotificationDeleteRequested(id: 'notif-2'))),
      );
    });
  });
}
