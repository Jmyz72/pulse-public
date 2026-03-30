import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/core/usecases/usecase.dart';
import 'package:pulse/features/location/domain/entities/location.dart';
import 'package:pulse/features/location/domain/repositories/location_repository.dart';
import 'package:pulse/features/location/domain/usecases/get_current_location.dart';

class MockLocationRepository extends Mock implements LocationRepository {}

void main() {
  late GetCurrentLocation usecase;
  late MockLocationRepository mockLocationRepository;

  setUp(() {
    mockLocationRepository = MockLocationRepository();
    usecase = GetCurrentLocation(mockLocationRepository);
  });

  final tUserLocation = UserLocation(
    userId: 'user-1',
    userName: 'Test User',
    latitude: 3.1390,
    longitude: 101.6869,
    lastUpdated: DateTime(2024, 1, 15, 10, 30),
    isSharing: true,
  );

  test('should return UserLocation when getting current location is successful', () async {
    // arrange
    when(() => mockLocationRepository.getCurrentLocation())
        .thenAnswer((_) async => Right(tUserLocation));

    // act
    final result = await usecase(const NoParams());

    // assert
    expect(result, Right(tUserLocation));
    verify(() => mockLocationRepository.getCurrentLocation()).called(1);
    verifyNoMoreInteractions(mockLocationRepository);
  });

  test('should return ServerFailure when getting current location fails', () async {
    // arrange
    when(() => mockLocationRepository.getCurrentLocation())
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to get location')));

    // act
    final result = await usecase(const NoParams());

    // assert
    expect(result, const Left(ServerFailure(message: 'Failed to get location')));
    verify(() => mockLocationRepository.getCurrentLocation()).called(1);
    verifyNoMoreInteractions(mockLocationRepository);
  });

  test('should return NetworkFailure when there is no internet connection', () async {
    // arrange
    when(() => mockLocationRepository.getCurrentLocation())
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(const NoParams());

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockLocationRepository.getCurrentLocation()).called(1);
  });
}
