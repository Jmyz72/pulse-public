import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/bill_payment_verification_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../injection_container.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/image_lightbox.dart';
import '../../domain/entities/bill.dart';
import '../bloc/living_tools_bloc.dart';
import 'bill_payment_proof_sheet.dart';
import 'payment_verification_dialog.dart';

class BillCard extends StatelessWidget {
  final Bill bill;
  final String currentUserId;
  final VoidCallback onTap;

  const BillCard({
    super.key,
    required this.bill,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = bill.status == BillStatus.overdue;
    final isPaid = bill.status == BillStatus.paid;
    final daysUntil = bill.dueDate.difference(DateTime.now()).inDays;
    final yourShare = bill.getShareForUser(currentUserId);
    final billColor = _getBillColor(bill.type);

    // Safely find the current user's membership in the bill
    BillMember? currentUserMember;
    for (final m in bill.members) {
      if (m.userId == currentUserId) {
        currentUserMember = m;
        break;
      }
    }
    currentUserMember ??= bill.members.first;

    final hasUserPaid = currentUserMember.hasPaid;
    final paymentStatus = currentUserMember.paymentStatus;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        borderColor: isOverdue
            ? AppColors.error
            : (isPaid ? AppColors.success : billColor),
        borderOpacity: isOverdue ? 0.6 : 0.3,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type Indicator Side Bar
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: isOverdue ? AppColors.error : billColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: billColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getBillIcon(bill.type),
                              color: billColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bill.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Due: ${DateFormatter.formatDate(bill.dueDate)}',
                                  style: TextStyle(
                                    color: isOverdue
                                        ? AppColors.error
                                        : AppColors.textTertiary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildStatusIndicator(isPaid, isOverdue, daysUntil),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Bill',
                                style: TextStyle(
                                  color: AppColors.textTertiary,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                'RM ${bill.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Your Share',
                                style: TextStyle(
                                  color: AppColors.textTertiary,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                'RM ${yourShare.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Colors.white10),
                      const SizedBox(height: 16),

                      _buildPaymentAction(
                        context,
                        paymentStatus,
                        hasUserPaid,
                        currentUserMember,
                      ),

                      if (bill.createdBy == currentUserId &&
                          bill.members.length > 1) ...[
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: Colors.white10),
                        const SizedBox(height: 16),
                        const Text(
                          'Verify Member Payments',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...bill.members
                            .where((m) => m.userId != currentUserId)
                            .map((m) => _buildMemberStatusRow(context, m)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberStatusRow(BuildContext context, BillMember member) {
    Color statusColor;
    String statusText;

    if (member.hasPaid) {
      statusColor = AppColors.success;
      statusText = 'Verified';
    } else {
      switch (member.paymentStatus) {
        case BillPaymentStatus.pending:
          statusColor = AppColors.warning;
          statusText = 'Pending';
          break;
        case BillPaymentStatus.rejected:
          statusColor = AppColors.error;
          statusText = 'Rejected';
          break;
        case BillPaymentStatus.none:
        default:
          statusColor = AppColors.textTertiary;
          statusText = 'Unpaid';
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: statusColor.withValues(alpha: 0.2),
            child: Text(
              member.userName[0].toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.userName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontSize: 10),
                ),
              ],
            ),
          ),
          if (!member.hasPaid) ...[
            // Creator's manual Approve (fallback)
            if (bill.createdBy == currentUserId &&
                (member.paymentStatus == BillPaymentStatus.none ||
                    member.paymentStatus == BillPaymentStatus.rejected))
              IconButton(
                icon: const Icon(
                  Icons.check_circle_outline,
                  size: 20,
                  color: AppColors.success,
                ),
                onPressed: () {
                  context.read<LivingToolsBloc>().add(
                    LivingToolsBillPaymentStatusUpdated(
                      billId: bill.id,
                      memberId: member.userId,
                      status: BillPaymentStatus.verified,
                    ),
                  );
                },
                tooltip: 'Mark as Paid (Manual)',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.only(right: 8),
              ),

            // Nudge button
            if (bill.createdBy == currentUserId)
              IconButton(
                icon: const Icon(
                  Icons.notifications_active_outlined,
                  size: 20,
                  color: AppColors.warning,
                ),
                onPressed: () {
                  context.read<LivingToolsBloc>().add(
                    LivingToolsBillMemberNudged(
                      billId: bill.id,
                      memberId: member.userId,
                    ),
                  );
                },
                tooltip: 'Nudge Member',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.only(right: 8),
              ),
          ],
          if (member.paymentStatus == BillPaymentStatus.pending)
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        PaymentVerificationDialog(bill: bill, member: member),
                    fullscreenDialog: true,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 0,
                ),
                minimumSize: const Size(0, 28),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text('Verify Proof', style: TextStyle(fontSize: 11)),
            ),
          if (member.hasPaid && member.proofImageUrl != null)
            IconButton(
              icon: const Icon(
                Icons.receipt_long,
                size: 18,
                color: AppColors.textSecondary,
              ),
              onPressed: () {
                final proofImageUrl = member.proofImageUrl;
                if (proofImageUrl == null) return;
                showDialog(
                  context: context,
                  builder: (_) => ImageLightbox(imageUrl: proofImageUrl),
                );
              },
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),

          // Creator's manual Undo (fallback)
          if (member.hasPaid && bill.createdBy == currentUserId)
            IconButton(
              icon: Icon(
                Icons.undo_rounded,
                size: 18,
                color: AppColors.error.withValues(alpha: 0.7),
              ),
              onPressed: () {
                context.read<LivingToolsBloc>().add(
                  LivingToolsBillPaymentStatusUpdated(
                    billId: bill.id,
                    memberId: member.userId,
                    status: BillPaymentStatus.none,
                  ),
                );
              },
              tooltip: 'Undo Verification',
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.only(left: 8),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentAction(
    BuildContext context,
    BillPaymentStatus status,
    bool hasPaid,
    BillMember member,
  ) {
    if (hasPaid) {
      // ... same as before ...
      return Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 16),
          const SizedBox(width: 8),
          const Text(
            'You have settled this bill',
            style: TextStyle(
              color: AppColors.success,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (member.proofImageUrl != null)
            TextButton.icon(
              onPressed: () {
                final proofImageUrl = member.proofImageUrl;
                if (proofImageUrl == null) return;
                showDialog(
                  context: context,
                  builder: (_) => ImageLightbox(imageUrl: proofImageUrl),
                );
              },
              icon: const Icon(Icons.receipt_long, size: 14),
              label: const Text('View Receipt', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      );
    }

    // Special case: Creator marking their own share as paid
    if (bill.createdBy == currentUserId) {
      return CustomButton(
        text: 'Mark as Paid',
        icon: Icons.check_circle_outline,
        backgroundColor: AppColors.success,
        onPressed: () {
          context.read<LivingToolsBloc>().add(
            LivingToolsBillPaymentStatusUpdated(
              billId: bill.id,
              memberId: currentUserId,
              status: BillPaymentStatus.verified,
            ),
          );
        },
      );
    }

    switch (status) {
      case BillPaymentStatus.pending:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.hourglass_empty_rounded,
                color: AppColors.warning,
                size: 14,
              ),
              SizedBox(width: 8),
              Text(
                'Proof uploaded. Waiting for verification.',
                style: TextStyle(
                  color: AppColors.warning,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      case BillPaymentStatus.rejected:
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.cancel_rounded, color: AppColors.error, size: 14),
                  SizedBox(width: 8),
                  Text(
                    'Proof rejected. Please upload again.',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildPayButton(context, member),
          ],
        );
      case BillPaymentStatus.none:
      default:
        return _buildPayButton(context, member);
    }
  }

  Widget _buildPayButton(BuildContext context, BillMember member) {
    return CustomButton(
      text: 'Pay & Upload Proof',
      icon: Icons.payments_outlined,
      backgroundColor: AppColors.secondary,
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => BillPaymentProofSheet(
            bill: bill,
            member: member,
            verificationService: sl<BillPaymentVerificationService>(),
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator(bool isPaid, bool isOverdue, int daysUntil) {
    Color color;
    String text;
    IconData icon;

    if (isPaid) {
      color = AppColors.success;
      text = 'Paid';
      icon = Icons.check_circle_outline_rounded;
    } else if (isOverdue) {
      color = AppColors.error;
      text = 'Overdue';
      icon = Icons.error_outline_rounded;
    } else {
      color = AppColors.warning;
      text = '${daysUntil}d left';
      icon = Icons.schedule_rounded;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  IconData _getBillIcon(BillType type) {
    switch (type) {
      case BillType.rent:
        return Icons.home_rounded;
      case BillType.utilities:
        return Icons.bolt_rounded;
      case BillType.internet:
        return Icons.wifi_rounded;
      case BillType.cleaning:
        return Icons.cleaning_services_rounded;
      case BillType.water:
        return Icons.water_drop_rounded;
      case BillType.other:
        return Icons.receipt_long_rounded;
    }
  }

  Color _getBillColor(BillType type) {
    switch (type) {
      case BillType.rent:
        return const Color(0xFF8B5CF6);
      case BillType.utilities:
        return const Color(0xFFF59E0B);
      case BillType.internet:
        return const Color(0xFF3B82F6);
      case BillType.cleaning:
        return const Color(0xFF10B981);
      case BillType.water:
        return const Color(0xFF06B6D4);
      case BillType.other:
        return const Color(0xFF6B7280);
    }
  }
}
