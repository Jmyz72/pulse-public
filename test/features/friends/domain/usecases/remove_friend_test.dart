import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/friends/domain/repositories/friend_repository.dart';
import 'package:pulse/features/friends/domain/usecases/remove_friend.dart';

class MockFriendRepository extends Mock implements FriendRepository {}

void main() {
  late RemoveFriend usecase;
  late MockFriendRepository mockFriendRepository;

  setUp(() {
    mockFriendRepository = MockFriendRepository();
    usecase = RemoveFriend(mockFriendRepository);
  });

  const tFriendshipId = 'friendship-123';

  test('should return void when removeFriend is successful', () async {
    // arrange
    when(() => mockFriendRepository.removeFriend(tFriendshipId))
        .thenAnswer((_) async => const Right(null));

    // act
    final result = await usecase(tFriendshipId);

    // assert
    expect(result, const Right(null));
    verify(() => mockFriendRepository.removeFriend(tFriendshipId)).called(1);
    verifyNoMoreInteractions(mockFriendRepository);
  });

  test('should return ServerFailure when removeFriend fails', () async {
    // arrange
    when(() => mockFriendRepository.removeFriend(tFriendshipId))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to remove friend')));

    // act
    final result = await usecase(tFriendshipId);

    // assert
    expect(result, const Left(ServerFailure(message: 'Failed to remove friend')));
    verify(() => mockFriendRepository.removeFriend(tFriendshipId)).called(1);
    verifyNoMoreInteractions(mockFriendRepository);
  });

  test('should return ServerFailure when friendship not found', () async {
    // arrange
    when(() => mockFriendRepository.removeFriend(tFriendshipId))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Friendship not found')));

    // act
    final result = await usecase(tFriendshipId);

    // assert
    expect(result, const Left(ServerFailure(message: 'Friendship not found')));
    verify(() => mockFriendRepository.removeFriend(tFriendshipId)).called(1);
    verifyNoMoreInteractions(mockFriendRepository);
  });

  test('should return NetworkFailure when there is no internet connection', () async {
    // arrange
    when(() => mockFriendRepository.removeFriend(tFriendshipId))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(tFriendshipId);

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockFriendRepository.removeFriend(tFriendshipId)).called(1);
    verifyNoMoreInteractions(mockFriendRepository);
  });
}
