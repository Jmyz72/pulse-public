import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/grocery_item.dart';
import '../../domain/repositories/grocery_repository.dart';
import '../datasources/grocery_remote_datasource.dart';
import '../models/grocery_item_model.dart';

class GroceryRepositoryImpl implements GroceryRepository {
  final GroceryRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  GroceryRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<GroceryItem>>> getGroceryItems(
    List<String> chatRoomIds,
  ) async {
    try {
      final items = await remoteDataSource.getGroceryItems(chatRoomIds);
      return Right(items);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, GroceryItem>> addGroceryItem(
    GroceryItem item, {
    String? imagePath,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final model = GroceryItemModel.fromEntity(item);
      final result = await remoteDataSource.addGroceryItem(
        model,
        imagePath: imagePath,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, GroceryItem>> updateGroceryItem(
    GroceryItem item, {
    String? imagePath,
    bool clearImage = false,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final model = GroceryItemModel.fromEntity(item);
      final result = await remoteDataSource.updateGroceryItem(
        model,
        imagePath: imagePath,
        clearImage: clearImage,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteGroceryItem(String id) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await remoteDataSource.deleteGroceryItem(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> togglePurchased(
    String id, {
    required String userId,
    String? userName,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await remoteDataSource.togglePurchased(
        id,
        userId: userId,
        userName: userName,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Stream<List<GroceryItem>> watchGroceryItems(List<String> chatRoomIds) {
    return remoteDataSource.watchGroceryItems(chatRoomIds);
  }

  @override
  Future<Either<Failure, List<GroceryItem>>> getGroceryItemsByChatRoom(
    String chatRoomId,
  ) async {
    try {
      final items = await remoteDataSource.getGroceryItemsByChatRoom(
        chatRoomId,
      );
      return Right(items);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}
