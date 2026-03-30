import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/grocery_repository.dart';

class TogglePurchased implements UseCase<void, TogglePurchasedParams> {
  final GroceryRepository repository;

  TogglePurchased(this.repository);

  @override
  Future<Either<Failure, void>> call(TogglePurchasedParams params) {
    return repository.togglePurchased(params.id, userId: params.userId, userName: params.userName);
  }
}

class TogglePurchasedParams extends Equatable {
  final String id;
  final String userId;
  final String? userName;

  const TogglePurchasedParams({required this.id, required this.userId, this.userName});

  @override
  List<Object?> get props => [id, userId, userName];
}
