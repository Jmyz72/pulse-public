import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../chat/domain/entities/message.dart';
import '../../../chat/presentation/bloc/chat_bloc.dart';
import '../../domain/entities/expense.dart';
import '../bloc/expense_bloc.dart';
import '../widgets/expense_card.dart';
import '../widgets/expense_stat_chip.dart';

enum _ExpenseFilter { all, pending, settled }

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  _ExpenseFilter _activeFilter = _ExpenseFilter.pending;
  String? _preselectedChatRoomId;
  List<ChatRoom>? _routeChatRooms;
  bool _hasLoadedRouteArgs = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedRouteArgs) {
      _hasLoadedRouteArgs = true;
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _routeChatRooms = args['chatRooms'] as List<ChatRoom>?;
        _preselectedChatRoomId = args['preselectedChatRoomId'] as String?;
      }
      _loadExpenses();
    }
  }

  void _loadExpenses() {
    if (_preselectedChatRoomId != null) {
      context.read<ExpenseBloc>().add(
        ExpenseLoadRequested(chatRoomIds: [_preselectedChatRoomId!]),
      );
    } else {
      final chatState = context.read<ChatBloc>().state;
      final chatRoomIds = chatState.chatRooms.map((r) => r.id).toList();
      context.read<ExpenseBloc>().add(
        ExpenseLoadRequested(chatRoomIds: chatRoomIds),
      );
    }
  }

  List<Expense> _getFilteredExpenses(ExpenseState state) {
    switch (_activeFilter) {
      case _ExpenseFilter.all:
        return state.expenses;
      case _ExpenseFilter.pending:
        return state.pendingExpenses;
      case _ExpenseFilter.settled:
        return state.settledExpenses;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExpenseBloc, ExpenseState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.detailStatus != current.detailStatus ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if ((state.status == ExpenseLoadStatus.error ||
                state.detailStatus == ExpenseDetailStatus.error) &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: GlassAppBar(
            title: 'Expenses',
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.document_scanner,
                  color: AppColors.primary,
                ),
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.receiptScan);
                },
                tooltip: 'Scan Receipt',
              ),
              IconButton(
                icon: const Icon(
                  Icons.account_balance_wallet,
                  color: AppColors.textPrimary,
                ),
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.balance);
                },
                tooltip: 'Balance Summary',
              ),
            ],
          ),
          body: _buildBody(state),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.addExpense,
                arguments: {
                  'chatRooms':
                      _routeChatRooms ??
                      context.read<ChatBloc>().state.chatRooms,
                  if (_preselectedChatRoomId != null)
                    'preselectedChatRoomId': _preselectedChatRoomId,
                },
              );
            },
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: AppColors.background),
          ),
        );
      },
    );
  }

  Widget _buildBody(ExpenseState state) {
    if (state.status == ExpenseLoadStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == ExpenseLoadStatus.error && state.expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: AppDimensions.spacingMd),
            const Text('Failed to load expenses'),
            const SizedBox(height: AppDimensions.spacingSm),
            GlassButton(
              text: 'Retry',
              onPressed: _loadExpenses,
              isPrimary: true,
            ),
          ],
        ),
      );
    }

    final filteredExpenses = _getFilteredExpenses(state);

    return Column(
      children: [
        _buildSummaryCard(Theme.of(context), state),
        _buildFilterChips(state),
        Expanded(
          child: filteredExpenses.isEmpty
              ? _buildEmptyState()
              : _buildGroupedList(state, filteredExpenses),
        ),
      ],
    );
  }

  // ─── Summary Card ──────────────────────────────────────────────

  Widget _buildSummaryCard(ThemeData theme, ExpenseState state) {
    if (state.status != ExpenseLoadStatus.loaded) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Expenses',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'RM ${state.totalExpenses.toStringAsFixed(2)}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ExpenseStatChip(
                  count: '${state.pendingExpenses.length}',
                  label: 'Pending',
                  dotColor: AppColors.warning,
                ),
                const SizedBox(height: 6),
                ExpenseStatChip(
                  count: '${state.settledExpenses.length}',
                  label: 'Settled',
                  dotColor: AppColors.success,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Filter Chips ──────────────────────────────────────────────

  Widget _buildFilterChips(ExpenseState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
        vertical: AppDimensions.spacingSm,
      ),
      child: Row(
        children: [
          _buildTabChip(
            label: 'All',
            count: state.expenses.length,
            color: AppColors.primary,
            filter: _ExpenseFilter.all,
          ),
          const SizedBox(width: 8),
          _buildTabChip(
            label: 'Pending',
            count: state.pendingExpenses.length,
            color: AppColors.warning,
            filter: _ExpenseFilter.pending,
          ),
          const SizedBox(width: 8),
          _buildTabChip(
            label: 'Settled',
            count: state.settledExpenses.length,
            color: AppColors.success,
            filter: _ExpenseFilter.settled,
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip({
    required String label,
    required int count,
    required Color color,
    required _ExpenseFilter filter,
  }) {
    final isSelected = _activeFilter == filter;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeFilter = filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : Colors.grey.withValues(alpha: 0.2),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$label ($count)',
                style: TextStyle(
                  color: isSelected ? color : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Grouped List ──────────────────────────────────────────────

  Widget _buildGroupedList(ExpenseState state, List<Expense> filteredExpenses) {
    final chatState = context.watch<ChatBloc>().state;
    final currentUserId = state.currentUserId ?? '';
    final grouped = state.expensesByChatRoomFiltered(filteredExpenses);
    final chatRoomIds = grouped.keys.toList();

    return RefreshIndicator(
      onRefresh: () async {
        _loadExpenses();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppDimensions.spacingMd),
        itemCount: chatRoomIds.length,
        itemBuilder: (context, index) {
          final chatRoomId = chatRoomIds[index];
          final expenses = grouped[chatRoomId]!;

          final chatRoomIndex = chatState.chatRooms.indexWhere(
            (r) => r.id == chatRoomId,
          );
          if (chatRoomIndex == -1) return const SizedBox.shrink();
          final chatRoom = chatState.chatRooms[chatRoomIndex];
          String displayName;
          if (chatRoom.isGroup || currentUserId.isEmpty) {
            displayName = currentUserId.isNotEmpty
                ? chatRoom.displayNameFor(currentUserId)
                : chatRoom.name;
          } else if (chatRoom.memberNames.isNotEmpty) {
            displayName = chatRoom.displayNameFor(currentUserId);
          } else {
            final otherUserId = chatRoom.members.firstWhere(
              (id) => id != currentUserId,
              orElse: () => '',
            );
            if (otherUserId.isEmpty) {
              displayName = chatRoom.name;
            } else {
              displayName =
                  state.friendDisplayNamesById[otherUserId] ?? chatRoom.name;
            }
          }
          final theme = Theme.of(context);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 8),
                child: Row(
                  children: [
                    Icon(
                      chatRoom.members.length > 2 ? Icons.groups : Icons.people,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        displayName.isNotEmpty ? displayName : 'Chat',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Text(
                      '${expenses.length} expenses',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Expenses in this chat room
              ...expenses.map((expense) {
                return Dismissible(
                  key: Key('expense_${expense.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    return await _showDeleteConfirmation(context, expense);
                  },
                  onDismissed: (_) {
                    context.read<ExpenseBloc>().add(
                      ExpenseDeleteRequested(id: expense.id),
                    );
                  },
                  child: ExpenseCard(
                    expense: expense,
                    onTap: () {
                      context.read<ExpenseBloc>().add(
                        ExpenseSelected(expense: expense),
                      );
                      Navigator.pushNamed(
                        context,
                        AppRoutes.expenseDetails,
                        arguments: {'expenseId': expense.id},
                      );
                    },
                    onLongPress: () {
                      _showDeleteDialog(context, expense);
                    },
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  // ─── Empty States ──────────────────────────────────────────────

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    late final IconData icon;
    late final String title;
    late final String subtitle;

    switch (_activeFilter) {
      case _ExpenseFilter.all:
        icon = Icons.receipt_long_outlined;
        title = 'No expenses yet';
        subtitle = 'Tap + to add your first expense';
      case _ExpenseFilter.pending:
        icon = Icons.check_circle_outline;
        title = 'All settled up!';
        subtitle = 'No pending expenses';
      case _ExpenseFilter.settled:
        icon = Icons.receipt_long_outlined;
        title = 'No settled expenses';
        subtitle = 'Settled expenses will appear here';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
            child: Icon(
              icon,
              size: 40,
              color: AppColors.primary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Dialogs ───────────────────────────────────────────────────

  Future<bool> _showDeleteConfirmation(
    BuildContext context,
    Expense expense,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.backgroundLight,
            title: const Text(
              'Delete Expense',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: Text(
              'Are you sure you want to delete "${expense.title}"?',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showDeleteDialog(BuildContext context, Expense expense) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundLight,
        title: const Text(
          'Delete Expense',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "${expense.title}"?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ExpenseBloc>().add(
                ExpenseDeleteRequested(id: expense.id),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
