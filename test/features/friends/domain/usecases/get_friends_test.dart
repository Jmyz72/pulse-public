import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/friends/domain/entities/friendship.dart';
import 'package:pulse/features/friends/domain/repositories/friend_repository.dart';
import 'package:pulse/features/friends/domain/usecases/get_friends.dart';

class MockFriendRepository extends Mock implements FriendRepository {}

void main() {
  late GetFriends usecase;
  late MockFriendRepository mockFriendRepository;

  setUp(() {
    mockFriendRepository = MockFriendRepository();
    usecase = GetFriends(mockFriendRepository);
  });

  const tUserId = 'user-123';
  final tFriendships = [
    Friendship(
      id: 'friendship-1',
      userId: tUserId,
      friendId: 'friend-1',
      friendUsername: 'friend1',
      friendDisplayName: 'Friend One',
      friendEmail: 'friend1@test.com',
      friendPhone: '+1234567890',
      requesterUsername: 'user',
      requesterDisplayName: 'User',
      requesterEmail: 'user@test.com',
      requesterPhone: '+0987654321',
      status: FriendshipStatus.accepted,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 2),
    ),
    Friendship(
      id: 'friendship-2',
      userId: tUserId,
      friendId: 'friend-2',
      friendUsername: 'friend2',
      friendDisplayName: 'Friend Two',
      friendEmail: 'friend2@test.com',
      friendPhone: '+1234567891',
      requesterUsername: 'user',
      requesterDisplayName: 'User',
      requesterEmail: 'user@test.com',
      requesterPhone: '+0987654321',
      status: FriendshipStatus.accepted,
      createdAt: DateTime(2024, 1, 3),
      updatedAt: DateTime(2024, 1, 4),
    ),
  ];

  test('should return list of friendships when getFriends is successful', () async {
    // arrange
    when(() => mockFriendRepository.getFriends(tUserId))
        .thenAnswer((_) async => Right(tFriendships));

    // act
    final result = await usecase(tUserId);

    // assert
    expect(result, Right(tFriendships));
    verify(() => mockFriendRepository.getFriends(tUserId)).called(1);
    verifyNoMoreInteractions(mockFriendRepository);
  });

  test('should return empty list when user has no friends', () async {
    // arrange
    when(() => mockFriendRepository.getFriends(tUserId))
        .thenAnswer((_) async => const Right([]));

    // act
    final result = await usecase(tUserId);

    // assert
    expect(result, const Right(<Friendship>[]));
    verify(() => mockFriendRepository.getFriends(tUserId)).called(1);
    verifyNoMoreInteractions(mockFriendRepository);
  });

  test('should return ServerFailure when getFriends fails', () async {
    // arrange
    when(() => mockFriendRepository.getFriends(tUserId))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to load friends')));

    // act
    final result = await usecase(tUserId);

    // assert
    expect(result, const Left(ServerFailure(message: 'Failed to load friends')));
    verify(() => mockFriendRepository.getFriends(tUserId)).called(1);
    verifyNoMoreInteractions(mockFriendRepository);
  });

  test('should return NetworkFailure when there is no internet connection', () async {
    // arrange
    when(() => mockFriendRepository.getFriends(tUserId))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(tUserId);

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockFriendRepository.getFriends(tUserId)).called(1);
    verifyNoMoreInteractions(mockFriendRepository);
  });
}
