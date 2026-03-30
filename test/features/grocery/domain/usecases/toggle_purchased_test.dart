import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/grocery/domain/repositories/grocery_repository.dart';
import 'package:pulse/features/grocery/domain/usecases/toggle_purchased.dart';

class MockGroceryRepository extends Mock implements GroceryRepository {}

void main() {
  late TogglePurchased usecase;
  late MockGroceryRepository mockRepository;

  setUp(() {
    mockRepository = MockGroceryRepository();
    usecase = TogglePurchased(mockRepository);
  });

  const tItemId = 'item-1';
  const tUserId = 'user-1';
  const tUserName = 'Test User';

  test('should return void when toggle is successful', () async {
    // arrange
    when(() => mockRepository.togglePurchased(tItemId, userId: tUserId, userName: tUserName))
        .thenAnswer((_) async => const Right(null));

    // act
    final result = await usecase(const TogglePurchasedParams(id: tItemId, userId: tUserId, userName: tUserName));

    // assert
    expect(result, const Right(null));
    verify(() => mockRepository.togglePurchased(tItemId, userId: tUserId, userName: tUserName)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return ServerFailure when toggle fails', () async {
    // arrange
    when(() => mockRepository.togglePurchased(tItemId, userId: tUserId, userName: tUserName))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to toggle')));

    // act
    final result = await usecase(const TogglePurchasedParams(id: tItemId, userId: tUserId, userName: tUserName));

    // assert
    expect(result, const Left(ServerFailure(message: 'Failed to toggle')));
    verify(() => mockRepository.togglePurchased(tItemId, userId: tUserId, userName: tUserName)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return NetworkFailure when there is no internet', () async {
    // arrange
    when(() => mockRepository.togglePurchased(tItemId, userId: tUserId, userName: tUserName))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(const TogglePurchasedParams(id: tItemId, userId: tUserId, userName: tUserName));

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockRepository.togglePurchased(tItemId, userId: tUserId, userName: tUserName)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
