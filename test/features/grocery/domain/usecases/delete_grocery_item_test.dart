import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/grocery/domain/repositories/grocery_repository.dart';
import 'package:pulse/features/grocery/domain/usecases/delete_grocery_item.dart';

class MockGroceryRepository extends Mock implements GroceryRepository {}

void main() {
  late DeleteGroceryItem usecase;
  late MockGroceryRepository mockRepository;

  setUp(() {
    mockRepository = MockGroceryRepository();
    usecase = DeleteGroceryItem(mockRepository);
  });

  const tItemId = 'item-1';

  test('should return void when deletion is successful', () async {
    // arrange
    when(() => mockRepository.deleteGroceryItem(tItemId))
        .thenAnswer((_) async => const Right(null));

    // act
    final result = await usecase(const DeleteGroceryItemParams(id: tItemId));

    // assert
    expect(result, const Right(null));
    verify(() => mockRepository.deleteGroceryItem(tItemId)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return ServerFailure when deletion fails', () async {
    // arrange
    when(() => mockRepository.deleteGroceryItem(tItemId))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to delete')));

    // act
    final result = await usecase(const DeleteGroceryItemParams(id: tItemId));

    // assert
    expect(result, const Left(ServerFailure(message: 'Failed to delete')));
    verify(() => mockRepository.deleteGroceryItem(tItemId)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return NetworkFailure when there is no internet', () async {
    // arrange
    when(() => mockRepository.deleteGroceryItem(tItemId))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(const DeleteGroceryItemParams(id: tItemId));

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockRepository.deleteGroceryItem(tItemId)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
