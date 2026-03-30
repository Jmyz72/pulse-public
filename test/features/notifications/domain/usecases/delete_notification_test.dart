import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/notifications/domain/repositories/notification_repository.dart';
import 'package:pulse/features/notifications/domain/usecases/delete_notification.dart';

class MockNotificationRepository extends Mock implements NotificationRepository {}

void main() {
  late DeleteNotification usecase;
  late MockNotificationRepository mockRepository;

  setUp(() {
    mockRepository = MockNotificationRepository();
    usecase = DeleteNotification(mockRepository);
  });

  const tNotificationId = 'notif-1';

  test('should delete notification when successful', () async {
    // arrange
    when(() => mockRepository.deleteNotification(tNotificationId))
        .thenAnswer((_) async => const Right(null));

    // act
    final result = await usecase(const DeleteNotificationParams(id: tNotificationId));

    // assert
    expect(result.isRight(), true);
    verify(() => mockRepository.deleteNotification(tNotificationId)).called(1);
  });

  test('should return ServerFailure when repository fails', () async {
    // arrange
    when(() => mockRepository.deleteNotification(tNotificationId))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to delete notification')));

    // act
    final result = await usecase(const DeleteNotificationParams(id: tNotificationId));

    // assert
    expect(result, const Left(ServerFailure(message: 'Failed to delete notification')));
    verify(() => mockRepository.deleteNotification(tNotificationId)).called(1);
  });

  test('should return NetworkFailure when there is no internet', () async {
    // arrange
    when(() => mockRepository.deleteNotification(tNotificationId))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(const DeleteNotificationParams(id: tNotificationId));

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockRepository.deleteNotification(tNotificationId)).called(1);
  });

  test('DeleteNotificationParams should have correct props for equality', () {
    // arrange
    const tParams1 = DeleteNotificationParams(id: 'notif-1');
    const tParams2 = DeleteNotificationParams(id: 'notif-1');
    const tParams3 = DeleteNotificationParams(id: 'notif-2');

    // assert
    expect(tParams1, equals(tParams2));
    expect(tParams1, isNot(equals(tParams3)));
    expect(tParams1.props, ['notif-1']);
  });
}
