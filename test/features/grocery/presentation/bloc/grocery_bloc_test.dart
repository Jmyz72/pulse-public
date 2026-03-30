import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/core/usecases/usecase.dart';
import 'package:pulse/features/grocery/domain/entities/grocery_item.dart';
import 'package:pulse/features/grocery/domain/usecases/add_grocery_item.dart';
import 'package:pulse/features/grocery/domain/usecases/delete_grocery_item.dart';
import 'package:pulse/features/grocery/domain/usecases/get_grocery_items.dart';
import 'package:pulse/features/grocery/domain/usecases/toggle_purchased.dart';
import 'package:pulse/features/grocery/domain/usecases/update_grocery_item.dart';
import 'package:pulse/features/grocery/domain/usecases/watch_grocery_items.dart';
import 'package:pulse/features/grocery/presentation/bloc/grocery_bloc.dart';

class MockGetGroceryItems extends Mock implements GetGroceryItems {}

class MockAddGroceryItem extends Mock implements AddGroceryItem {}

class MockDeleteGroceryItem extends Mock implements DeleteGroceryItem {}

class MockTogglePurchased extends Mock implements TogglePurchased {}

class MockUpdateGroceryItem extends Mock implements UpdateGroceryItem {}

class MockWatchGroceryItems extends Mock implements WatchGroceryItems {}

void main() {
  late GroceryBloc bloc;
  late MockGetGroceryItems mockGetGroceryItems;
  late MockAddGroceryItem mockAddGroceryItem;
  late MockDeleteGroceryItem mockDeleteGroceryItem;
  late MockTogglePurchased mockTogglePurchased;
  late MockUpdateGroceryItem mockUpdateGroceryItem;
  late MockWatchGroceryItems mockWatchGroceryItems;

  setUp(() {
    mockGetGroceryItems = MockGetGroceryItems();
    mockAddGroceryItem = MockAddGroceryItem();
    mockDeleteGroceryItem = MockDeleteGroceryItem();
    mockTogglePurchased = MockTogglePurchased();
    mockUpdateGroceryItem = MockUpdateGroceryItem();
    mockWatchGroceryItems = MockWatchGroceryItems();

    bloc = GroceryBloc(
      getGroceryItems: mockGetGroceryItems,
      addGroceryItem: mockAddGroceryItem,
      deleteGroceryItem: mockDeleteGroceryItem,
      togglePurchased: mockTogglePurchased,
      updateGroceryItem: mockUpdateGroceryItem,
      watchGroceryItems: mockWatchGroceryItems,
    );
  });

  tearDown(() {
    bloc.close();
  });

  const tChatRoomIds = ['chat-1', 'chat-2'];

  final tGroceryItem = GroceryItem(
    id: '1',
    name: 'Milk',
    quantity: 2,
    isPurchased: false,
    chatRoomId: 'chat-1',
    addedBy: 'user-1',
    createdAt: DateTime(2024, 1, 1),
  );

  final tGroceryItems = [tGroceryItem];

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const GetGroceryItemsParams(chatRoomIds: ['chat-1']));
    registerFallbackValue(AddGroceryItemParams(item: tGroceryItem));
    registerFallbackValue(const DeleteGroceryItemParams(id: '1'));
    registerFallbackValue(
      const TogglePurchasedParams(id: '1', userId: 'user-1'),
    );
    registerFallbackValue(UpdateGroceryItemParams(item: tGroceryItem));
  });

  group('GroceryLoadRequested', () {
    blocTest<GroceryBloc, GroceryState>(
      'emits [loading, loaded] when items are loaded successfully',
      build: () {
        when(
          () => mockGetGroceryItems(any()),
        ).thenAnswer((_) async => Right(tGroceryItems));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const GroceryLoadRequested(chatRoomIds: tChatRoomIds)),
      expect: () => [
        const GroceryState(status: GroceryStatus.loading),
        GroceryState(status: GroceryStatus.loaded, items: tGroceryItems),
      ],
      verify: (_) {
        verify(() => mockGetGroceryItems(any())).called(1);
      },
    );

    blocTest<GroceryBloc, GroceryState>(
      'emits [loading, loaded] with empty list when no items exist',
      build: () {
        when(
          () => mockGetGroceryItems(any()),
        ).thenAnswer((_) async => const Right([]));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const GroceryLoadRequested(chatRoomIds: tChatRoomIds)),
      expect: () => [
        const GroceryState(status: GroceryStatus.loading),
        const GroceryState(status: GroceryStatus.loaded, items: []),
      ],
    );

    blocTest<GroceryBloc, GroceryState>(
      'emits [loading, error] when loading fails',
      build: () {
        when(() => mockGetGroceryItems(any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Server error')),
        );
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const GroceryLoadRequested(chatRoomIds: tChatRoomIds)),
      expect: () => [
        const GroceryState(status: GroceryStatus.loading),
        const GroceryState(
          status: GroceryStatus.error,
          errorMessage: 'Server error',
        ),
      ],
    );
  });

  group('GroceryItemAddRequested', () {
    blocTest<GroceryBloc, GroceryState>(
      'emits [optimistic, loaded] when item is added successfully',
      build: () {
        when(
          () => mockAddGroceryItem(any()),
        ).thenAnswer((_) async => Right(tGroceryItem));
        return bloc;
      },
      act: (bloc) => bloc.add(GroceryItemAddRequested(item: tGroceryItem)),
      expect: () => [
        // Optimistic update
        GroceryState(status: GroceryStatus.initial, items: [tGroceryItem]),
        // Server response (status changes to loaded)
        GroceryState(status: GroceryStatus.loaded, items: [tGroceryItem]),
      ],
      verify: (_) {
        verify(() => mockAddGroceryItem(any())).called(1);
      },
    );

    blocTest<GroceryBloc, GroceryState>(
      'emits [optimistic, error with rollback] when adding item fails',
      build: () {
        when(() => mockAddGroceryItem(any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Failed to add')),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(GroceryItemAddRequested(item: tGroceryItem)),
      expect: () => [
        // Optimistic update
        GroceryState(status: GroceryStatus.initial, items: [tGroceryItem]),
        // Rollback on failure
        const GroceryState(
          status: GroceryStatus.error,
          items: [],
          errorMessage: 'Failed to add',
        ),
      ],
    );

    blocTest<GroceryBloc, GroceryState>(
      'forwards image path when adding an item with a photo',
      build: () {
        when(
          () => mockAddGroceryItem(any()),
        ).thenAnswer((_) async => Right(tGroceryItem));
        return bloc;
      },
      act: (bloc) => bloc.add(
        GroceryItemAddRequested(item: tGroceryItem, imagePath: '/tmp/milk.jpg'),
      ),
      verify: (_) {
        verify(
          () => mockAddGroceryItem(
            AddGroceryItemParams(
              item: tGroceryItem,
              imagePath: '/tmp/milk.jpg',
            ),
          ),
        ).called(1);
      },
    );
  });

  group('GroceryItemToggleRequested', () {
    final tToggledItem = GroceryItem(
      id: '1',
      name: 'Milk',
      quantity: 2,
      isPurchased: true,
      purchasedBy: 'user-1',
      purchasedByName: 'Test User',
      chatRoomId: 'chat-1',
      addedBy: 'user-1',
      createdAt: DateTime(2024, 1, 1),
    );

    blocTest<GroceryBloc, GroceryState>(
      'emits optimistic update when toggle succeeds',
      build: () {
        when(
          () => mockTogglePurchased(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      seed: () =>
          GroceryState(status: GroceryStatus.loaded, items: [tGroceryItem]),
      act: (bloc) => bloc.add(
        const GroceryItemToggleRequested(
          itemId: '1',
          userId: 'user-1',
          userName: 'Test User',
        ),
      ),
      expect: () => [
        // Optimistic update (status remains loaded, items change)
        GroceryState(status: GroceryStatus.loaded, items: [tToggledItem]),
        // Server confirmed - same state, no duplicate emission due to Equatable
      ],
      verify: (_) {
        verify(() => mockTogglePurchased(any())).called(1);
      },
    );

    blocTest<GroceryBloc, GroceryState>(
      'emits [optimistic, error with rollback] when toggle fails',
      build: () {
        when(() => mockTogglePurchased(any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Failed to toggle')),
        );
        return bloc;
      },
      seed: () =>
          GroceryState(status: GroceryStatus.loaded, items: [tGroceryItem]),
      act: (bloc) => bloc.add(
        const GroceryItemToggleRequested(
          itemId: '1',
          userId: 'user-1',
          userName: 'Test User',
        ),
      ),
      expect: () => [
        // Optimistic update
        GroceryState(status: GroceryStatus.loaded, items: [tToggledItem]),
        // Rollback on failure
        GroceryState(
          status: GroceryStatus.error,
          items: [tGroceryItem],
          errorMessage: 'Failed to toggle',
        ),
      ],
    );
  });

  group('GroceryItemDeleteRequested', () {
    blocTest<GroceryBloc, GroceryState>(
      'emits optimistic update when deletion succeeds',
      build: () {
        when(
          () => mockDeleteGroceryItem(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      seed: () =>
          GroceryState(status: GroceryStatus.loaded, items: [tGroceryItem]),
      act: (bloc) => bloc.add(const GroceryItemDeleteRequested(itemId: '1')),
      expect: () => [
        // Optimistic update - items removed
        const GroceryState(status: GroceryStatus.loaded, items: []),
        // Server confirmed - same state, no duplicate emission due to Equatable
      ],
      verify: (_) {
        verify(() => mockDeleteGroceryItem(any())).called(1);
      },
    );

    blocTest<GroceryBloc, GroceryState>(
      'emits [optimistic, error with rollback] when deletion fails',
      build: () {
        when(() => mockDeleteGroceryItem(any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Failed to delete')),
        );
        return bloc;
      },
      seed: () =>
          GroceryState(status: GroceryStatus.loaded, items: [tGroceryItem]),
      act: (bloc) => bloc.add(const GroceryItemDeleteRequested(itemId: '1')),
      expect: () => [
        // Optimistic update
        const GroceryState(status: GroceryStatus.loaded, items: []),
        // Rollback on failure
        GroceryState(
          status: GroceryStatus.error,
          items: [tGroceryItem],
          errorMessage: 'Failed to delete',
        ),
      ],
    );
  });

  group('GroceryItemUpdateRequested', () {
    final tUpdatedItem = GroceryItem(
      id: '1',
      name: 'Skim Milk',
      quantity: 3,
      isPurchased: false,
      chatRoomId: 'chat-1',
      addedBy: 'user-1',
      createdAt: DateTime(2024, 1, 1),
    );

    blocTest<GroceryBloc, GroceryState>(
      'emits optimistic update when update succeeds',
      build: () {
        when(
          () => mockUpdateGroceryItem(any()),
        ).thenAnswer((_) async => Right(tUpdatedItem));
        return bloc;
      },
      seed: () =>
          GroceryState(status: GroceryStatus.loaded, items: [tGroceryItem]),
      act: (bloc) => bloc.add(GroceryItemUpdateRequested(item: tUpdatedItem)),
      expect: () => [
        // Optimistic update
        GroceryState(status: GroceryStatus.loaded, items: [tUpdatedItem]),
        // Server confirmed - same state, no duplicate emission due to Equatable
      ],
      verify: (_) {
        verify(() => mockUpdateGroceryItem(any())).called(1);
      },
    );

    blocTest<GroceryBloc, GroceryState>(
      'emits [optimistic, error with rollback] when update fails',
      build: () {
        when(() => mockUpdateGroceryItem(any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Failed to update')),
        );
        return bloc;
      },
      seed: () =>
          GroceryState(status: GroceryStatus.loaded, items: [tGroceryItem]),
      act: (bloc) => bloc.add(GroceryItemUpdateRequested(item: tUpdatedItem)),
      expect: () => [
        // Optimistic update
        GroceryState(status: GroceryStatus.loaded, items: [tUpdatedItem]),
        // Rollback on failure
        GroceryState(
          status: GroceryStatus.error,
          items: [tGroceryItem],
          errorMessage: 'Failed to update',
        ),
      ],
    );

    blocTest<GroceryBloc, GroceryState>(
      'forwards image update metadata when editing an item',
      build: () {
        when(
          () => mockUpdateGroceryItem(any()),
        ).thenAnswer((_) async => Right(tUpdatedItem));
        return bloc;
      },
      seed: () =>
          GroceryState(status: GroceryStatus.loaded, items: [tGroceryItem]),
      act: (bloc) => bloc.add(
        GroceryItemUpdateRequested(
          item: tUpdatedItem,
          imagePath: '/tmp/milk-new.jpg',
          clearImage: false,
        ),
      ),
      verify: (_) {
        verify(
          () => mockUpdateGroceryItem(
            UpdateGroceryItemParams(
              item: tUpdatedItem,
              imagePath: '/tmp/milk-new.jpg',
              clearImage: false,
            ),
          ),
        ).called(1);
      },
    );
  });
}
