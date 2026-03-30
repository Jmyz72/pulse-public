import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_item.dart';
import '../../domain/entities/expense_split.dart';
import '../bloc/expense_bloc.dart';
import '../widgets/glass_bottom_bar.dart';

class ItemSelectionScreen extends StatefulWidget {
  final String expenseId;

  const ItemSelectionScreen({super.key, required this.expenseId});

  @override
  State<ItemSelectionScreen> createState() => _ItemSelectionScreenState();
}

class _ItemSelectionScreenState extends State<ItemSelectionScreen> {
  final Set<String> _selectedItemIds = {};
  bool _initialized = false;
  bool _isSubmitting = false;
  String? _lastSyncedSelectionSignature;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExpenseBloc, ExpenseState>(
      listener: (context, state) {
        if (state.detailStatus == ExpenseDetailStatus.loaded) {
          if (_isSubmitting) {
            _isSubmitting = false;
            Navigator.pop(context);
          }
        }

        if (state.detailStatus == ExpenseDetailStatus.error &&
            state.errorMessage != null) {
          _isSubmitting = false;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      builder: (context, state) {
        final expense = _resolveExpense(state);
        final currentUserId =
            context.read<AuthBloc>().state.user?.id ??
            state.currentUserId ??
            '';

        if (expense == null) {
          throw Exception('Expense not found');
        }

        _syncSelectedItemsFromExpense(
          expense: expense,
          currentUserId: currentUserId,
        );

        return _buildContent(context, expense, state);
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    Expense expense,
    ExpenseState state,
  ) {
    final theme = Theme.of(context);
    final currentUserId =
        context.read<AuthBloc>().state.user?.id ?? state.currentUserId ?? '';
    final currentUserSplit = _getCurrentUserSplit(
      expense: expense,
      currentUserId: currentUserId,
    );
    final isReadOnly =
        expense.status == ExpenseStatus.settled ||
        currentUserSplit?.locksItemSelection == true;
    final unlockedItems = expense.items
        .where((item) => !_isItemLocked(expense, item))
        .toList();
    final lockedItems = expense.items
        .where((item) => _isItemLocked(expense, item))
        .toList();

    return Scaffold(
      appBar: GlassAppBar(
        title: 'Select Your Items',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!isReadOnly)
            TextButton(
              onPressed: state.detailStatus == ExpenseDetailStatus.loading
                  ? null
                  : () => _saveSelection(context, currentUserId),
              child: state.detailStatus == ExpenseDetailStatus.loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(color: AppColors.primary),
                    ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Header with expense info
          GlassContainer(
            borderRadius: 0,
            backgroundOpacity: 0.08,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap items that you ordered. Cost will be split among everyone who selects the same item.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (isReadOnly) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      currentUserSplit?.isPaid == true
                          ? 'Your payment is already recorded. Item selection is locked.'
                          : currentUserSplit?.needsReview == true
                          ? 'Your payment proof is waiting for owner review. Item selection is locked.'
                          : 'This expense is settled. Item selection is locked.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Items list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final item in unlockedItems)
                  _buildItemCard(
                    context,
                    theme,
                    item,
                    currentUserId,
                    expense,
                    isReadOnly,
                  ),
                if (lockedItems.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildSectionLabel(
                    theme: theme,
                    title: 'Locked Items',
                    subtitle:
                        'Payment is under review or already recorded for these items.',
                    color: AppColors.warning,
                  ),
                  const SizedBox(height: 12),
                ],
                for (final item in lockedItems)
                  _buildItemCard(
                    context,
                    theme,
                    item,
                    currentUserId,
                    expense,
                    isReadOnly,
                  ),
              ],
            ),
          ),

          // Bottom summary
          _buildBottomSummary(
            context,
            theme,
            expense,
            currentUserId,
            isReadOnly,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    ThemeData theme,
    ExpenseItem item,
    String currentUserId,
    Expense expense,
    bool isReadOnly,
  ) {
    final isSelected = _selectedItemIds.contains(item.id);
    final otherAssignees = item.assignedUserIds
        .where((id) => id != currentUserId)
        .toList();
    final totalAssignees = otherAssignees.length + (isSelected ? 1 : 0);
    final isLocked = _isItemLocked(expense, item);
    final canEdit = !isReadOnly && !isLocked;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        borderRadius: 24,
        borderColor: isSelected
            ? (canEdit ? AppColors.primary : AppColors.warning)
            : null,
        borderOpacity: isSelected ? 0.8 : 0.4,
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: canEdit ? () => _toggleItem(item.id) : null,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Selection indicator
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? (canEdit ? AppColors.primary : AppColors.warning)
                            : AppColors.glassBackground,
                        border: Border.all(
                          color: isSelected
                              ? (canEdit
                                    ? AppColors.primary
                                    : AppColors.warning)
                              : AppColors.textTertiary,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 18,
                              color: AppColors.background,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),

                    // Quantity badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${item.quantity}x',
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Item name
                    Expanded(
                      child: Text(
                        item.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),

                    // Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'RM ${item.subtotal.toStringAsFixed(2)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        if (item.quantity > 1)
                          Text(
                            'RM ${item.price.toStringAsFixed(2)} each',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                    if (isLocked) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Locked',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // Assignees info
                if (totalAssignees > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.glassBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getAssigneesText(totalAssignees, isSelected),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Text(
                          'RM ${(item.subtotal / totalAssignees).toStringAsFixed(2)}/person',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (isLocked) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Selection locked because payment is under review or already recorded.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSummary(
    BuildContext context,
    ThemeData theme,
    Expense expense,
    String currentUserId,
    bool isReadOnly,
  ) {
    final selectedAmount = _calculateUserTotal(expense, currentUserId);

    return GlassBottomBar(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Items selected',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${_selectedItemIds.length} of ${expense.items.length}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your estimated total',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'RM ${selectedAmount.toStringAsFixed(2)}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          if (expense.taxPercent != null ||
              expense.serviceChargePercent != null ||
              expense.discountPercent != null) ...[
            const SizedBox(height: 4),
            Text(
              '* Including adjustments (tax, service, discount)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: IgnorePointer(
              ignoring: isReadOnly,
              child: Opacity(
                opacity: isReadOnly ? 0.6 : 1,
                child: GlassButton(
                  text: isReadOnly ? 'Selection Locked' : 'Confirm Selection',
                  isPrimary: true,
                  onPressed: () {
                    if (_selectedItemIds.isEmpty || _isSubmitting) return;
                    _saveSelection(context, currentUserId);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleItem(String itemId) {
    setState(() {
      if (_selectedItemIds.contains(itemId)) {
        _selectedItemIds.remove(itemId);
      } else {
        _selectedItemIds.add(itemId);
      }
    });
  }

  String _getAssigneesText(int count, bool includesCurrentUser) {
    if (count == 1) {
      return includesCurrentUser ? 'Only you' : '1 other person';
    } else if (includesCurrentUser) {
      return 'You + ${count - 1} ${count == 2 ? 'other' : 'others'}';
    } else {
      return '$count others';
    }
  }

  double _calculateUserTotal(Expense expense, String currentUserId) {
    double total = 0;

    for (final item in expense.items) {
      if (_selectedItemIds.contains(item.id)) {
        final otherAssignees = item.assignedUserIds
            .where((id) => id != currentUserId)
            .length;
        final totalAssignees = otherAssignees + 1;

        total += item.subtotal / totalAssignees;
      }
    }

    // Apply adjustments proportionally
    if (expense.items.isNotEmpty) {
      final itemsSubtotal = expense.items.fold<double>(
        0,
        (sum, item) => sum + item.subtotal,
      );
      if (itemsSubtotal > 0) {
        final multiplier = expense.calculatedTotal / itemsSubtotal;
        total *= multiplier;
      }
    }

    return total;
  }

  void _saveSelection(BuildContext context, String currentUserId) {
    if (currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to identify current user. Please re-login.'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    context.read<ExpenseBloc>().add(
      ExpenseItemsSelectionRequested(
        expenseId: widget.expenseId,
        userId: currentUserId,
        itemIds: _selectedItemIds.toList(),
      ),
    );
  }

  Expense? _resolveExpense(ExpenseState state) {
    if (state.selectedExpense?.id == widget.expenseId) {
      return state.selectedExpense;
    }

    final expenseIndex = state.expenses.indexWhere(
      (e) => e.id == widget.expenseId,
    );
    if (expenseIndex == -1) {
      return null;
    }
    return state.expenses[expenseIndex];
  }

  void _syncSelectedItemsFromExpense({
    required Expense expense,
    required String currentUserId,
  }) {
    if (currentUserId.isEmpty) {
      return;
    }

    final nextSelectedItemIds =
        expense.items
            .where((item) => item.assignedUserIds.contains(currentUserId))
            .map((item) => item.id)
            .toList()
          ..sort();

    final nextSignature = '${expense.id}:${nextSelectedItemIds.join(',')}';
    if (_initialized && _lastSyncedSelectionSignature == nextSignature) {
      return;
    }

    _selectedItemIds
      ..clear()
      ..addAll(nextSelectedItemIds);
    _initialized = true;
    _lastSyncedSelectionSignature = nextSignature;
  }

  ExpenseSplit? _getCurrentUserSplit({
    required Expense expense,
    required String currentUserId,
  }) {
    final splitIndex = expense.splits.indexWhere(
      (split) => split.userId == currentUserId,
    );
    if (splitIndex == -1) {
      return null;
    }
    return expense.splits[splitIndex];
  }

  bool _isItemLocked(Expense expense, ExpenseItem item) {
    for (final assignedUserId in item.assignedUserIds) {
      final splitIndex = expense.splits.indexWhere(
        (split) => split.userId == assignedUserId,
      );
      if (splitIndex != -1 && expense.splits[splitIndex].locksItemSelection) {
        return true;
      }
    }
    return false;
  }
}
