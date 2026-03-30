import '../entities/grocery_item.dart';
import '../repositories/grocery_repository.dart';

class WatchGroceryItems {
  final GroceryRepository repository;

  WatchGroceryItems(this.repository);

  Stream<List<GroceryItem>> call(List<String> chatRoomIds) {
    return repository.watchGroceryItems(chatRoomIds);
  }
}
