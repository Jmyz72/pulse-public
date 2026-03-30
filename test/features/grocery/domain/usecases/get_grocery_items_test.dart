import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/grocery/domain/entities/grocery_item.dart';
import 'package:pulse/features/grocery/domain/repositories/grocery_repository.dart';
import 'package:pulse/features/grocery/domain/usecases/get_grocery_items.dart';

class MockGroceryRepository extends Mock implements GroceryRepository {}

void main() {
  late GetGroceryItems usecase;
  late MockGroceryRepository mockRepository;

  setUp(() {
    mockRepository = MockGroceryRepository();
    usecase = GetGroceryItems(mockRepository);
  });

  const tChatRoomIds = ['chat-1', 'chat-2'];

  final tGroceryItems = [
    GroceryItem(
      id: '1',
      name: 'Milk',
      quantity: 2,
      isPurchased: false,
      chatRoomId: 'chat-1',
      addedBy: 'user-1',
      createdAt: DateTime(2024, 1, 1),
    ),
    GroceryItem(
      id: '2',
      name: 'Bread',
      quantity: 1,
      isPurchased: true,
      chatRoomId: 'chat-1',
      addedBy: 'user-1',
      createdAt: DateTime(2024, 1, 1),
    ),
  ];

  test('should return list of grocery items when successful', () async {
    // arrange
    when(() => mockRepository.getGroceryItems(tChatRoomIds))
        .thenAnswer((_) async => Right(tGroceryItems));

    // act
    final result = await usecase(const GetGroceryItemsParams(chatRoomIds: tChatRoomIds));

    // assert
    expect(result, Right(tGroceryItems));
    verify(() => mockRepository.getGroceryItems(tChatRoomIds)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return empty list when no grocery items exist', () async {
    // arrange
    when(() => mockRepository.getGroceryItems(tChatRoomIds))
        .thenAnswer((_) async => const Right(<GroceryItem>[]));

    // act
    final result = await usecase(const GetGroceryItemsParams(chatRoomIds: tChatRoomIds));

    // assert
    expect(result, const Right(<GroceryItem>[]));
    verify(() => mockRepository.getGroceryItems(tChatRoomIds)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return ServerFailure when server error occurs', () async {
    // arrange
    when(() => mockRepository.getGroceryItems(tChatRoomIds))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Server error')));

    // act
    final result = await usecase(const GetGroceryItemsParams(chatRoomIds: tChatRoomIds));

    // assert
    expect(result, const Left(ServerFailure(message: 'Server error')));
    verify(() => mockRepository.getGroceryItems(tChatRoomIds)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return NetworkFailure when there is no internet', () async {
    // arrange
    when(() => mockRepository.getGroceryItems(tChatRoomIds))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(const GetGroceryItemsParams(chatRoomIds: tChatRoomIds));

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockRepository.getGroceryItems(tChatRoomIds)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
