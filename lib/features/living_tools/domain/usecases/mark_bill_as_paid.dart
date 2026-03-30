import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/bill_repository.dart';

class MarkBillAsPaid implements UseCase<void, MarkBillAsPaidParams> {
  final BillRepository repository;

  MarkBillAsPaid(this.repository);

  @override
  Future<Either<Failure, void>> call(MarkBillAsPaidParams params) {
    return repository.markBillAsPaid(params.billId, params.memberId);
  }
}

class MarkBillAsPaidParams extends Equatable {
  final String billId;
  final String memberId;

  const MarkBillAsPaidParams({required this.billId, required this.memberId});

  @override
  List<Object> get props => [billId, memberId];
}
