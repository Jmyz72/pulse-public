import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/bill_repository.dart';

class DeleteBill implements UseCase<void, DeleteBillParams> {
  final BillRepository repository;

  DeleteBill(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteBillParams params) {
    return repository.deleteBill(params.id);
  }
}

class DeleteBillParams extends Equatable {
  final String id;

  const DeleteBillParams({required this.id});

  @override
  List<Object> get props => [id];
}
