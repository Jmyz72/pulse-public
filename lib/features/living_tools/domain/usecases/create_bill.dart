import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/bill.dart';
import '../repositories/bill_repository.dart';

class CreateBill implements UseCase<Bill, CreateBillParams> {
  final BillRepository repository;

  CreateBill(this.repository);

  @override
  Future<Either<Failure, Bill>> call(CreateBillParams params) {
    return repository.createBill(params.bill);
  }
}

class CreateBillParams extends Equatable {
  final Bill bill;

  const CreateBillParams({required this.bill});

  @override
  List<Object> get props => [bill];
}
