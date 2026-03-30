import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/location/domain/entities/location.dart';
import 'package:pulse/features/location/domain/repositories/location_repository.dart';
import 'package:pulse/features/location/domain/usecases/update_location.dart';

class MockLocationRepository extends Mock implements LocationRepository {}

void main() {
  late UpdateLocation usecase;
  late MockLocationRepository mockLocationRepository;

  setUp(() {
    mockLocationRepository = MockLocationRepository();
    usecase = UpdateLocation(mockLocationRepository);
  });

  final tUserLocation = UserLocation(
    userId: 'user-1',
    userName: 'Test User',
    latitude: 3.1390,
    longitude: 101.6869,
    lastUpdated: DateTime(2024, 1, 15, 10, 30),
    isSharing: true,
  );

  setUpAll(() {
    registerFallbackValue(tUserLocation);
  });

  test('should return void when location update is successful', () async {
    // arrange
    when(() => mockLocationRepository.updateLocation(any()))
        .thenAnswer((_) async => const Right(null));

    // act
    final result = await usecase(UpdateLocationParams(location: tUserLocation));

    // assert
    expect(result, const Right(null));
    verify(() => mockLocationRepository.updateLocation(tUserLocation)).called(1);
    verifyNoMoreInteractions(mockLocationRepository);
  });

  test('should return ServerFailure when location update fails', () async {
    // arrange
    when(() => mockLocationRepository.updateLocation(any()))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to update location')));

    // act
    final result = await usecase(UpdateLocationParams(location: tUserLocation));

    // assert
    expect(result, const Left(ServerFailure(message: 'Failed to update location')));
    verify(() => mockLocationRepository.updateLocation(tUserLocation)).called(1);
    verifyNoMoreInteractions(mockLocationRepository);
  });

  test('should return NetworkFailure when there is no internet connection', () async {
    // arrange
    when(() => mockLocationRepository.updateLocation(any()))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(UpdateLocationParams(location: tUserLocation));

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockLocationRepository.updateLocation(tUserLocation)).called(1);
  });

  test('UpdateLocationParams should have correct props', () {
    // arrange
    final tParams = UpdateLocationParams(location: tUserLocation);

    // assert
    expect(tParams.props, [tUserLocation]);
  });
}
