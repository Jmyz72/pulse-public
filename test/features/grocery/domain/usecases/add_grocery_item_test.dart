import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/grocery/domain/entities/grocery_item.dart';
import 'package:pulse/features/grocery/domain/repositories/grocery_repository.dart';
import 'package:pulse/features/grocery/domain/usecases/add_grocery_item.dart';

class MockGroceryRepository extends Mock implements GroceryRepository {}

void main() {
  late AddGroceryItem usecase;
  late MockGroceryRepository mockRepository;

  setUp(() {
    mockRepository = MockGroceryRepository();
    usecase = AddGroceryItem(mockRepository);
  });

  final tGroceryItem = GroceryItem(
    id: '1',
    name: 'Milk',
    quantity: 2,
    isPurchased: false,
    chatRoomId: 'chat-1',
    addedBy: 'user-1',
    createdAt: DateTime(2024, 1, 1),
  );

  setUpAll(() {
    registerFallbackValue(tGroceryItem);
  });

  test('should return added grocery item when successful', () async {
    // arrange
    when(
      () => mockRepository.addGroceryItem(
        any(),
        imagePath: any(named: 'imagePath'),
      ),
    ).thenAnswer((_) async => Right(tGroceryItem));

    // act
    final result = await usecase(AddGroceryItemParams(item: tGroceryItem));

    // assert
    expect(result, Right(tGroceryItem));
    verify(
      () => mockRepository.addGroceryItem(
        any(),
        imagePath: any(named: 'imagePath'),
      ),
    ).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return ServerFailure when server error occurs', () async {
    // arrange
    when(
      () => mockRepository.addGroceryItem(
        any(),
        imagePath: any(named: 'imagePath'),
      ),
    ).thenAnswer(
      (_) async => const Left(ServerFailure(message: 'Failed to add item')),
    );

    // act
    final result = await usecase(AddGroceryItemParams(item: tGroceryItem));

    // assert
    expect(result, const Left(ServerFailure(message: 'Failed to add item')));
    verify(
      () => mockRepository.addGroceryItem(
        any(),
        imagePath: any(named: 'imagePath'),
      ),
    ).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return NetworkFailure when there is no internet', () async {
    // arrange
    when(
      () => mockRepository.addGroceryItem(
        any(),
        imagePath: any(named: 'imagePath'),
      ),
    ).thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(AddGroceryItemParams(item: tGroceryItem));

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(
      () => mockRepository.addGroceryItem(
        any(),
        imagePath: any(named: 'imagePath'),
      ),
    ).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should pass image path through to repository', () async {
    // arrange
    when(
      () => mockRepository.addGroceryItem(
        any(),
        imagePath: any(named: 'imagePath'),
      ),
    ).thenAnswer((_) async => Right(tGroceryItem));

    // act
    await usecase(
      AddGroceryItemParams(item: tGroceryItem, imagePath: '/tmp/milk.jpg'),
    );

    // assert
    verify(
      () => mockRepository.addGroceryItem(
        tGroceryItem,
        imagePath: '/tmp/milk.jpg',
      ),
    ).called(1);
  });
}
