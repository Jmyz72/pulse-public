import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/grocery_item.dart';
import '../repositories/grocery_repository.dart';

class AddGroceryItem implements UseCase<GroceryItem, AddGroceryItemParams> {
  final GroceryRepository repository;

  AddGroceryItem(this.repository);

  @override
  Future<Either<Failure, GroceryItem>> call(AddGroceryItemParams params) {
    return repository.addGroceryItem(params.item, imagePath: params.imagePath);
  }
}

class AddGroceryItemParams extends Equatable {
  final GroceryItem item;
  final String? imagePath;

  const AddGroceryItemParams({required this.item, this.imagePath});

  @override
  List<Object?> get props => [item, imagePath];
}
