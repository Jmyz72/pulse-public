import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/core/usecases/usecase.dart';
import 'package:pulse/features/settings/domain/repositories/settings_repository.dart';
import 'package:pulse/features/settings/domain/usecases/clear_settings_cache.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late ClearSettingsCache usecase;
  late MockSettingsRepository mockSettingsRepository;

  setUp(() {
    mockSettingsRepository = MockSettingsRepository();
    usecase = ClearSettingsCache(mockSettingsRepository);
  });

  test('should return void when clearCache is successful', () async {
    // arrange
    when(() => mockSettingsRepository.clearCache())
        .thenAnswer((_) async => const Right(null));

    // act
    final result = await usecase(const NoParams());

    // assert
    expect(result, const Right(null));
    verify(() => mockSettingsRepository.clearCache()).called(1);
    verifyNoMoreInteractions(mockSettingsRepository);
  });

  test('should return CacheFailure when clearCache fails', () async {
    // arrange
    when(() => mockSettingsRepository.clearCache())
        .thenAnswer((_) async => const Left(CacheFailure(message: 'Failed to clear cache')));

    // act
    final result = await usecase(const NoParams());

    // assert
    expect(result, const Left(CacheFailure(message: 'Failed to clear cache')));
    verify(() => mockSettingsRepository.clearCache()).called(1);
    verifyNoMoreInteractions(mockSettingsRepository);
  });
}
