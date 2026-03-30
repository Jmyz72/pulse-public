import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/exceptions.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/core/network/network_info.dart';
import 'package:pulse/features/grocery/data/datasources/grocery_remote_datasource.dart';
import 'package:pulse/features/grocery/data/models/grocery_item_model.dart';
import 'package:pulse/features/grocery/data/repositories/grocery_repository_impl.dart';
import 'package:pulse/features/grocery/domain/entities/grocery_item.dart';

class MockGroceryRemoteDataSource extends Mock
    implements GroceryRemoteDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late GroceryRepositoryImpl repository;
  late MockGroceryRemoteDataSource mockRemoteDataSource;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockRemoteDataSource = MockGroceryRemoteDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = GroceryRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  final tItem = GroceryItem(
    id: 'item-1',
    name: 'Milk',
    brand: 'Dutch Lady',
    size: '2L',
    variant: 'Low fat',
    quantity: 2,
    note: 'Blue cap',
    category: 'Dairy',
    chatRoomId: 'chat-1',
    addedBy: 'user-1',
    createdAt: DateTime(2024, 1, 1),
  );

  final tModel = GroceryItemModel.fromEntity(
    tItem.copyWith(imageUrl: 'https://example.com/milk.jpg'),
  );

  setUpAll(() {
    registerFallbackValue(GroceryItemModel.fromEntity(tItem));
  });

  group('addGroceryItem', () {
    test(
      'should return added item when online and remote call succeeds',
      () async {
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(
          () => mockRemoteDataSource.addGroceryItem(
            any(),
            imagePath: any(named: 'imagePath'),
          ),
        ).thenAnswer((_) async => tModel);

        final result = await repository.addGroceryItem(
          tItem,
          imagePath: '/tmp/milk.jpg',
        );

        expect(result, Right<Failure, GroceryItem>(tModel));
        verify(
          () => mockRemoteDataSource.addGroceryItem(
            any(),
            imagePath: '/tmp/milk.jpg',
          ),
        ).called(1);
      },
    );

    test('should return NetworkFailure when offline', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      final result = await repository.addGroceryItem(tItem);

      expect(result, const Left(NetworkFailure()));
      verifyNever(
        () => mockRemoteDataSource.addGroceryItem(
          any(),
          imagePath: any(named: 'imagePath'),
        ),
      );
    });
  });

  group('updateGroceryItem', () {
    test(
      'should forward image replacement and clear flag to remote data source',
      () async {
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(
          () => mockRemoteDataSource.updateGroceryItem(
            any(),
            imagePath: any(named: 'imagePath'),
            clearImage: any(named: 'clearImage'),
          ),
        ).thenAnswer((_) async => tModel);

        final result = await repository.updateGroceryItem(
          tItem,
          imagePath: '/tmp/milk-new.jpg',
          clearImage: false,
        );

        expect(result, Right<Failure, GroceryItem>(tModel));
        verify(
          () => mockRemoteDataSource.updateGroceryItem(
            any(),
            imagePath: '/tmp/milk-new.jpg',
            clearImage: false,
          ),
        ).called(1);
      },
    );

    test('should return ServerFailure when remote throws', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(
        () => mockRemoteDataSource.updateGroceryItem(
          any(),
          imagePath: any(named: 'imagePath'),
          clearImage: any(named: 'clearImage'),
        ),
      ).thenThrow(const ServerException(message: 'update failed'));

      final result = await repository.updateGroceryItem(
        tItem,
        clearImage: true,
      );

      expect(result, const Left(ServerFailure(message: 'update failed')));
    });
  });
}
