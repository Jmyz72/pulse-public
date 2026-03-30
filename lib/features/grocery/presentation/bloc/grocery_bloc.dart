import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../domain/entities/grocery_item.dart';
import '../../domain/usecases/add_grocery_item.dart';
import '../../domain/usecases/delete_grocery_item.dart';
import '../../domain/usecases/get_grocery_items.dart';
import '../../domain/usecases/toggle_purchased.dart';
import '../../domain/usecases/update_grocery_item.dart';
import '../../domain/usecases/watch_grocery_items.dart';

part 'grocery_event.dart';
part 'grocery_state.dart';

EventTransformer<E> throttle<E>(Duration duration) {
  return (events, mapper) => events.throttle(duration).switchMap(mapper);
}

class GroceryBloc extends Bloc<GroceryEvent, GroceryState> {
  final GetGroceryItems getGroceryItems;
  final AddGroceryItem addGroceryItem;
  final DeleteGroceryItem deleteGroceryItem;
  final TogglePurchased togglePurchased;
  final UpdateGroceryItem updateGroceryItem;
  final WatchGroceryItems watchGroceryItems;

  StreamSubscription<List<GroceryItem>>? _grocerySubscription;

  GroceryBloc({
    required this.getGroceryItems,
    required this.addGroceryItem,
    required this.deleteGroceryItem,
    required this.togglePurchased,
    required this.updateGroceryItem,
    required this.watchGroceryItems,
  }) : super(const GroceryState()) {
    on<GroceryLoadRequested>(_onLoadRequested, transformer: droppable());
    on<GroceryWatchRequested>(_onWatchRequested, transformer: droppable());
    on<GroceryWatchStopRequested>(_onWatchStopped);
    on<_GroceryItemsUpdated>(_onItemsUpdated);
    on<GroceryItemAddRequested>(
      _onItemAdded,
      transformer: throttle(const Duration(milliseconds: 500)),
    );
    on<GroceryItemToggleRequested>(
      _onItemToggled,
      transformer: throttle(const Duration(milliseconds: 300)),
    );
    on<GroceryItemDeleteRequested>(_onItemDeleted, transformer: droppable());
    on<GroceryItemUpdateRequested>(
      _onItemUpdated,
      transformer: throttle(const Duration(milliseconds: 500)),
    );
    on<GroceryItemRestoreRequested>(
      _onItemRestored,
      transformer: throttle(const Duration(milliseconds: 500)),
    );
  }

  Future<void> _onLoadRequested(
    GroceryLoadRequested event,
    Emitter<GroceryState> emit,
  ) async {
    emit(state.copyWith(status: GroceryStatus.loading));

    final result = await getGroceryItems(
      GetGroceryItemsParams(chatRoomIds: event.chatRoomIds),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: GroceryStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (items) =>
          emit(state.copyWith(status: GroceryStatus.loaded, items: items)),
    );
  }

  Future<void> _onWatchRequested(
    GroceryWatchRequested event,
    Emitter<GroceryState> emit,
  ) async {
    emit(state.copyWith(status: GroceryStatus.loading));

    await _grocerySubscription?.cancel();
    _grocerySubscription = watchGroceryItems(event.chatRoomIds).listen(
      (items) => add(_GroceryItemsUpdated(items)),
      onError: (_) => add(GroceryLoadRequested(chatRoomIds: event.chatRoomIds)),
    );
  }

  void _onWatchStopped(
    GroceryWatchStopRequested event,
    Emitter<GroceryState> emit,
  ) {
    _grocerySubscription?.cancel();
    _grocerySubscription = null;
  }

  void _onItemsUpdated(_GroceryItemsUpdated event, Emitter<GroceryState> emit) {
    emit(state.copyWith(status: GroceryStatus.loaded, items: event.items));
  }

  Future<void> _onItemAdded(
    GroceryItemAddRequested event,
    Emitter<GroceryState> emit,
  ) async {
    // Optimistic update
    final optimisticItems = [...state.items, event.item];
    emit(state.copyWith(items: optimisticItems));

    final params = AddGroceryItemParams(
      item: event.item,
      imagePath: event.imagePath,
    );
    final result = await addGroceryItem(params);
    result.fold(
      (failure) {
        // Rollback on failure
        final rolledBackItems = state.items
            .where((i) => i.id != event.item.id)
            .toList();
        emit(
          state.copyWith(
            status: GroceryStatus.error,
            errorMessage: failure.message,
            items: rolledBackItems,
          ),
        );
      },
      (item) {
        // Replace optimistic item with server response
        final updatedItems = state.items
            .map((i) => i.id == event.item.id ? item : i)
            .toList();
        emit(state.copyWith(status: GroceryStatus.loaded, items: updatedItems));
      },
    );
  }

  Future<void> _onItemToggled(
    GroceryItemToggleRequested event,
    Emitter<GroceryState> emit,
  ) async {
    // Backup for rollback
    final backup = List<GroceryItem>.from(state.items);

    // Optimistic update
    final optimisticItems = state.items.map((item) {
      if (item.id == event.itemId) {
        final toggling = !item.isPurchased;
        return toggling
            ? item.copyWith(
                isPurchased: true,
                purchasedBy: event.userId,
                purchasedByName: event.userName,
              )
            : item.copyWith(
                isPurchased: false,
                clearPurchasedBy: true,
                clearPurchasedByName: true,
              );
      }
      return item;
    }).toList();
    emit(state.copyWith(items: optimisticItems));

    final result = await togglePurchased(
      TogglePurchasedParams(
        id: event.itemId,
        userId: event.userId,
        userName: event.userName,
      ),
    );

    result.fold(
      (failure) {
        // Rollback on failure
        emit(
          state.copyWith(
            status: GroceryStatus.error,
            errorMessage: failure.message,
            items: backup,
          ),
        );
      },
      (_) {
        // Already updated optimistically, just ensure status
        emit(state.copyWith(status: GroceryStatus.loaded));
      },
    );
  }

  Future<void> _onItemDeleted(
    GroceryItemDeleteRequested event,
    Emitter<GroceryState> emit,
  ) async {
    // Backup for rollback
    final backup = List<GroceryItem>.from(state.items);

    // Optimistic update
    final optimisticItems = state.items
        .where((item) => item.id != event.itemId)
        .toList();
    emit(state.copyWith(items: optimisticItems));

    final result = await deleteGroceryItem(
      DeleteGroceryItemParams(id: event.itemId),
    );

    result.fold(
      (failure) {
        // Rollback on failure
        emit(
          state.copyWith(
            status: GroceryStatus.error,
            errorMessage: failure.message,
            items: backup,
          ),
        );
      },
      (_) {
        // Already deleted optimistically
        emit(state.copyWith(status: GroceryStatus.loaded));
      },
    );
  }

  Future<void> _onItemUpdated(
    GroceryItemUpdateRequested event,
    Emitter<GroceryState> emit,
  ) async {
    // Backup for rollback
    final backup = List<GroceryItem>.from(state.items);

    // Optimistic update
    final optimisticItems = state.items.map((item) {
      if (item.id == event.item.id) {
        return event.item;
      }
      return item;
    }).toList();
    emit(state.copyWith(items: optimisticItems));

    final result = await updateGroceryItem(
      UpdateGroceryItemParams(
        item: event.item,
        imagePath: event.imagePath,
        clearImage: event.clearImage,
      ),
    );

    result.fold(
      (failure) {
        // Rollback on failure
        emit(
          state.copyWith(
            status: GroceryStatus.error,
            errorMessage: failure.message,
            items: backup,
          ),
        );
      },
      (updatedItem) {
        // Replace with server response
        final updatedItems = state.items
            .map((i) => i.id == updatedItem.id ? updatedItem : i)
            .toList();
        emit(state.copyWith(status: GroceryStatus.loaded, items: updatedItems));
      },
    );
  }

  Future<void> _onItemRestored(
    GroceryItemRestoreRequested event,
    Emitter<GroceryState> emit,
  ) async {
    final result = await addGroceryItem(AddGroceryItemParams(item: event.item));

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: GroceryStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (_) {
        // Stream will pick up the new item automatically
        emit(state.copyWith(status: GroceryStatus.loaded));
      },
    );
  }

  @override
  Future<void> close() {
    _grocerySubscription?.cancel();
    return super.close();
  }
}
