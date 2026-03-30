import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/grocery_item.dart';

abstract class GroceryRepository {
  Future<Either<Failure, List<GroceryItem>>> getGroceryItems(
    List<String> chatRoomIds,
  );
  Future<Either<Failure, GroceryItem>> addGroceryItem(
    GroceryItem item, {
    String? imagePath,
  });
  Future<Either<Failure, GroceryItem>> updateGroceryItem(
    GroceryItem item, {
    String? imagePath,
    bool clearImage = false,
  });
  Future<Either<Failure, void>> deleteGroceryItem(String id);
  Future<Either<Failure, void>> togglePurchased(
    String id, {
    required String userId,
    String? userName,
  });
  Future<Either<Failure, List<GroceryItem>>> getGroceryItemsByChatRoom(
    String chatRoomId,
  );
  Stream<List<GroceryItem>> watchGroceryItems(List<String> chatRoomIds);
}
