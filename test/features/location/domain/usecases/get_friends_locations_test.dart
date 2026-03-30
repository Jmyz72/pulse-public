import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/location/domain/entities/location.dart';
import 'package:pulse/features/location/domain/repositories/location_repository.dart';
import 'package:pulse/features/location/domain/usecases/get_friends_locations.dart';

class MockLocationRepository extends Mock implements LocationRepository {}

void main() {
  late GetFriendsLocations usecase;
  late MockLocationRepository mockLocationRepository;

  setUp(() {
    mockLocationRepository = MockLocationRepository();
    usecase = GetFriendsLocations(mockLocationRepository);
  });

  const tUserId = 'user-1';

  final tFriendLocation1 = UserLocation(
    userId: 'friend-1',
    userName: 'Alice',
    latitude: 3.1400,
    longitude: 101.6900,
    lastUpdated: DateTime(2024, 1, 15, 10, 30),
    isSharing: true,
  );

  final tFriendLocation2 = UserLocation(
    userId: 'friend-2',
    userName: 'Bob',
    latitude: 3.1350,
    longitude: 101.6800,
    lastUpdated: DateTime(2024, 1, 15, 10, 25),
    isSharing: true,
  );

  final tFriendsLocations = [tFriendLocation1, tFriendLocation2];

  test('should return list of UserLocation when getting friends locations is successful', () async {
    // arrange
    when(() => mockLocationRepository.getFriendsLocations(tUserId))
        .thenAnswer((_) async => Right(tFriendsLocations));

    // act
    final result = await usecase(const GetFriendsLocationsParams(userId: tUserId));

    // assert
    expect(result, Right(tFriendsLocations));
    verify(() => mockLocationRepository.getFriendsLocations(tUserId)).called(1);
    verifyNoMoreInteractions(mockLocationRepository);
  });

  test('should return empty list when no friends are sharing location', () async {
    // arrange
    when(() => mockLocationRepository.getFriendsLocations(tUserId))
        .thenAnswer((_) async => const Right([]));

    // act
    final result = await usecase(const GetFriendsLocationsParams(userId: tUserId));

    // assert
    expect(result, const Right(<UserLocation>[]));
    verify(() => mockLocationRepository.getFriendsLocations(tUserId)).called(1);
    verifyNoMoreInteractions(mockLocationRepository);
  });

  test('should return ServerFailure when getting friends locations fails', () async {
    // arrange
    when(() => mockLocationRepository.getFriendsLocations(tUserId))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to fetch friends locations')));

    // act
    final result = await usecase(const GetFriendsLocationsParams(userId: tUserId));

    // assert
    expect(result, const Left(ServerFailure(message: 'Failed to fetch friends locations')));
    verify(() => mockLocationRepository.getFriendsLocations(tUserId)).called(1);
    verifyNoMoreInteractions(mockLocationRepository);
  });

  test('should return NetworkFailure when there is no internet connection', () async {
    // arrange
    when(() => mockLocationRepository.getFriendsLocations(tUserId))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(const GetFriendsLocationsParams(userId: tUserId));

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockLocationRepository.getFriendsLocations(tUserId)).called(1);
  });
}
