import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/bill.dart';
import '../repositories/bill_repository.dart';

class GetBills implements UseCase<List<Bill>, GetBillsParams> {
  final BillRepository repository;

  GetBills(this.repository);

  @override
  Future<Either<Failure, List<Bill>>> call(GetBillsParams params) {
    return repository.getBills(params.chatRoomIds);
  }
}

class GetBillsParams extends Equatable {
  final List<String> chatRoomIds;

  const GetBillsParams({required this.chatRoomIds});

  @override
  List<Object> get props => [chatRoomIds];
}
