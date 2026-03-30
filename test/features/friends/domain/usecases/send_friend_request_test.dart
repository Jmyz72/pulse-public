import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/friends/domain/entities/friendship.dart';
import 'package:pulse/features/friends/domain/repositories/friend_repository.dart';
import 'package:pulse/features/friends/domain/usecases/send_friend_request.dart';

class MockFriendRepository extends Mock implements FriendRepository {}

void main() {
  late SendFriendRequest usecase;
  late MockFriendRepository mockFriendRepository;

  setUp(() {
    mockFriendRepository = MockFriendRepository();
    usecase = SendFriendRequest(mockFriendRepository);
  });

  const tUserId = 'user-123';
  const tFriendEmail = 'friend@test.com';
  final tFriendship = Friendship(
    id: 'friendship-1',
    userId: tUserId,
    friendId: 'friend-1',
    friendUsername: 'friend',
    friendDisplayName: 'Friend',
    friendEmail: tFriendEmail,
    friendPhone: '+1234567890',
    requesterUsername: 'user',
    requesterDisplayName: 'User',
    requesterEmail: 'user@test.com',
    requesterPhone: '+0987654321',
    status: FriendshipStatus.pending,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  test('should return Friendship when sendFriendRequest is successful', () async {
    // arrange
    when(() => mockFriendRepository.sendFriendRequest(tUserId, tFriendEmail))
        .thenAnswer((_) async => Right(tFriendship));

    // act
    final result = await usecase(const SendFriendRequestParams(userId: tUserId, friendEmail: tFriendEmail));

    // assert
    expect(result, Right(tFriendship));
    verify(() => mockFriendRepository.sendFriendRequest(tUserId, tFriendEmail)).called(1);
    verifyNoMoreInteractions(mockFriendRepository);
  });

  test('should return ServerFailure when sendFriendRequest fails', () async {
    // arrange
    when(() => mockFriendRepository.sendFriendRequest(tUserId, tFriendEmail))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to send request')));

    // act
    final result = await usecase(const SendFriendRequestParams(userId: tUserId, friendEmail: tFriendEmail));

    // assert
    expect(result, const Left(ServerFailure(message: 'Failed to send request')));
    verify(() => mockFriendRepository.sendFriendRequest(tUserId, tFriendEmail)).called(1);
    verifyNoMoreInteractions(mockFriendRepository);
  });

  test('should return ServerFailure when user not found', () async {
    // arrange
    when(() => mockFriendRepository.sendFriendRequest(tUserId, tFriendEmail))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'User not found')));

    // act
    final result = await usecase(const SendFriendRequestParams(userId: tUserId, friendEmail: tFriendEmail));

    // assert
    expect(result, const Left(ServerFailure(message: 'User not found')));
    verify(() => mockFriendRepository.sendFriendRequest(tUserId, tFriendEmail)).called(1);
    verifyNoMoreInteractions(mockFriendRepository);
  });

  test('should return NetworkFailure when there is no internet connection', () async {
    // arrange
    when(() => mockFriendRepository.sendFriendRequest(tUserId, tFriendEmail))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(const SendFriendRequestParams(userId: tUserId, friendEmail: tFriendEmail));

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockFriendRepository.sendFriendRequest(tUserId, tFriendEmail)).called(1);
    verifyNoMoreInteractions(mockFriendRepository);
  });

  group('SendFriendRequestParams', () {
    test('should have correct props', () {
      const params = SendFriendRequestParams(userId: tUserId, friendEmail: tFriendEmail);
      expect(params.props, [tUserId, tFriendEmail]);
    });

    test('two params with same values should be equal', () {
      const params1 = SendFriendRequestParams(userId: tUserId, friendEmail: tFriendEmail);
      const params2 = SendFriendRequestParams(userId: tUserId, friendEmail: tFriendEmail);
      expect(params1, params2);
    });

    test('two params with different values should not be equal', () {
      const params1 = SendFriendRequestParams(userId: tUserId, friendEmail: tFriendEmail);
      const params2 = SendFriendRequestParams(userId: 'other-user', friendEmail: tFriendEmail);
      expect(params1, isNot(params2));
    });
  });
}
