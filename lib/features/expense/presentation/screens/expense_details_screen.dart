import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/image_lightbox.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_split.dart';
import '../bloc/expense_bloc.dart';
import '../widgets/expense_item_card.dart';
import '../widgets/expense_split_card.dart';
import '../widgets/glass_bottom_bar.dart';

class ExpenseDetailsScreen extends StatelessWidget {
  final String expenseId;

  const ExpenseDetailsScreen({super.key, required this.expenseId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpenseBloc, ExpenseState>(
      builder: (context, state) {
        // Find expense in the list or use selectedExpense
        Expense? expense = state.selectedExpense;
        if (expense == null) {
          final expenseIndex = state.expenses.indexWhere(
            (e) => e.id == expenseId,
          );
          if (expenseIndex != -1) {
            expense = state.expenses[expenseIndex];
          }
        }

        if (expense == null) {
          return Scaffold(
            appBar: GlassAppBar(
              title: 'Expense Details',
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: const Center(
              child: Text(
                'Expense not found',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        return _ExpenseDetailsContent(expense: expense);
      },
    );
  }
}

class _ExpenseDetailsContent extends StatefulWidget {
  final Expense expense;

  const _ExpenseDetailsContent({required this.expense});

  @override
  State<_ExpenseDetailsContent> createState() => _ExpenseDetailsContentState();
}

class _ExpenseDetailsContentState extends State<_ExpenseDetailsContent> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isProgressDialogVisible = false;

  Expense get expense => widget.expense;

  @override
  Widget build(BuildContext context) {
    final expenseState = context.watch<ExpenseBloc>().state;
    final theme = Theme.of(context);
    final authState = context.watch<AuthBloc>().state;
    final currentUserId = expenseState.currentUserId ?? '';
    final isSubmittingPaymentProof =
        expenseState.detailAction == ExpenseDetailAction.submittingPaymentProof;
    final expense = widget.expense;
    final isOwner = expense.ownerId == currentUserId;
    final profilePaymentIdentity = isOwner
        ? _normalizePaymentIdentity(authState.user?.paymentIdentity)
        : null;

    return BlocListener<ExpenseBloc, ExpenseState>(
      listenWhen: (previous, current) =>
          previous.detailAction != current.detailAction,
      listener: (context, state) {
        final isSubmitting =
            state.detailAction == ExpenseDetailAction.submittingPaymentProof;
        if (isSubmitting) {
          _showPaymentProofProgressDialog(context);
        } else {
          _hidePaymentProofProgressDialog(context);
        }
      },
      child: Scaffold(
        appBar: GlassAppBar(
          title: 'Expense Details',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (isOwner && expense.status == ExpenseStatus.pending)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    if (expense.type == ExpenseType.adHoc) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ad-hoc expenses cannot be edited'),
                        ),
                      );
                    } else {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.editExpense,
                        arguments: {'expense': expense},
                      );
                    }
                  } else if (value == 'delete') {
                    _showDeleteConfirmation(context);
                  } else if (value == 'settle') {
                    _showSettleConfirmation(context);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Edit'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'settle',
                    child: ListTile(
                      leading: Icon(Icons.check_circle),
                      title: Text('Force Settle'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: AppColors.error),
                      title: Text(
                        'Delete',
                        style: TextStyle(color: AppColors.error),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, theme),
              _buildTotalSection(context, theme),
              if (expense.items.isNotEmpty) _buildItemsSection(context, theme),
              _buildSplitsSection(
                context,
                theme,
                currentUserId,
                isOwner,
                profilePaymentIdentity,
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomBar(
          context,
          theme,
          currentUserId,
          isSubmittingPaymentProof,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  expense.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              StatusBadge(
                status: expense.status == ExpenseStatus.settled
                    ? BadgeStatus.paid
                    : BadgeStatus.pending,
                customLabel: expense.status == ExpenseStatus.settled
                    ? 'Settled'
                    : 'Pending',
              ),
            ],
          ),
          if (expense.description != null) ...[
            const SizedBox(height: 8),
            Text(
              expense.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                DateFormatter.formatDateTime(expense.date),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              Icon(_getTypeIcon(), size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                _getTypeLabel(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSection(BuildContext context, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
              Text(
                'RM ${expense.totalAmount.toStringAsFixed(2)}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          if (expense.items.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            _buildBreakdownRow('Subtotal', expense.itemsSubtotal, theme),
            if (expense.taxPercent != null && expense.taxPercent! > 0)
              _buildBreakdownRow(
                'Tax (${expense.taxPercent}%)',
                expense.taxAmount,
                theme,
              ),
            if (expense.serviceChargePercent != null &&
                expense.serviceChargePercent! > 0)
              _buildBreakdownRow(
                'Service (${expense.serviceChargePercent}%)',
                expense.serviceChargeAmount,
                theme,
              ),
            if (expense.discountPercent != null && expense.discountPercent! > 0)
              _buildBreakdownRow(
                'Discount (${expense.discountPercent}%)',
                -expense.discountAmount,
                theme,
                isDiscount: true,
              ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Payment Progress',
                style: TextStyle(color: Colors.white70),
              ),
              Text(
                expense.paymentProgress,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(
    String label,
    double amount,
    ThemeData theme, {
    bool isDiscount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          Text(
            '${isDiscount ? '-' : ''}RM ${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              color: isDiscount ? AppColors.success : Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection(BuildContext context, ThemeData theme) {
    final currentUserId =
        context.read<AuthBloc>().state.user?.id ??
        context.read<ExpenseBloc>().state.currentUserId ??
        '';
    final currentUserSplitIndex = expense.splits.indexWhere(
      (split) => split.userId == currentUserId,
    );
    final currentUserSelectionLocked =
        currentUserSplitIndex != -1 &&
        expense.splits[currentUserSplitIndex].locksItemSelection;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Items (${expense.items.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (expense.status == ExpenseStatus.pending &&
                  !currentUserSelectionLocked)
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.itemSelection,
                    arguments: {'expenseId': expense.id},
                  ),
                  icon: const Icon(
                    Icons.edit,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  label: const Text(
                    'Select Items',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...expense.items.map((item) {
            final selectedSplits = expense.splits
                .where((split) => item.assignedUserIds.contains(split.userId))
                .toList(growable: false);
            final selectedByNames = selectedSplits
                .map(
                  (split) => split.userName.trim().isEmpty
                      ? split.userId
                      : split.userName.trim(),
                )
                .toList(growable: false);
            final paidByNames = selectedSplits
                .where((split) => split.isPaid)
                .map(
                  (split) => split.userName.trim().isEmpty
                      ? split.userId
                      : split.userName.trim(),
                )
                .toList(growable: false);

            return ExpenseItemCard(
              item: item,
              selectedByNames: selectedByNames,
              paidByNames: paidByNames,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSplitsSection(
    BuildContext context,
    ThemeData theme,
    String currentUserId,
    bool isOwner,
    String? profilePaymentIdentity,
  ) {
    final expensePaymentIdentity = _normalizePaymentIdentity(
      expense.ownerPaymentIdentity,
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (expense.status == ExpenseStatus.pending &&
              expensePaymentIdentity == null)
            _buildOwnerIdentityNotice(
              context,
              theme,
              isOwner: isOwner,
              profilePaymentIdentity: profilePaymentIdentity,
            ),
          Text(
            'Split Details',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...expense.splits.map((split) {
            final canViewProof =
                isOwner && (split.proofImageUrl?.isNotEmpty ?? false);
            final actionLabel = canViewProof
                ? (split.needsReview ? 'Review' : 'View Proof')
                : null;

            return ExpenseSplitCard(
              split: split,
              isCurrentUser: split.userId == currentUserId,
              isOwner: isOwner,
              isExpenseOwner: split.userId == expense.ownerId,
              isPending: expense.status == ExpenseStatus.pending,
              hasItems: expense.items.isNotEmpty,
              actionLabel: actionLabel,
              onActionPressed: canViewProof
                  ? () => _showReviewProofSheet(context, split)
                  : null,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    ThemeData theme,
    String currentUserId,
    bool isSubmittingPaymentProof,
  ) {
    // Find current user's split without firstWhere/orElse type coupling.
    final userSplitIndex = expense.splits.indexWhere(
      (s) => s.userId == currentUserId,
    );
    final userSplit = userSplitIndex != -1
        ? expense.splits[userSplitIndex]
        : const ExpenseSplit(userId: '', userName: '', amount: 0);

    if (userSplit.userId.isEmpty) return const SizedBox.shrink();

    final isOwner = expense.ownerId == currentUserId;
    if (isOwner && expense.status != ExpenseStatus.settled) {
      return const SizedBox.shrink();
    }

    return GlassBottomBar(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isOwner) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your share:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'RM ${userSplit.amount.toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (!isOwner && expense.status == ExpenseStatus.pending)
            _buildParticipantAction(
              context,
              userSplit,
              isSubmittingPaymentProof,
            )
          else if (expense.status == ExpenseStatus.settled)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.success),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: AppColors.success),
                  SizedBox(width: 8),
                  Text(
                    'This expense is settled',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _getTypeIcon() {
    switch (expense.type) {
      case ExpenseType.group:
        return Icons.groups;
      case ExpenseType.oneOnOne:
        return Icons.people;
      case ExpenseType.adHoc:
        return Icons.swap_horiz;
    }
  }

  String _getTypeLabel() {
    switch (expense.type) {
      case ExpenseType.group:
        return 'Group';
      case ExpenseType.oneOnOne:
        return '1-on-1';
      case ExpenseType.adHoc:
        return 'Ad-hoc';
    }
  }

  Widget _buildOwnerIdentityNotice(
    BuildContext context,
    ThemeData theme, {
    required bool isOwner,
    required String? profilePaymentIdentity,
  }) {
    final canRefresh = isOwner && profilePaymentIdentity != null;
    final message = canRefresh
        ? 'This expense was created before your payment identity was saved. Refresh this expense to use your latest payment identity for proof matching.'
        : isOwner
        ? 'Add a payment identity in your profile to enable receipt proof matching for this expense.'
        : 'Owner payment identity is not configured on this expense yet. Payment proofs will stay in manual review until the owner refreshes it.';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.warning,
            ),
          ),
          if (canRefresh) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.read<ExpenseBloc>().add(
                    ExpenseOwnerPaymentIdentityRefreshRequested(
                      expenseId: expense.id,
                      ownerId: expense.ownerId,
                      paymentIdentity: profilePaymentIdentity,
                    ),
                  );
                },
                icon: const Icon(Icons.sync),
                label: const Text('Use latest payment identity'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warning,
                  side: BorderSide(
                    color: AppColors.warning.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String? _normalizePaymentIdentity(String? paymentIdentity) {
    final trimmed = paymentIdentity?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  Widget _buildParticipantAction(
    BuildContext context,
    ExpenseSplit userSplit,
    bool isSubmittingPaymentProof,
  ) {
    switch (userSplit.paymentStatus) {
      case ExpensePaymentStatus.unpaid:
        return SizedBox(
          width: double.infinity,
          child: GlassButton(
            text: 'Upload Payment Proof',
            icon: Icons.upload_file,
            isLoading: isSubmittingPaymentProof,
            isPrimary: true,
            onPressed: () {
              if (isSubmittingPaymentProof) return;
              _showProofImageSourceSheet(context);
            },
          ),
        );
      case ExpensePaymentStatus.proofSubmitted:
        return _buildStatusPanel(
          icon: Icons.pending_actions,
          color: AppColors.warning,
          message: 'Payment proof submitted. Waiting for owner review.',
        );
      case ExpensePaymentStatus.proofRejected:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusPanel(
              icon: Icons.cancel_outlined,
              color: AppColors.error,
              message: userSplit.proofRejectionReason?.isNotEmpty == true
                  ? 'Proof rejected: ${userSplit.proofRejectionReason}'
                  : 'Payment proof was rejected. Please resubmit.',
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: GlassButton(
                text: 'Resubmit Proof',
                icon: Icons.upload_file,
                isLoading: isSubmittingPaymentProof,
                isPrimary: true,
                onPressed: () {
                  if (isSubmittingPaymentProof) return;
                  _showProofImageSourceSheet(context);
                },
              ),
            ),
          ],
        );
      case ExpensePaymentStatus.paid:
        return _buildStatusPanel(
          icon: Icons.check_circle,
          color: AppColors.success,
          message: 'Your payment has been recorded.',
        );
    }
  }

  Widget _buildStatusPanel({
    required IconData icon,
    required Color color,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettleConfirmation(BuildContext context) {
    final unpaidSplits = expense.splits.where((s) => !s.isPaid).toList();
    if (unpaidSplits.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundLight,
        title: const Text(
          'Force Settle',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'This will mark ${unpaidSplits.length} unpaid split(s) as paid. Continue?',
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
              _settleExpense(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.success),
            child: const Text('Settle'),
          ),
        ],
      ),
    );
  }

  void _settleExpense(BuildContext context) {
    for (final split in expense.splits) {
      if (!split.isPaid) {
        context.read<ExpenseBloc>().add(
          ExpenseSplitPaidToggled(
            expenseId: expense.id,
            userId: split.userId,
            isPaid: true,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
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
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _showProofImageSourceSheet(BuildContext context) async {
    if (_isSubmittingPaymentProof) return;

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickProofImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickProofImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickProofImage(ImageSource source) async {
    if (_isSubmittingPaymentProof) return;

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1600,
      );
      if (pickedFile == null || !mounted) return;

      final currentUserId =
          context.read<AuthBloc>().state.user?.id ??
          context.read<ExpenseBloc>().state.currentUserId ??
          '';
      if (currentUserId.isEmpty) return;

      await _showProofPreviewSheet(
        imagePath: pickedFile.path,
        userId: currentUserId,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick payment proof: $e')),
      );
    }
  }

  Future<void> _showProofPreviewSheet({
    required String imagePath,
    required String userId,
  }) async {
    if (!mounted || _isSubmittingPaymentProof) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              key: const ValueKey('payment-proof-preview-sheet'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload this payment proof?',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please confirm the selected image before uploading.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  key: const ValueKey('payment-proof-upload-preview-image'),
                  onTap: () => ImageLightbox.showFile(
                    context,
                    imagePath,
                    'payment-proof-upload-$imagePath',
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Hero(
                      tag: 'payment-proof-upload-$imagePath',
                      child: Image.file(
                        File(imagePath),
                        height: 280,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap image to view full size',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        key: const ValueKey('confirm-payment-proof-upload'),
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          context.read<ExpenseBloc>().add(
                            ExpensePaymentProofSubmissionRequested(
                              expenseId: expense.id,
                              userId: userId,
                              imagePath: imagePath,
                            ),
                          );
                        },
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text('Upload'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _isSubmittingPaymentProof =>
      context.read<ExpenseBloc>().state.detailAction ==
      ExpenseDetailAction.submittingPaymentProof;

  static const String _reviewActionReject = 'reject';
  static const String _reviewActionApprove = 'approve';

  void _showPaymentProofProgressDialog(BuildContext context) {
    if (_isProgressDialogVisible) return;
    _isProgressDialogVisible = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: Dialog(
          key: const ValueKey('payment-proof-progress-dialog'),
          backgroundColor: AppColors.backgroundLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Submitting payment proof...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Analyzing receipt and saving payment. Please wait.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      _isProgressDialogVisible = false;
    });
  }

  void _hidePaymentProofProgressDialog(BuildContext context) {
    if (!_isProgressDialogVisible || !mounted) return;
    Navigator.of(context, rootNavigator: false).pop();
  }

  Future<void> _showReviewProofSheet(
    BuildContext context,
    ExpenseSplit split,
  ) async {
    final canReview = split.needsReview;
    final proofHeroTag = split.proofImageUrl?.isNotEmpty == true
        ? 'payment-proof-${split.userId}-${split.proofImageUrl!}'
        : null;

    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  canReview ? 'Review Payment Proof' : 'Payment Proof',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (split.proofImageUrl?.isNotEmpty ?? false)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        key: const ValueKey('payment-proof-image-preview'),
                        onTap: () => ImageLightbox.show(
                          context,
                          split.proofImageUrl!,
                          proofHeroTag,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Hero(
                            tag: proofHeroTag!,
                            child: Image.network(
                              split.proofImageUrl!,
                              height: 220,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    height: 220,
                                    width: double.infinity,
                                    color: AppColors.background.withValues(
                                      alpha: 0.4,
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'Unable to load proof image',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap image to view full size',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                _buildReviewRow(
                  'Expected amount',
                  'RM ${split.amount.toStringAsFixed(2)}',
                ),
                _buildReviewRow(
                  'Matched amount',
                  split.matchedAmount != null
                      ? 'RM ${split.matchedAmount!.toStringAsFixed(2)}'
                      : 'Not detected',
                ),
                _buildReviewRow(
                  'Matched recipient',
                  split.matchedRecipient?.isNotEmpty == true
                      ? split.matchedRecipient!
                      : 'Not detected',
                ),
                _buildReviewRow(
                  'Confidence',
                  split.matchConfidence != null
                      ? '${(split.matchConfidence! * 100).toStringAsFixed(0)}%'
                      : 'Unknown',
                ),
                const SizedBox(height: 16),
                if (canReview)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.pop(sheetContext, _reviewActionReject),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                          ),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () =>
                              Navigator.pop(sheetContext, _reviewActionApprove),
                          child: const Text('Approve'),
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Close'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!mounted) return;

    if (action == _reviewActionReject) {
      await _showRejectProofDialog(this.context, split);
    } else if (action == _reviewActionApprove) {
      _approveProof(this.context, split);
    }
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRejectProofDialog(
    BuildContext context,
    ExpenseSplit split,
  ) async {
    var reason = '';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundLight,
        title: const Text(
          'Reject Payment Proof',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          onChanged: (value) => reason = value,
          decoration: const InputDecoration(
            hintText: 'Tell the payer what is wrong with this proof',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _rejectProof(context, split, reason);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _approveProof(BuildContext context, ExpenseSplit split) {
    final reviewerId =
        context.read<AuthBloc>().state.user?.id ??
        context.read<ExpenseBloc>().state.currentUserId ??
        '';
    if (reviewerId.isEmpty) return;

    context.read<ExpenseBloc>().add(
      ExpensePaymentProofApproved(
        expenseId: expense.id,
        userId: split.userId,
        reviewerId: reviewerId,
      ),
    );
  }

  void _rejectProof(BuildContext context, ExpenseSplit split, String reason) {
    final reviewerId =
        context.read<AuthBloc>().state.user?.id ??
        context.read<ExpenseBloc>().state.currentUserId ??
        '';
    if (reviewerId.isEmpty) return;

    context.read<ExpenseBloc>().add(
      ExpensePaymentProofRejected(
        expenseId: expense.id,
        userId: split.userId,
        reviewerId: reviewerId,
        reason: reason,
      ),
    );
  }
}
