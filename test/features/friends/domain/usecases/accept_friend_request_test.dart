import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/friends/domain/repositories/friend_repository.dart';
import 'package:pulse/features/friends/domain/usecases/accept_friend_request.dart';

class MockFriendRepository extends Mock implements FriendRepository {}

void main() {
  late AcceptFriendRequest usecase;
  late MockFriendRepository mockFriendRepository;

  setUp(() {
    mockFriendRepository = MockFriendRepository();
    usecase = AcceptFriendRequest(mockFriendRepository);
  });

  const tFriendshipId = 'friendship-123';

  test('should return void when acceptFriendRequest is successful', () async {
    // arrange
    when(() => mockFriendRepository.acceptFriendRequest(tFriendshipId))
        .thenAnswer((_) async => const Right(null));

    // act
    final result = await usecase(tFriendshipId);

    // assert
    expect(result, const Right(null));
    verify(() => mockFriendRepository.acceptFriendRequest(tFriendshipId)).called(1);
    verifyNoMoreInteractions(mockFriendRepository);
  });

  test('should return ServerFailure when acceptFriendRequest fails', () async {
    // arrange
    when(() => mockFriendRepository.acceptFriendRequest(tFriendshipId))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to accept request')));

    // act
    final result = await usecase(tFriendshipId);

    // assert
    expect(result, const Left(ServerFailure(message: 'Failed to accept request')));
    verify(() => mockFriendRepository.acceptFriendRequest(tFriendshipId)).called(1);
    verifyNoMoreInteractions(mockFriendRepository);
  });

  test('should return ServerFailure when friendship not found', () async {
    // arrange
    when(() => mockFriendRepository.acceptFriendRequest(tFriendshipId))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Friendship not found')));

    // act
    final result = await usecase(tFriendshipId);

    // assert
    expect(result, const Left(ServerFailure(message: 'Friendship not found')));
    verify(() => mockFriendRepository.acceptFriendRequest(tFriendshipId)).called(1);
    verifyNoMoreInteractions(mockFriendRepository);
  });

  test('should return NetworkFailure when there is no internet connection', () async {
    // arrange
    when(() => mockFriendRepository.acceptFriendRequest(tFriendshipId))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(tFriendshipId);

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockFriendRepository.acceptFriendRequest(tFriendshipId)).called(1);
    verifyNoMoreInteractions(mockFriendRepository);
  });
}
