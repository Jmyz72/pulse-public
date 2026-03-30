import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/grocery_repository.dart';

class DeleteGroceryItem implements UseCase<void, DeleteGroceryItemParams> {
  final GroceryRepository repository;

  DeleteGroceryItem(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteGroceryItemParams params) {
    return repository.deleteGroceryItem(params.id);
  }
}

class DeleteGroceryItemParams extends Equatable {
  final String id;

  const DeleteGroceryItemParams({required this.id});

  @override
  List<Object> get props => [id];
}
