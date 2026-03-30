import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/notifications/domain/repositories/notification_repository.dart';
import 'package:pulse/features/notifications/domain/usecases/mark_as_read.dart';

class MockNotificationRepository extends Mock implements NotificationRepository {}

void main() {
  late MarkAsRead usecase;
  late MockNotificationRepository mockRepository;

  setUp(() {
    mockRepository = MockNotificationRepository();
    usecase = MarkAsRead(mockRepository);
  });

  const tNotificationId = 'notif-1';

  test('should mark notification as read when successful', () async {
    // arrange
    when(() => mockRepository.markAsRead(tNotificationId))
        .thenAnswer((_) async => const Right(null));

    // act
    final result = await usecase(const MarkAsReadParams(id: tNotificationId));

    // assert
    expect(result.isRight(), true);
    verify(() => mockRepository.markAsRead(tNotificationId)).called(1);
  });

  test('should return ServerFailure when repository fails', () async {
    // arrange
    when(() => mockRepository.markAsRead(tNotificationId))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to mark as read')));

    // act
    final result = await usecase(const MarkAsReadParams(id: tNotificationId));

    // assert
    expect(result, const Left(ServerFailure(message: 'Failed to mark as read')));
    verify(() => mockRepository.markAsRead(tNotificationId)).called(1);
  });

  test('should return NetworkFailure when there is no internet', () async {
    // arrange
    when(() => mockRepository.markAsRead(tNotificationId))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(const MarkAsReadParams(id: tNotificationId));

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockRepository.markAsRead(tNotificationId)).called(1);
  });

  test('MarkAsReadParams should have correct props for equality', () {
    // arrange
    const tParams1 = MarkAsReadParams(id: 'notif-1');
    const tParams2 = MarkAsReadParams(id: 'notif-1');
    const tParams3 = MarkAsReadParams(id: 'notif-2');

    // assert
    expect(tParams1, equals(tParams2));
    expect(tParams1, isNot(equals(tParams3)));
    expect(tParams1.props, ['notif-1']);
  });
}
