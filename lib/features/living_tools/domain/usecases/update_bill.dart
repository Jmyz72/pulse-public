import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/bill.dart';
import '../repositories/bill_repository.dart';

class UpdateBill implements UseCase<Bill, UpdateBillParams> {
  final BillRepository repository;

  UpdateBill(this.repository);

  @override
  Future<Either<Failure, Bill>> call(UpdateBillParams params) {
    return repository.updateBill(params.bill);
  }
}

class UpdateBillParams extends Equatable {
  final Bill bill;

  const UpdateBillParams({required this.bill});

  @override
  List<Object> get props => [bill];
}
