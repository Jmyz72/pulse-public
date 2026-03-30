import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/friends/domain/entities/friendship.dart';
import 'package:pulse/features/friends/domain/repositories/friend_repository.dart';
import 'package:pulse/features/friends/domain/usecases/get_pending_requests.dart';

class MockFriendRepository extends Mock implements FriendRepository {}

void main() {
  late GetPendingRequests usecase;
  late MockFriendRepository mockFriendRepository;

  setUp(() {
    mockFriendRepository = MockFriendRepository();
    usecase = GetPendingRequests(mockFriendRepository);
  });

  const tUserId = 'user-123';
  final tPendingRequests = [
    Friendship(
      id: 'request-1',
      userId: 'requester-1',
      friendId: tUserId,
      friendUsername: 'user',
      friendDisplayName: 'User',
      friendEmail: 'user@test.com',
      friendPhone: '+0987654321',
      requesterUsername: 'requester1',
      requesterDisplayName: 'Requester One',
      requesterEmail: 'requester1@test.com',
      requesterPhone: '+1234567890',
      status: FriendshipStatus.pending,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    ),
  ];

  test('should return list of pending requests when getPendingRequests is successful', () async {
    // arrange
    when(() => mockFriendRepository.getPendingRequests(tUserId))
        .thenAnswer((_) async => Right(tPendingRequests));

    // act
    final result = await usecase(tUserId);

    // assert
    expect(result, Right(tPendingRequests));
    verify(() => mockFriendRepository.getPendingRequests(tUserId)).called(1);
    verifyNoMoreInteractions(mockFriendRepository);
  });

  test('should return empty list when there are no pending requests', () async {
    // arrange
    when(() => mockFriendRepository.getPendingRequests(tUserId))
        .thenAnswer((_) async => const Right([]));

    // act
    final result = await usecase(tUserId);

    // assert
    expect(result, const Right(<Friendship>[]));
    verify(() => mockFriendRepository.getPendingRequests(tUserId)).called(1);
    verifyNoMoreInteractions(mockFriendRepository);
  });

  test('should return ServerFailure when getPendingRequests fails', () async {
    // arrange
    when(() => mockFriendRepository.getPendingRequests(tUserId))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to load requests')));

    // act
    final result = await usecase(tUserId);

    // assert
    expect(result, const Left(ServerFailure(message: 'Failed to load requests')));
    verify(() => mockFriendRepository.getPendingRequests(tUserId)).called(1);
    verifyNoMoreInteractions(mockFriendRepository);
  });

  test('should return NetworkFailure when there is no internet connection', () async {
    // arrange
    when(() => mockFriendRepository.getPendingRequests(tUserId))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(tUserId);

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockFriendRepository.getPendingRequests(tUserId)).called(1);
    verifyNoMoreInteractions(mockFriendRepository);
  });
}
