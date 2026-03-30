import 'package:equatable/equatable.dart';

class BillSummary extends Equatable {
  final double totalOwed;
  final double totalPaid;
  final double yourOwed;
  final double yourPaid;
  final int pendingCount;
  final int overdueCount;
  final int paidCount;

  const BillSummary({
    required this.totalOwed,
    required this.totalPaid,
    required this.yourOwed,
    required this.yourPaid,
    required this.pendingCount,
    required this.overdueCount,
    required this.paidCount,
  });

  double get totalAmount => totalOwed + totalPaid;
  double get yourTotal => yourOwed + yourPaid;

  @override
  List<Object?> get props => [
        totalOwed,
        totalPaid,
        yourOwed,
        yourPaid,
        pendingCount,
        overdueCount,
        paidCount,
      ];
}
