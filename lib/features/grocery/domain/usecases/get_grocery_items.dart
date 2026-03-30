import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/grocery_item.dart';
import '../repositories/grocery_repository.dart';

class GetGroceryItems implements UseCase<List<GroceryItem>, GetGroceryItemsParams> {
  final GroceryRepository repository;

  GetGroceryItems(this.repository);

  @override
  Future<Either<Failure, List<GroceryItem>>> call(GetGroceryItemsParams params) {
    return repository.getGroceryItems(params.chatRoomIds);
  }
}

class GetGroceryItemsParams extends Equatable {
  final List<String> chatRoomIds;

  const GetGroceryItemsParams({required this.chatRoomIds});

  @override
  List<Object> get props => [chatRoomIds];
}
