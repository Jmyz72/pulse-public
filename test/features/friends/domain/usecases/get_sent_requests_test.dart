import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/friends/domain/entities/friendship.dart';
import 'package:pulse/features/friends/domain/repositories/friend_repository.dart';
import 'package:pulse/features/friends/domain/usecases/get_sent_requests.dart';

class MockFriendRepository extends Mock implements FriendRepository {}

void main() {
  late GetSentRequests usecase;
  late MockFriendRepository mockFriendRepository;

  setUp(() {
    mockFriendRepository = MockFriendRepository();
    usecase = GetSentRequests(mockFriendRepository);
  });

  const tUserId = 'user-123';
  final tSentRequests = [
    Friendship(
      id: 'request-1',
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
      status: FriendshipStatus.pending,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    ),
  ];

  test(
    'should return list of sent requests when getSentRequests is successful',
    () async {
      when(
        () => mockFriendRepository.getSentRequests(tUserId),
      ).thenAnswer((_) async => Right(tSentRequests));

      final result = await usecase(tUserId);

      expect(result, Right(tSentRequests));
      verify(() => mockFriendRepository.getSentRequests(tUserId)).called(1);
      verifyNoMoreInteractions(mockFriendRepository);
    },
  );

  test('should return empty list when there are no sent requests', () async {
    when(
      () => mockFriendRepository.getSentRequests(tUserId),
    ).thenAnswer((_) async => const Right([]));

    final result = await usecase(tUserId);

    expect(result, const Right(<Friendship>[]));
    verify(() => mockFriendRepository.getSentRequests(tUserId)).called(1);
    verifyNoMoreInteractions(mockFriendRepository);
  });

  test('should return ServerFailure when getSentRequests fails', () async {
    when(() => mockFriendRepository.getSentRequests(tUserId)).thenAnswer(
      (_) async =>
          const Left(ServerFailure(message: 'Failed to load sent requests')),
    );

    final result = await usecase(tUserId);

    expect(
      result,
      const Left(ServerFailure(message: 'Failed to load sent requests')),
    );
    verify(() => mockFriendRepository.getSentRequests(tUserId)).called(1);
    verifyNoMoreInteractions(mockFriendRepository);
  });
}
