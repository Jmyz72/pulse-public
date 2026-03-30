part of 'living_tools_bloc.dart';

enum LivingToolsStatus { initial, loading, loaded, error }

class LivingToolsState extends Equatable {
  final LivingToolsStatus status;
  final List<Bill> bills;
  final BillSummary? summary;
  final int selectedTab;
  final String? errorMessage;

  const LivingToolsState({
    this.status = LivingToolsStatus.initial,
    this.bills = const [],
    this.summary,
    this.selectedTab = 0,
    this.errorMessage,
  });

  List<Bill> get allBills => bills;

  List<Bill> get pendingBills =>
      bills.where((b) => b.status != BillStatus.paid).toList();

  List<Bill> get paidBills =>
      bills.where((b) => b.status == BillStatus.paid).toList();

  List<Bill> get overdueBills =>
      bills.where((b) => b.status == BillStatus.overdue).toList();

  List<Bill> get filteredBills {
    switch (selectedTab) {
      case 1:
        return pendingBills;
      case 2:
        return paidBills;
      default:
        return allBills;
    }
  }

  LivingToolsState copyWith({
    LivingToolsStatus? status,
    List<Bill>? bills,
    BillSummary? summary,
    int? selectedTab,
    String? errorMessage,
  }) {
    return LivingToolsState(
      status: status ?? this.status,
      bills: bills ?? this.bills,
      summary: summary ?? this.summary,
      selectedTab: selectedTab ?? this.selectedTab,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, bills, summary, selectedTab, errorMessage];
}
