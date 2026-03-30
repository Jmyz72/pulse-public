part of 'grocery_bloc.dart';

enum GroceryStatus { initial, loading, loaded, error }

class GroceryState extends Equatable {
  final GroceryStatus status;
  final List<GroceryItem> items;
  final String? errorMessage;

  const GroceryState({
    this.status = GroceryStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  List<GroceryItem> get pendingItems => items.where((i) => !i.isPurchased).toList();

  List<GroceryItem> get purchasedItems => items.where((i) => i.isPurchased).toList();

  Map<String, List<GroceryItem>> itemsByChatRoomFiltered(List<GroceryItem> filtered) {
    final map = <String, List<GroceryItem>>{};
    for (final item in filtered) {
      (map[item.chatRoomId] ??= []).add(item);
    }
    return map;
  }

  GroceryState copyWith({
    GroceryStatus? status,
    List<GroceryItem>? items,
    String? errorMessage,
  }) {
    return GroceryState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, items, errorMessage];
}
