import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/core/usecases/usecase.dart';
import 'package:pulse/features/notifications/domain/repositories/notification_repository.dart';
import 'package:pulse/features/notifications/domain/usecases/mark_all_as_read.dart';

class MockNotificationRepository extends Mock implements NotificationRepository {}

void main() {
  late MarkAllAsRead usecase;
  late MockNotificationRepository mockRepository;

  setUp(() {
    mockRepository = MockNotificationRepository();
    usecase = MarkAllAsRead(mockRepository);
  });

  test('should mark all notifications as read when successful', () async {
    // arrange
    when(() => mockRepository.markAllAsRead())
        .thenAnswer((_) async => const Right(null));

    // act
    final result = await usecase(const NoParams());

    // assert
    expect(result.isRight(), true);
    verify(() => mockRepository.markAllAsRead()).called(1);
  });

  test('should return ServerFailure when repository fails', () async {
    // arrange
    when(() => mockRepository.markAllAsRead())
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to mark all as read')));

    // act
    final result = await usecase(const NoParams());

    // assert
    expect(result, const Left(ServerFailure(message: 'Failed to mark all as read')));
    verify(() => mockRepository.markAllAsRead()).called(1);
  });

  test('should return NetworkFailure when there is no internet', () async {
    // arrange
    when(() => mockRepository.markAllAsRead())
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(const NoParams());

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockRepository.markAllAsRead()).called(1);
  });
}
