part of 'expense_bloc.dart';

abstract class ExpenseEvent extends Equatable {
  const ExpenseEvent();

  @override
  List<Object?> get props => [];
}

class ExpenseLoadRequested extends ExpenseEvent {
  final List<String> chatRoomIds;

  const ExpenseLoadRequested({required this.chatRoomIds});

  @override
  List<Object> get props => [chatRoomIds];
}

class ExpenseByIdRequested extends ExpenseEvent {
  final String id;

  const ExpenseByIdRequested({required this.id});

  @override
  List<Object> get props => [id];
}

class ExpenseCreateRequested extends ExpenseEvent {
  final ExpenseSubmission submission;

  const ExpenseCreateRequested({required this.submission});

  @override
  List<Object> get props => [submission];
}

class AdHocExpenseCreateRequested extends ExpenseEvent {
  final Expense masterExpense;
  final List<String> participantIds;
  final Map<String, String> chatRoomIdsByParticipant;

  const AdHocExpenseCreateRequested({
    required this.masterExpense,
    required this.participantIds,
    required this.chatRoomIdsByParticipant,
  });

  @override
  List<Object> get props => [
    masterExpense,
    participantIds,
    chatRoomIdsByParticipant,
  ];
}

class ExpenseUpdateRequested extends ExpenseEvent {
  final Expense existingExpense;
  final ExpenseSubmission submission;

  const ExpenseUpdateRequested({
    required this.existingExpense,
    required this.submission,
  });

  @override
  List<Object> get props => [existingExpense, submission];
}

class ExpenseDeleteRequested extends ExpenseEvent {
  final String id;

  const ExpenseDeleteRequested({required this.id});

  @override
  List<Object> get props => [id];
}

class ExpenseItemsSelectionRequested extends ExpenseEvent {
  final String expenseId;
  final String userId;
  final List<String> itemIds;

  const ExpenseItemsSelectionRequested({
    required this.expenseId,
    required this.userId,
    required this.itemIds,
  });

  @override
  List<Object> get props => [expenseId, userId, itemIds];
}

class ExpenseSplitPaidToggled extends ExpenseEvent {
  final String expenseId;
  final String userId;
  final bool isPaid;

  const ExpenseSplitPaidToggled({
    required this.expenseId,
    required this.userId,
    required this.isPaid,
  });

  @override
  List<Object> get props => [expenseId, userId, isPaid];
}

class ExpensePaymentProofSubmissionRequested extends ExpenseEvent {
  final String expenseId;
  final String userId;
  final String imagePath;

  const ExpensePaymentProofSubmissionRequested({
    required this.expenseId,
    required this.userId,
    required this.imagePath,
  });

  @override
  List<Object> get props => [expenseId, userId, imagePath];
}

class ExpensePaymentProofApproved extends ExpenseEvent {
  final String expenseId;
  final String userId;
  final String reviewerId;

  const ExpensePaymentProofApproved({
    required this.expenseId,
    required this.userId,
    required this.reviewerId,
  });

  @override
  List<Object> get props => [expenseId, userId, reviewerId];
}

class ExpensePaymentProofRejected extends ExpenseEvent {
  final String expenseId;
  final String userId;
  final String reviewerId;
  final String reason;

  const ExpensePaymentProofRejected({
    required this.expenseId,
    required this.userId,
    required this.reviewerId,
    required this.reason,
  });

  @override
  List<Object> get props => [expenseId, userId, reviewerId, reason];
}

class ExpenseOwnerPaymentIdentityRefreshRequested extends ExpenseEvent {
  final String expenseId;
  final String ownerId;
  final String paymentIdentity;

  const ExpenseOwnerPaymentIdentityRefreshRequested({
    required this.expenseId,
    required this.ownerId,
    required this.paymentIdentity,
  });

  @override
  List<Object> get props => [expenseId, ownerId, paymentIdentity];
}

class ExpenseSelected extends ExpenseEvent {
  final Expense expense;

  const ExpenseSelected({required this.expense});

  @override
  List<Object> get props => [expense];
}

class ExpenseCleared extends ExpenseEvent {
  const ExpenseCleared();
}

class ExpenseCurrentUserUpdated extends ExpenseEvent {
  final String userId;

  const ExpenseCurrentUserUpdated({required this.userId});

  @override
  List<Object> get props => [userId];
}

class ExpenseFriendDisplayNamesUpdated extends ExpenseEvent {
  final Map<String, String> friendDisplayNamesById;

  const ExpenseFriendDisplayNamesUpdated({
    required this.friendDisplayNamesById,
  });

  @override
  List<Object> get props => [friendDisplayNamesById];
}
