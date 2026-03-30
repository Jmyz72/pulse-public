import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/bill.dart';
import '../bloc/living_tools_bloc.dart';

class PaymentVerificationDialog extends StatelessWidget {
  final Bill bill;
  final BillMember member;

  const PaymentVerificationDialog({
    super.key,
    required this.bill,
    required this.member,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          '${member.userName}\'s Proof',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            member.proofImageUrl!,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.95),
          border: const Border(top: BorderSide(color: Colors.white10)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  context.read<LivingToolsBloc>().add(
                    LivingToolsBillPaymentStatusUpdated(
                      billId: bill.id,
                      memberId: member.userId,
                      status: BillPaymentStatus.rejected,
                    ),
                  );
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Reject Proof'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  context.read<LivingToolsBloc>().add(
                    LivingToolsBillPaymentStatusUpdated(
                      billId: bill.id,
                      memberId: member.userId,
                      status: BillPaymentStatus.verified,
                    ),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Approve Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
