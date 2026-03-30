import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/location/domain/repositories/location_repository.dart';
import 'package:pulse/features/location/domain/usecases/toggle_location_sharing.dart';

class MockLocationRepository extends Mock implements LocationRepository {}

void main() {
  late ToggleLocationSharing usecase;
  late MockLocationRepository mockLocationRepository;

  setUp(() {
    mockLocationRepository = MockLocationRepository();
    usecase = ToggleLocationSharing(mockLocationRepository);
  });

  const tIsSharingEnabled = true;
  const tIsSharingDisabled = false;

  test('should return void when enabling location sharing is successful', () async {
    // arrange
    when(() => mockLocationRepository.toggleLocationSharing(tIsSharingEnabled))
        .thenAnswer((_) async => const Right(null));

    // act
    final result = await usecase(const ToggleLocationSharingParams(isSharing: tIsSharingEnabled));

    // assert
    expect(result, const Right(null));
    verify(() => mockLocationRepository.toggleLocationSharing(tIsSharingEnabled)).called(1);
    verifyNoMoreInteractions(mockLocationRepository);
  });

  test('should return void when disabling location sharing is successful', () async {
    // arrange
    when(() => mockLocationRepository.toggleLocationSharing(tIsSharingDisabled))
        .thenAnswer((_) async => const Right(null));

    // act
    final result = await usecase(const ToggleLocationSharingParams(isSharing: tIsSharingDisabled));

    // assert
    expect(result, const Right(null));
    verify(() => mockLocationRepository.toggleLocationSharing(tIsSharingDisabled)).called(1);
    verifyNoMoreInteractions(mockLocationRepository);
  });

  test('should return ServerFailure when toggling location sharing fails', () async {
    // arrange
    when(() => mockLocationRepository.toggleLocationSharing(tIsSharingEnabled))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to toggle sharing')));

    // act
    final result = await usecase(const ToggleLocationSharingParams(isSharing: tIsSharingEnabled));

    // assert
    expect(result, const Left(ServerFailure(message: 'Failed to toggle sharing')));
    verify(() => mockLocationRepository.toggleLocationSharing(tIsSharingEnabled)).called(1);
    verifyNoMoreInteractions(mockLocationRepository);
  });

  test('should return NetworkFailure when there is no internet connection', () async {
    // arrange
    when(() => mockLocationRepository.toggleLocationSharing(tIsSharingEnabled))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(const ToggleLocationSharingParams(isSharing: tIsSharingEnabled));

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockLocationRepository.toggleLocationSharing(tIsSharingEnabled)).called(1);
  });

  test('ToggleLocationSharingParams should have correct props', () {
    // arrange
    const tParams = ToggleLocationSharingParams(isSharing: tIsSharingEnabled);

    // assert
    expect(tParams.props, [tIsSharingEnabled]);
  });
}
