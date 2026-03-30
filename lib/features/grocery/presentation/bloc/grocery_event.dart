part of 'grocery_bloc.dart';

abstract class GroceryEvent extends Equatable {
  const GroceryEvent();

  @override
  List<Object?> get props => [];
}

class GroceryLoadRequested extends GroceryEvent {
  final List<String> chatRoomIds;

  const GroceryLoadRequested({required this.chatRoomIds});

  @override
  List<Object> get props => [chatRoomIds];
}

class GroceryWatchRequested extends GroceryEvent {
  final List<String> chatRoomIds;

  const GroceryWatchRequested({required this.chatRoomIds});

  @override
  List<Object> get props => [chatRoomIds];
}

class GroceryWatchStopRequested extends GroceryEvent {}

class _GroceryItemsUpdated extends GroceryEvent {
  final List<GroceryItem> items;

  const _GroceryItemsUpdated(this.items);

  @override
  List<Object> get props => [items];
}

class GroceryItemAddRequested extends GroceryEvent {
  final GroceryItem item;
  final String? imagePath;

  const GroceryItemAddRequested({required this.item, this.imagePath});

  @override
  List<Object?> get props => [item, imagePath];
}

class GroceryItemToggleRequested extends GroceryEvent {
  final String itemId;
  final String userId;
  final String? userName;

  const GroceryItemToggleRequested({
    required this.itemId,
    required this.userId,
    this.userName,
  });

  @override
  List<Object?> get props => [itemId, userId, userName];
}

class GroceryItemDeleteRequested extends GroceryEvent {
  final String itemId;

  const GroceryItemDeleteRequested({required this.itemId});

  @override
  List<Object> get props => [itemId];
}

class GroceryItemUpdateRequested extends GroceryEvent {
  final GroceryItem item;
  final String? imagePath;
  final bool clearImage;

  const GroceryItemUpdateRequested({
    required this.item,
    this.imagePath,
    this.clearImage = false,
  });

  @override
  List<Object?> get props => [item, imagePath, clearImage];
}

class GroceryItemRestoreRequested extends GroceryEvent {
  final GroceryItem item;

  const GroceryItemRestoreRequested({required this.item});

  @override
  List<Object> get props => [item];
}
