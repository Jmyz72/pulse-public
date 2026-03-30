import '../entities/bill.dart';
import '../repositories/bill_repository.dart';

class WatchBills {
  final BillRepository repository;

  WatchBills(this.repository);

  Stream<List<Bill>> call(List<String> chatRoomIds) {
    return repository.watchBills(chatRoomIds);
  }
}
