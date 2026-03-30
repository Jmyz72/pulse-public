import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/bill_summary.dart';
import '../repositories/bill_repository.dart';

class GetBillsSummary implements UseCase<BillSummary, GetBillsSummaryParams> {
  final BillRepository repository;

  GetBillsSummary(this.repository);

  @override
  Future<Either<Failure, BillSummary>> call(GetBillsSummaryParams params) {
    return repository.getBillsSummary(params.userId, params.chatRoomIds);
  }
}

class GetBillsSummaryParams extends Equatable {
  final String userId;
  final List<String> chatRoomIds;

  const GetBillsSummaryParams({
    required this.userId,
    required this.chatRoomIds,
  });

  @override
  List<Object> get props => [userId, chatRoomIds];
}
