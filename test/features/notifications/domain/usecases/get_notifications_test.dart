import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/core/usecases/usecase.dart';
import 'package:pulse/features/notifications/domain/entities/notification.dart';
import 'package:pulse/features/notifications/domain/repositories/notification_repository.dart';
import 'package:pulse/features/notifications/domain/usecases/get_notifications.dart';

class MockNotificationRepository extends Mock implements NotificationRepository {}

void main() {
  late GetNotifications usecase;
  late MockNotificationRepository mockRepository;

  setUp(() {
    mockRepository = MockNotificationRepository();
    usecase = GetNotifications(mockRepository);
  });

  final tNotification1 = AppNotification(
    id: 'notif-1',
    userId: 'user-1',
    title: 'Test Notification',
    body: 'This is a test notification',
    type: NotificationType.task,
    relatedId: 'task-1',
    timestamp: DateTime(2024, 1, 1, 10, 0),
    isRead: false,
    actionUrl: '/tasks/task-1',
    data: {'taskId': 'task-1'},
  );

  final tNotification2 = AppNotification(
    id: 'notif-2',
    userId: 'user-1',
    title: 'Event Reminder',
    body: 'Your event is starting soon',
    type: NotificationType.event,
    relatedId: 'event-1',
    timestamp: DateTime(2024, 1, 1, 11, 0),
    isRead: true,
  );

  final tNotifications = [tNotification1, tNotification2];

  test('should return list of notifications when successful', () async {
    // arrange
    when(() => mockRepository.getNotifications())
        .thenAnswer((_) async => Right(tNotifications));

    // act
    final result = await usecase(const NoParams());

    // assert
    expect(result.isRight(), true);
    result.fold(
      (l) => fail('Should be Right'),
      (r) {
        expect(r.length, 2);
        expect(r[0].id, 'notif-1');
        expect(r[0].title, 'Test Notification');
        expect(r[0].type, NotificationType.task);
        expect(r[0].isRead, false);
        expect(r[1].id, 'notif-2');
        expect(r[1].isRead, true);
      },
    );
    verify(() => mockRepository.getNotifications()).called(1);
  });

  test('should return empty list when there are no notifications', () async {
    // arrange
    when(() => mockRepository.getNotifications())
        .thenAnswer((_) async => const Right([]));

    // act
    final result = await usecase(const NoParams());

    // assert
    expect(result.isRight(), true);
    result.fold(
      (l) => fail('Should be Right'),
      (r) => expect(r, isEmpty),
    );
    verify(() => mockRepository.getNotifications()).called(1);
  });

  test('should return ServerFailure when repository fails', () async {
    // arrange
    when(() => mockRepository.getNotifications())
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to fetch notifications')));

    // act
    final result = await usecase(const NoParams());

    // assert
    expect(result, const Left(ServerFailure(message: 'Failed to fetch notifications')));
    verify(() => mockRepository.getNotifications()).called(1);
  });

  test('should return NetworkFailure when there is no internet', () async {
    // arrange
    when(() => mockRepository.getNotifications())
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(const NoParams());

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockRepository.getNotifications()).called(1);
  });
}
