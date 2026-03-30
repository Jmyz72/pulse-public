import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/friends/domain/entities/friend_profile_stats.dart';
import 'package:pulse/features/friends/domain/repositories/friend_repository.dart';
import 'package:pulse/features/friends/domain/usecases/get_friend_profile_stats.dart';

class MockFriendRepository extends Mock implements FriendRepository {}

void main() {
  late GetFriendProfileStats usecase;
  late MockFriendRepository mockFriendRepository;

  const tCurrentUserId = 'user-123';
  const tFriendUserId = 'friend-123';
  const tParams = GetFriendProfileStatsParams(
    currentUserId: tCurrentUserId,
    friendUserId: tFriendUserId,
  );
  const tStats = FriendProfileStats(
    mutualRoomsCount: 3,
    mutualFriendsCount: 5,
    isOnline: true,
  );

  setUp(() {
    mockFriendRepository = MockFriendRepository();
    usecase = GetFriendProfileStats(mockFriendRepository);
  });

  test(
    'should return stats when getFriendProfileStats is successful',
    () async {
      when(
        () => mockFriendRepository.getFriendProfileStats(
          currentUserId: tCurrentUserId,
          friendUserId: tFriendUserId,
        ),
      ).thenAnswer((_) async => const Right(tStats));

      final result = await usecase(tParams);

      expect(result, const Right(tStats));
      verify(
        () => mockFriendRepository.getFriendProfileStats(
          currentUserId: tCurrentUserId,
          friendUserId: tFriendUserId,
        ),
      ).called(1);
      verifyNoMoreInteractions(mockFriendRepository);
    },
  );

  test('should return failure when getFriendProfileStats fails', () async {
    when(
      () => mockFriendRepository.getFriendProfileStats(
        currentUserId: tCurrentUserId,
        friendUserId: tFriendUserId,
      ),
    ).thenAnswer(
      (_) async => const Left(ServerFailure(message: 'Unable to load stats')),
    );

    final result = await usecase(tParams);

    expect(result, const Left(ServerFailure(message: 'Unable to load stats')));
    verify(
      () => mockFriendRepository.getFriendProfileStats(
        currentUserId: tCurrentUserId,
        friendUserId: tFriendUserId,
      ),
    ).called(1);
    verifyNoMoreInteractions(mockFriendRepository);
  });
}
