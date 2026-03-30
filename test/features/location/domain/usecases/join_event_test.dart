import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/location/domain/repositories/event_repository.dart';
import 'package:pulse/features/location/domain/usecases/join_event.dart';

class MockEventRepository extends Mock implements EventRepository {}

void main() {
  late JoinEvent usecase;
  late MockEventRepository mockRepository;

  setUp(() {
    mockRepository = MockEventRepository();
    usecase = JoinEvent(mockRepository);
  });

  const tEventId = 'event-123';
  const tUserId = 'user-1';
  const tUserName = 'Test User';

  test('should return void when joining event is successful', () async {
    // arrange
    when(() => mockRepository.joinEvent(tEventId, tUserId, tUserName))
        .thenAnswer((_) async => const Right(null));

    // act
    final result = await usecase(const JoinEventParams(
      eventId: tEventId,
      userId: tUserId,
      userName: tUserName,
    ));

    // assert
    expect(result, const Right(null));
    verify(() => mockRepository.joinEvent(tEventId, tUserId, tUserName)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return ServerFailure when joining event fails', () async {
    // arrange
    when(() => mockRepository.joinEvent(tEventId, tUserId, tUserName))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to join event')));

    // act
    final result = await usecase(const JoinEventParams(
      eventId: tEventId,
      userId: tUserId,
      userName: tUserName,
    ));

    // assert
    expect(result, const Left(ServerFailure(message: 'Failed to join event')));
    verify(() => mockRepository.joinEvent(tEventId, tUserId, tUserName)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return NetworkFailure when there is no internet connection', () async {
    // arrange
    when(() => mockRepository.joinEvent(tEventId, tUserId, tUserName))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(const JoinEventParams(
      eventId: tEventId,
      userId: tUserId,
      userName: tUserName,
    ));

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockRepository.joinEvent(tEventId, tUserId, tUserName)).called(1);
  });

  test('JoinEventParams should have correct props', () {
    const params = JoinEventParams(
      eventId: tEventId,
      userId: tUserId,
      userName: tUserName,
    );
    expect(params.props, [tEventId, tUserId, tUserName]);
  });
}
