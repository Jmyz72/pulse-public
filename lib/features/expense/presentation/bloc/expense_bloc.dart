import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/bloc_event_transformers.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_submission.dart';
import '../../domain/usecases/create_adhoc_expense.dart';
import '../../domain/usecases/create_expense.dart';
import '../../domain/usecases/delete_expense.dart';
import '../../domain/usecases/get_expense_by_id.dart';
import '../../domain/usecases/get_expenses.dart';
import '../../domain/usecases/approve_payment_proof.dart';
import '../../domain/usecases/refresh_expense_owner_payment_identity.dart';
import '../../domain/usecases/mark_split_paid.dart';
import '../../domain/usecases/reject_payment_proof.dart';
import '../../domain/usecases/select_items.dart';
import '../../domain/usecases/submit_payment_proof.dart';
import '../../domain/usecases/update_expense.dart';

part 'expense_event.dart';
part 'expense_state.dart';

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final GetExpenses getExpenses;
  final GetExpenseById getExpenseById;
  final CreateExpense createExpense;
  final CreateAdHocExpense createAdHocExpense;
  final UpdateExpense updateExpense;
  final DeleteExpense deleteExpense;
  final SelectItems selectItems;
  final MarkSplitPaid markSplitPaid;
  final SubmitPaymentProof submitPaymentProof;
  final ApprovePaymentProof approvePaymentProof;
  final RejectPaymentProof rejectPaymentProof;
  final RefreshExpenseOwnerPaymentIdentity refreshExpenseOwnerPaymentIdentity;

  ExpenseBloc({
    required this.getExpenses,
    required this.getExpenseById,
    required this.createExpense,
    required this.createAdHocExpense,
    required this.updateExpense,
    required this.deleteExpense,
    required this.selectItems,
    required this.markSplitPaid,
    required this.submitPaymentProof,
    required this.approvePaymentProof,
    required this.rejectPaymentProof,
    required this.refreshExpenseOwnerPaymentIdentity,
    required String currentUserId,
  }) : super(ExpenseState(currentUserId: currentUserId)) {
    on<ExpenseLoadRequested>(_onLoadRequested);
    on<ExpenseByIdRequested>(_onByIdRequested);
    on<ExpenseCreateRequested>(_onCreateRequested, transformer: droppable());
    on<AdHocExpenseCreateRequested>(
      _onAdHocCreateRequested,
      transformer: droppable(),
    );
    on<ExpenseUpdateRequested>(_onUpdateRequested, transformer: droppable());
    on<ExpenseDeleteRequested>(_onDeleteRequested, transformer: droppable());
    on<ExpenseItemsSelectionRequested>(
      _onItemsSelectionRequested,
      transformer: droppable(),
    );
    on<ExpenseSplitPaidToggled>(_onSplitPaidToggled, transformer: droppable());
    on<ExpensePaymentProofSubmissionRequested>(
      _onPaymentProofSubmissionRequested,
      transformer: droppable(),
    );
    on<ExpensePaymentProofApproved>(
      _onPaymentProofApproved,
      transformer: droppable(),
    );
    on<ExpensePaymentProofRejected>(
      _onPaymentProofRejected,
      transformer: droppable(),
    );
    on<ExpenseOwnerPaymentIdentityRefreshRequested>(
      _onOwnerPaymentIdentityRefreshRequested,
      transformer: droppable(),
    );
    on<ExpenseSelected>(_onExpenseSelected);
    on<ExpenseCleared>(_onExpenseCleared);
    on<ExpenseCurrentUserUpdated>(_onCurrentUserUpdated);
    on<ExpenseFriendDisplayNamesUpdated>(_onFriendDisplayNamesUpdated);
  }

  Future<void> _onLoadRequested(
    ExpenseLoadRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(state.copyWith(status: ExpenseLoadStatus.loading));

    final result = await getExpenses(
      GetExpensesParams(chatRoomIds: event.chatRoomIds),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ExpenseLoadStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (expenses) => emit(
        state.copyWith(status: ExpenseLoadStatus.loaded, expenses: expenses),
      ),
    );
  }

  Future<void> _onByIdRequested(
    ExpenseByIdRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(state.copyWith(detailStatus: ExpenseDetailStatus.loading));

    final result = await getExpenseById(GetExpenseByIdParams(id: event.id));

    result.fold(
      (failure) => emit(
        state.copyWith(
          detailStatus: ExpenseDetailStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (expense) => emit(
        state.copyWith(
          detailStatus: ExpenseDetailStatus.loaded,
          selectedExpense: expense,
        ),
      ),
    );
  }

  Future<void> _onCreateRequested(
    ExpenseCreateRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(state.copyWith(status: ExpenseLoadStatus.loading));

    final result = await createExpense(
      CreateExpenseParams(submission: event.submission),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ExpenseLoadStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (expense) {
        final updatedExpenses = [expense, ...state.expenses];
        emit(
          state.copyWith(
            status: ExpenseLoadStatus.loaded,
            expenses: updatedExpenses,
            selectedExpense: expense,
          ),
        );
      },
    );
  }

  Future<void> _onAdHocCreateRequested(
    AdHocExpenseCreateRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(state.copyWith(status: ExpenseLoadStatus.loading));

    final result = await createAdHocExpense(
      CreateAdHocExpenseParams(
        masterExpense: event.masterExpense,
        participantIds: event.participantIds,
        chatRoomIdsByParticipant: event.chatRoomIdsByParticipant,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ExpenseLoadStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (expense) {
        final updatedExpenses = [expense, ...state.expenses];
        emit(
          state.copyWith(
            status: ExpenseLoadStatus.loaded,
            expenses: updatedExpenses,
          ),
        );
      },
    );
  }

  Future<void> _onUpdateRequested(
    ExpenseUpdateRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(state.copyWith(status: ExpenseLoadStatus.loading));

    final result = await updateExpense(
      UpdateExpenseParams(
        existingExpense: event.existingExpense,
        submission: event.submission,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ExpenseLoadStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (expense) {
        final updatedExpenses = state.expenses.map((e) {
          return e.id == expense.id ? expense : e;
        }).toList();
        emit(
          state.copyWith(
            status: ExpenseLoadStatus.loaded,
            expenses: updatedExpenses,
            selectedExpense: state.selectedExpense?.id == expense.id
                ? expense
                : state.selectedExpense,
          ),
        );
      },
    );
  }

  Future<void> _onDeleteRequested(
    ExpenseDeleteRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(state.copyWith(status: ExpenseLoadStatus.loading));

    final result = await deleteExpense(DeleteExpenseParams(id: event.id));

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ExpenseLoadStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (_) {
        final updatedExpenses = state.expenses
            .where((e) => e.id != event.id)
            .toList();
        final shouldClearSelected = state.selectedExpense?.id == event.id;
        emit(
          state.copyWith(
            status: ExpenseLoadStatus.loaded,
            expenses: updatedExpenses,
            clearSelectedExpense: shouldClearSelected,
          ),
        );
      },
    );
  }

  Future<void> _onItemsSelectionRequested(
    ExpenseItemsSelectionRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    // Backup current state for rollback on failure
    final backupExpense = state.selectedExpense;
    final backupExpenses = List<Expense>.from(state.expenses);

    emit(state.copyWith(detailStatus: ExpenseDetailStatus.loading));

    final result = await selectItems(
      SelectItemsParams(
        expenseId: event.expenseId,
        userId: event.userId,
        itemIds: event.itemIds,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          detailStatus: ExpenseDetailStatus.error,
          errorMessage: failure.message,
          // Rollback to previous state
          expenses: backupExpenses,
          selectedExpense: backupExpense,
        ),
      ),
      (expense) {
        final updatedExpenses = state.expenses.map((e) {
          return e.id == expense.id ? expense : e;
        }).toList();
        emit(
          state.copyWith(
            detailStatus: ExpenseDetailStatus.loaded,
            expenses: updatedExpenses,
            selectedExpense: expense,
          ),
        );
      },
    );
  }

  Future<void> _onSplitPaidToggled(
    ExpenseSplitPaidToggled event,
    Emitter<ExpenseState> emit,
  ) async {
    // Backup current state for rollback on failure
    final backupExpense = state.selectedExpense;
    final backupExpenses = List<Expense>.from(state.expenses);

    emit(state.copyWith(detailStatus: ExpenseDetailStatus.loading));

    final result = await markSplitPaid(
      MarkSplitPaidParams(
        expenseId: event.expenseId,
        userId: event.userId,
        isPaid: event.isPaid,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          detailStatus: ExpenseDetailStatus.error,
          errorMessage: failure.message,
          // Rollback to previous state
          expenses: backupExpenses,
          selectedExpense: backupExpense,
        ),
      ),
      (expense) {
        final updatedExpenses = state.expenses.map((e) {
          return e.id == expense.id ? expense : e;
        }).toList();
        emit(
          state.copyWith(
            detailStatus: ExpenseDetailStatus.loaded,
            expenses: updatedExpenses,
            selectedExpense: expense,
          ),
        );
      },
    );
  }

  Future<void> _onPaymentProofSubmissionRequested(
    ExpensePaymentProofSubmissionRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    final backupExpense = state.selectedExpense;
    final backupExpenses = List<Expense>.from(state.expenses);

    emit(
      state.copyWith(
        detailAction: ExpenseDetailAction.submittingPaymentProof,
        clearErrorMessage: true,
      ),
    );

    final result = await submitPaymentProof(
      SubmitPaymentProofParams(
        expenseId: event.expenseId,
        userId: event.userId,
        imagePath: event.imagePath,
      ),
    );

    _emitExpenseMutationResult(
      emit,
      result,
      backupExpense: backupExpense,
      backupExpenses: backupExpenses,
    );
  }

  Future<void> _onPaymentProofApproved(
    ExpensePaymentProofApproved event,
    Emitter<ExpenseState> emit,
  ) async {
    final backupExpense = state.selectedExpense;
    final backupExpenses = List<Expense>.from(state.expenses);

    emit(state.copyWith(detailStatus: ExpenseDetailStatus.loading));

    final result = await approvePaymentProof(
      ApprovePaymentProofParams(
        expenseId: event.expenseId,
        userId: event.userId,
        reviewerId: event.reviewerId,
      ),
    );

    _emitExpenseMutationResult(
      emit,
      result,
      backupExpense: backupExpense,
      backupExpenses: backupExpenses,
    );
  }

  Future<void> _onPaymentProofRejected(
    ExpensePaymentProofRejected event,
    Emitter<ExpenseState> emit,
  ) async {
    final backupExpense = state.selectedExpense;
    final backupExpenses = List<Expense>.from(state.expenses);

    emit(state.copyWith(detailStatus: ExpenseDetailStatus.loading));

    final result = await rejectPaymentProof(
      RejectPaymentProofParams(
        expenseId: event.expenseId,
        userId: event.userId,
        reviewerId: event.reviewerId,
        reason: event.reason,
      ),
    );

    _emitExpenseMutationResult(
      emit,
      result,
      backupExpense: backupExpense,
      backupExpenses: backupExpenses,
    );
  }

  Future<void> _onOwnerPaymentIdentityRefreshRequested(
    ExpenseOwnerPaymentIdentityRefreshRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    final backupExpense = state.selectedExpense;
    final backupExpenses = List<Expense>.from(state.expenses);

    emit(state.copyWith(detailStatus: ExpenseDetailStatus.loading));

    final result = await refreshExpenseOwnerPaymentIdentity(
      RefreshExpenseOwnerPaymentIdentityParams(
        expenseId: event.expenseId,
        ownerId: event.ownerId,
        paymentIdentity: event.paymentIdentity,
      ),
    );

    _emitExpenseMutationResult(
      emit,
      result,
      backupExpense: backupExpense,
      backupExpenses: backupExpenses,
    );
  }

  void _emitExpenseMutationResult(
    Emitter<ExpenseState> emit,
    Either<Failure, Expense> result, {
    required Expense? backupExpense,
    required List<Expense> backupExpenses,
  }) {
    result.fold(
      (failure) => emit(
        state.copyWith(
          detailStatus: ExpenseDetailStatus.error,
          detailAction: ExpenseDetailAction.none,
          errorMessage: failure.message,
          expenses: backupExpenses,
          selectedExpense: backupExpense,
        ),
      ),
      (expense) {
        final updatedExpenses = state.expenses.map((e) {
          return e.id == expense.id ? expense : e;
        }).toList();
        emit(
          state.copyWith(
            detailStatus: ExpenseDetailStatus.loaded,
            detailAction: ExpenseDetailAction.none,
            expenses: updatedExpenses,
            selectedExpense: expense,
          ),
        );
      },
    );
  }

  void _onExpenseSelected(ExpenseSelected event, Emitter<ExpenseState> emit) {
    emit(
      state.copyWith(
        selectedExpense: event.expense,
        detailStatus: ExpenseDetailStatus.loaded,
      ),
    );
  }

  void _onExpenseCleared(ExpenseCleared event, Emitter<ExpenseState> emit) {
    emit(
      state.copyWith(
        clearSelectedExpense: true,
        detailStatus: ExpenseDetailStatus.initial,
      ),
    );
  }

  void _onCurrentUserUpdated(
    ExpenseCurrentUserUpdated event,
    Emitter<ExpenseState> emit,
  ) {
    if (event.userId == state.currentUserId) return;
    emit(state.copyWith(currentUserId: event.userId));
  }

  void _onFriendDisplayNamesUpdated(
    ExpenseFriendDisplayNamesUpdated event,
    Emitter<ExpenseState> emit,
  ) {
    if (event.friendDisplayNamesById == state.friendDisplayNamesById) return;
    emit(state.copyWith(friendDisplayNamesById: event.friendDisplayNamesById));
  }
}
