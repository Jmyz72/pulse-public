import '../../../../core/error/exceptions.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_item.dart';

class ExpenseValidator {
  ExpenseValidator._();

  /// Validates core expense fields: title, amount, ownerId, splits.
  static void validateExpense(Expense expense) {
    if (expense.title.isEmpty) {
      throw const ServerException(message: 'Expense title cannot be empty');
    }
    if (expense.totalAmount < 0) {
      throw const ServerException(message: 'Total amount cannot be negative');
    }
    if (expense.ownerId.isEmpty) {
      throw const ServerException(message: 'Owner ID cannot be empty');
    }
    if (expense.splits.isEmpty) {
      throw const ServerException(message: 'Expense must have at least one split');
    }
  }

  /// Validates item list and percentage adjustments.
  static void validateItems(
    List<ExpenseItem> items, {
    double? taxPercent,
    double? serviceChargePercent,
    double? discountPercent,
  }) {
    if (items.isEmpty) {
      throw const ServerException(message: 'Items list cannot be empty');
    }
    if (items.any((item) => item.price < 0)) {
      throw const ServerException(message: 'Item price cannot be negative');
    }
    if (items.any((item) => item.quantity <= 0)) {
      throw const ServerException(message: 'Item quantity must be positive');
    }
    validatePercentage(taxPercent, 'Tax');
    validatePercentage(serviceChargePercent, 'Service charge');
    validatePercentage(discountPercent, 'Discount');
  }

  /// Validates a percentage value is between 0 and 100 (null is allowed).
  static void validatePercentage(double? value, String label) {
    if (value != null && (value < 0 || value > 100)) {
      throw ServerException(message: '$label percentage must be between 0 and 100');
    }
  }

  /// Validates that required IDs are non-empty.
  static void validateRequiredIds({
    required String expenseId,
    required String userId,
  }) {
    if (expenseId.isEmpty) {
      throw const ServerException(message: 'Expense ID cannot be empty');
    }
    if (userId.isEmpty) {
      throw const ServerException(message: 'User ID cannot be empty');
    }
  }
}
