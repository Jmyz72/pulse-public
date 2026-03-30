import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/expense.dart';
import '../entities/expense_item.dart';
import '../entities/expense_split.dart';
import '../entities/expense_submission.dart';

class ExpenseSubmissionService {
  Either<Failure, Expense> createExpense(ExpenseSubmission submission) {
    final validation = _validate(submission);
    if (validation != null) {
      return Left(validation);
    }

    final now = DateTime.now();

    return Right(
      Expense(
        id: '',
        ownerId: submission.currentUserId,
        chatRoomId: submission.chatRoomId,
        ownerPaymentIdentity: _normalizedPaymentIdentity(
          submission.ownerPaymentIdentity,
        ),
        title: submission.title.trim(),
        description: _normalizedDescription(submission.description),
        totalAmount: _total(submission),
        date: now,
        status: ExpenseStatus.pending,
        type: submission.expenseType,
        items: List<ExpenseItem>.from(submission.items),
        taxPercent: submission.taxPercent,
        serviceChargePercent: submission.serviceChargePercent,
        discountPercent: submission.discountPercent,
        splits: _buildSplits(submission, now),
      ),
    );
  }

  Either<Failure, Expense> updateExpense({
    required Expense existingExpense,
    required ExpenseSubmission submission,
  }) {
    final validation = _validate(
      submission,
      fallbackChatRoomId: existingExpense.chatRoomId,
    );
    if (validation != null) {
      return Left(validation);
    }

    final now = DateTime.now();

    return Right(
      existingExpense.copyWith(
        title: submission.title.trim(),
        description: _normalizedDescription(submission.description),
        clearDescription: submission.description.trim().isEmpty,
        ownerPaymentIdentity: _normalizedPaymentIdentity(
          submission.ownerPaymentIdentity,
        ),
        clearOwnerPaymentIdentity:
            _normalizedPaymentIdentity(submission.ownerPaymentIdentity) == null,
        totalAmount: _total(submission),
        items: List<ExpenseItem>.from(submission.items),
        taxPercent: submission.taxPercent,
        clearTaxPercent: submission.taxPercent == null,
        serviceChargePercent: submission.serviceChargePercent,
        clearServiceChargePercent: submission.serviceChargePercent == null,
        discountPercent: submission.discountPercent,
        clearDiscountPercent: submission.discountPercent == null,
        splits: _buildSplits(submission, now),
        type: submission.expenseType,
      ),
    );
  }

  Failure? _validate(
    ExpenseSubmission submission, {
    String? fallbackChatRoomId,
  }) {
    if (submission.title.trim().isEmpty) {
      return const InvalidInputFailure(message: 'Please enter a title');
    }
    if (submission.currentUserId.isEmpty) {
      return const InvalidInputFailure(message: 'Missing current user');
    }
    if (submission.requiresChatRoom &&
        (submission.chatRoomId ?? fallbackChatRoomId ?? '').isEmpty) {
      return const InvalidInputFailure(message: 'Please select a chat room');
    }
    if (submission.participants.length < 2) {
      return const InvalidInputFailure(
        message: 'Please select at least 2 members',
      );
    }
    if (submission.isCustomSplit) {
      if (submission.items.isEmpty) {
        return const InvalidInputFailure(
          message: 'Please add at least one item',
        );
      }
      for (final item in submission.items) {
        if (item.price < 0) {
          return const InvalidInputFailure(
            message: 'Item price cannot be negative',
          );
        }
        if (item.quantity <= 0) {
          return const InvalidInputFailure(
            message: 'Item quantity must be positive',
          );
        }
      }
    } else {
      final manualAmount = submission.manualAmount;
      if (manualAmount == null) {
        return const InvalidInputFailure(
          message: 'Please enter a valid amount',
        );
      }
      if (manualAmount <= 0) {
        return const InvalidInputFailure(
          message: 'Amount must be greater than 0',
        );
      }
      if (manualAmount > 999999) {
        return const InvalidInputFailure(message: 'Amount is too large');
      }
    }

    for (final entry in [
      ('Tax', submission.taxPercent),
      ('Service charge', submission.serviceChargePercent),
      ('Discount', submission.discountPercent),
    ]) {
      final value = entry.$2;
      if (value != null && (value < 0 || value > 100)) {
        return InvalidInputFailure(
          message: '${entry.$1} percentage must be between 0 and 100',
        );
      }
    }

    return null;
  }

  List<ExpenseSplit> _buildSplits(ExpenseSubmission submission, DateTime now) {
    if (submission.isCustomSplit) {
      return submission.participants
          .map(
            (participant) => ExpenseSplit(
              userId: participant.id,
              userName: participant.name,
              amount: 0,
              paymentStatus: ExpensePaymentStatus.unpaid,
              hasSelectedItems: false,
            ),
          )
          .toList();
    }

    final perPerson = _total(submission) / submission.participants.length;
    return submission.participants
        .map(
          (participant) => ExpenseSplit(
            userId: participant.id,
            userName: participant.name,
            amount: perPerson,
            paymentStatus: participant.id == submission.currentUserId
                ? ExpensePaymentStatus.paid
                : ExpensePaymentStatus.unpaid,
            paidAt: participant.id == submission.currentUserId ? now : null,
          ),
        )
        .toList();
  }

  double _total(ExpenseSubmission submission) {
    final subtotal = submission.isCustomSplit
        ? submission.items.fold<double>(0, (sum, item) => sum + item.subtotal)
        : (submission.manualAmount ?? 0);
    final tax = submission.taxPercent == null
        ? 0.0
        : subtotal * (submission.taxPercent! / 100);
    final serviceCharge = submission.serviceChargePercent == null
        ? 0.0
        : subtotal * (submission.serviceChargePercent! / 100);
    final discount = submission.discountPercent == null
        ? 0.0
        : subtotal * (submission.discountPercent! / 100);
    return subtotal + tax + serviceCharge - discount;
  }

  String? _normalizedDescription(String description) {
    final trimmed = description.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _normalizedPaymentIdentity(String? paymentIdentity) {
    final trimmed = paymentIdentity?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
