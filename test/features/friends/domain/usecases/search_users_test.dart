import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/auth/domain/entities/user.dart';
import 'package:pulse/features/friends/domain/repositories/friend_repository.dart';
import 'package:pulse/features/friends/domain/usecases/search_users.dart';

class MockFriendRepository extends Mock implements FriendRepository {}

void main() {
  late SearchUsers usecase;
  late MockFriendRepository mockFriendRepository;

  setUp(() {
    mockFriendRepository = MockFriendRepository();
    usecase = SearchUsers(mockFriendRepository);
  });

  const tQuery = 'john';
  final tUsers = [
    User(
      id: 'user-1',
      username: 'johndoe',
      displayName: 'John Doe',
      email: 'john@test.com',
      phone: '+1234567890',
      dateJoining: DateTime(2024, 1, 1),
    ),
    User(
      id: 'user-2',
      username: 'johnny',
      displayName: 'Johnny Smith',
      email: 'johnny@test.com',
      phone: '+1234567891',
      dateJoining: DateTime(2024, 1, 2),
    ),
  ];

  test('should return list of users when searchUsers is successful', () async {
    // arrange
    when(() => mockFriendRepository.searchUsers(tQuery))
        .thenAnswer((_) async => Right(tUsers));

    // act
    final result = await usecase(tQuery);

    // assert
    expect(result, Right(tUsers));
    verify(() => mockFriendRepository.searchUsers(tQuery)).called(1);
    verifyNoMoreInteractions(mockFriendRepository);
  });

  test('should return empty list when no users match the query', () async {
    // arrange
    when(() => mockFriendRepository.searchUsers(tQuery))
        .thenAnswer((_) async => const Right([]));

    // act
    final result = await usecase(tQuery);

    // assert
    expect(result, const Right(<User>[]));
    verify(() => mockFriendRepository.searchUsers(tQuery)).called(1);
    verifyNoMoreInteractions(mockFriendRepository);
  });

  test('should return ServerFailure when searchUsers fails', () async {
    // arrange
    when(() => mockFriendRepository.searchUsers(tQuery))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Search failed')));

    // act
    final result = await usecase(tQuery);

    // assert
    expect(result, const Left(ServerFailure(message: 'Search failed')));
    verify(() => mockFriendRepository.searchUsers(tQuery)).called(1);
    verifyNoMoreInteractions(mockFriendRepository);
  });

  test('should return NetworkFailure when there is no internet connection', () async {
    // arrange
    when(() => mockFriendRepository.searchUsers(tQuery))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(tQuery);

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockFriendRepository.searchUsers(tQuery)).called(1);
    verifyNoMoreInteractions(mockFriendRepository);
  });
}
