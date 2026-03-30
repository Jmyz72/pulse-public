part of 'expense_bloc.dart';

enum ExpenseLoadStatus { initial, loading, loaded, error }

enum ExpenseDetailStatus { initial, loading, loaded, error }

enum ExpenseDetailAction { none, submittingPaymentProof }

class ExpenseState extends Equatable {
  final String? currentUserId;
  final Map<String, String> friendDisplayNamesById;
  final ExpenseLoadStatus status;
  final ExpenseDetailStatus detailStatus;
  final ExpenseDetailAction detailAction;
  final List<Expense> expenses;
  final Expense? selectedExpense;
  final String? errorMessage;

  const ExpenseState({
    this.currentUserId,
    this.friendDisplayNamesById = const {},
    this.status = ExpenseLoadStatus.initial,
    this.detailStatus = ExpenseDetailStatus.initial,
    this.detailAction = ExpenseDetailAction.none,
    this.expenses = const [],
    this.selectedExpense,
    this.errorMessage,
  });

  double get totalExpenses => expenses.fold(0, (sum, e) => sum + e.totalAmount);

  /// Get pending expenses
  List<Expense> get pendingExpenses =>
      expenses.where((e) => e.status == ExpenseStatus.pending).toList();

  /// Get settled expenses
  List<Expense> get settledExpenses =>
      expenses.where((e) => e.status == ExpenseStatus.settled).toList();

  /// Group expenses by chat room
  Map<String?, List<Expense>> get expensesByChatRoom {
    final map = <String?, List<Expense>>{};
    for (final expense in expenses) {
      final key = expense.chatRoomId;
      if (!map.containsKey(key)) {
        map[key] = [];
      }
      map[key]!.add(expense);
    }
    return map;
  }

  /// Group a pre-filtered expense list by chat room
  Map<String?, List<Expense>> expensesByChatRoomFiltered(
    List<Expense> filtered,
  ) {
    final map = <String?, List<Expense>>{};
    for (final expense in filtered) {
      (map[expense.chatRoomId] ??= []).add(expense);
    }
    return map;
  }

  /// Get total amount owed to user (as expense owner)
  double totalOwedToUser(String userId) {
    return expenses
        .where((e) => e.ownerId == userId && e.status == ExpenseStatus.pending)
        .fold(0.0, (sum, e) {
          final unpaidSplits = e.splits.where(
            (s) => !s.isPaid && s.userId != userId,
          );
          return sum + unpaidSplits.fold(0.0, (s, split) => s + split.amount);
        });
  }

  /// Get total amount user owes (as expense participant)
  double totalUserOwes(String userId) {
    return expenses
        .where((e) => e.ownerId != userId && e.status == ExpenseStatus.pending)
        .fold(0.0, (sum, e) {
          final userSplit = e.splits.where(
            (s) => s.userId == userId && !s.isPaid,
          );
          return sum + userSplit.fold(0.0, (s, split) => s + split.amount);
        });
  }

  ExpenseState copyWith({
    String? currentUserId,
    Map<String, String>? friendDisplayNamesById,
    ExpenseLoadStatus? status,
    ExpenseDetailStatus? detailStatus,
    ExpenseDetailAction? detailAction,
    List<Expense>? expenses,
    Expense? selectedExpense,
    bool clearSelectedExpense = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return ExpenseState(
      currentUserId: currentUserId ?? this.currentUserId,
      friendDisplayNamesById:
          friendDisplayNamesById ?? this.friendDisplayNamesById,
      status: status ?? this.status,
      detailStatus: detailStatus ?? this.detailStatus,
      detailAction: detailAction ?? this.detailAction,
      expenses: expenses ?? this.expenses,
      selectedExpense: clearSelectedExpense
          ? null
          : (selectedExpense ?? this.selectedExpense),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    currentUserId,
    friendDisplayNamesById,
    status,
    detailStatus,
    detailAction,
    expenses,
    selectedExpense,
    errorMessage,
  ];
}
