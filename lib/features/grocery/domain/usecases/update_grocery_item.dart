import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/grocery_item.dart';
import '../repositories/grocery_repository.dart';

class UpdateGroceryItem
    implements UseCase<GroceryItem, UpdateGroceryItemParams> {
  final GroceryRepository repository;

  UpdateGroceryItem(this.repository);

  @override
  Future<Either<Failure, GroceryItem>> call(UpdateGroceryItemParams params) {
    return repository.updateGroceryItem(
      params.item,
      imagePath: params.imagePath,
      clearImage: params.clearImage,
    );
  }
}

class UpdateGroceryItemParams extends Equatable {
  final GroceryItem item;
  final String? imagePath;
  final bool clearImage;

  const UpdateGroceryItemParams({
    required this.item,
    this.imagePath,
    this.clearImage = false,
  });

  @override
  List<Object?> get props => [item, imagePath, clearImage];
}
