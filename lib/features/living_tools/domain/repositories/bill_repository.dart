import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/bill.dart';
import '../entities/bill_summary.dart';

abstract class BillRepository {
  Future<Either<Failure, List<Bill>>> getBills(List<String> chatRoomIds);
  Stream<List<Bill>> watchBills(List<String> chatRoomIds);
  Future<Either<Failure, Bill>> getBillById(String id);
  Future<Either<Failure, Bill>> createBill(Bill bill);
  Future<Either<Failure, Bill>> updateBill(Bill bill);
  Future<Either<Failure, void>> deleteBill(String id);
  Future<Either<Failure, void>> markBillAsPaid(String billId, String memberId);
  Future<Either<Failure, void>> nudgeMember(String billId, String memberId);
  Future<Either<Failure, BillSummary>> getBillsSummary(String userId, List<String> chatRoomIds);
  Future<Either<Failure, List<Bill>>> getBillsByChatRoom(String chatRoomId);
}
