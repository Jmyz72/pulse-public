import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../chat/presentation/bloc/chat_bloc.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_split.dart';
import '../bloc/expense_bloc.dart';
import '../widgets/balance_summary_card.dart';

class BalanceScreen extends StatelessWidget {
  const BalanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpenseBloc, ExpenseState>(
      builder: (context, state) {
        final currentUserId = state.currentUserId ?? '';
        return Scaffold(
          appBar: GlassAppBar(
            title: 'Balance Summary',
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: state.status == ExpenseLoadStatus.loading
              ? const Center(child: CircularProgressIndicator())
              : _buildContent(context, state, currentUserId),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ExpenseState state,
    String currentUserId,
  ) {
    final theme = Theme.of(context);
    final pendingExpenses = state.pendingExpenses;
    final totalOwedToUser = state.totalOwedToUser(currentUserId);
    final totalUserOwes = state.totalUserOwes(currentUserId);
    final netBalance = totalOwedToUser - totalUserOwes;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Card
          BalanceSummaryCard(
            netBalance: netBalance,
            totalOwedToUser: totalOwedToUser,
            totalUserOwes: totalUserOwes,
          ),

          // Pending expenses breakdown
          if (pendingExpenses.isEmpty)
            _buildEmptyState(theme)
          else
            _buildPendingExpenses(context, theme, state, currentUserId),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppColors.success.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'All settled!',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No pending expenses',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingExpenses(
    BuildContext context,
    ThemeData theme,
    ExpenseState state,
    String currentUserId,
  ) {
    final chatState = context.read<ChatBloc>().state;
    final expensesByChatRoom = <String?, List<Expense>>{};

    for (final expense in state.pendingExpenses) {
      final key = expense.chatRoomId;
      if (!expensesByChatRoom.containsKey(key)) {
        expensesByChatRoom[key] = [];
      }
      expensesByChatRoom[key]!.add(expense);
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pending by Group',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...expensesByChatRoom.entries.map((entry) {
            final chatRoomId = entry.key;
            final expenses = entry.value;

            String groupName = 'Ad-hoc';
            if (chatRoomId != null) {
              final chatRoomIndex = chatState.chatRooms.indexWhere(
                (r) => r.id == chatRoomId,
              );
              if (chatRoomIndex != -1) {
                groupName = chatState.chatRooms[chatRoomIndex].name;
              }
            }

            return _buildGroupSection(
              context,
              theme,
              groupName.isNotEmpty ? groupName : 'Unknown',
              expenses,
              currentUserId,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGroupSection(
    BuildContext context,
    ThemeData theme,
    String groupName,
    List<Expense> expenses,
    String currentUserId,
  ) {
    // Calculate totals for this group
    double owedToUser = 0;
    double userOwes = 0;

    for (final expense in expenses) {
      if (expense.ownerId == currentUserId) {
        final unpaidSplits = expense.splits.where(
          (s) => !s.isPaid && s.userId != currentUserId,
        );
        owedToUser += unpaidSplits.fold(0.0, (sum, s) => sum + s.amount);
      } else {
        final userSplitIndex = expense.splits.indexWhere(
          (s) => s.userId == currentUserId,
        );
        if (userSplitIndex != -1) {
          final userSplit = expense.splits[userSplitIndex];
          if (!userSplit.isPaid) {
            userOwes += userSplit.amount;
          }
        }
      }
    }

    final netAmount = owedToUser - userOwes;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        borderRadius: 24,
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          leading: IconCircle(
            icon: Icons.groups,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            iconColor: AppColors.primary,
            size: 40,
          ),
          title: Text(
            groupName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            '${expenses.length} pending expenses',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${netAmount >= 0 ? '+' : ''}RM ${netAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: netAmount >= 0 ? AppColors.success : AppColors.warning,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                netAmount >= 0 ? 'to receive' : 'to pay',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          children: expenses
              .map((e) => _buildExpenseRow(context, theme, e, currentUserId))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildExpenseRow(
    BuildContext context,
    ThemeData theme,
    Expense expense,
    String currentUserId,
  ) {
    final isOwner = expense.ownerId == currentUserId;
    final unpaidSplits = expense.splits
        .where((s) => !s.isPaid && s.userId != currentUserId)
        .toList();

    double amount;
    String description;

    if (isOwner) {
      amount = unpaidSplits.fold(0.0, (sum, s) => sum + s.amount);
      final names = unpaidSplits.map((s) => s.userName).join(', ');
      description = 'From $names';
    } else {
      final userSplitIndex = expense.splits.indexWhere(
        (s) => s.userId == currentUserId,
      );
      final userSplit = userSplitIndex != -1
          ? expense.splits[userSplitIndex]
          : const ExpenseSplit(userId: '', userName: '', amount: 0);
      amount = -userSplit.amount;
      final ownerSplitIndex = expense.splits.indexWhere(
        (s) => s.userId == expense.ownerId,
      );
      final ownerName = ownerSplitIndex != -1
          ? expense.splits[ownerSplitIndex].userName
          : 'Owner';
      description = 'To $ownerName';
    }

    return ListTile(
      onTap: () {
        context.read<ExpenseBloc>().add(ExpenseSelected(expense: expense));
        Navigator.pushNamed(
          context,
          AppRoutes.expenseDetails,
          arguments: {'expenseId': expense.id},
        );
      },
      title: Text(
        expense.title,
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      subtitle: Text(
        description,
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Text(
        '${amount >= 0 ? '+' : ''}RM ${amount.toStringAsFixed(2)}',
        style: TextStyle(
          color: amount >= 0 ? AppColors.success : AppColors.warning,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
