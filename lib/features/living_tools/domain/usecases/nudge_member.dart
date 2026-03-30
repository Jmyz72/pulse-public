import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/bill_repository.dart';

class NudgeMember implements UseCase<void, NudgeMemberParams> {
  final BillRepository repository;

  NudgeMember(this.repository);

  @override
  Future<Either<Failure, void>> call(NudgeMemberParams params) {
    return repository.nudgeMember(params.billId, params.memberId);
  }
}

class NudgeMemberParams extends Equatable {
  final String billId;
  final String memberId;

  const NudgeMemberParams({required this.billId, required this.memberId});

  @override
  List<Object> get props => [billId, memberId];
}
