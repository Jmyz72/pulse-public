import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/bill.dart';
import '../../domain/entities/bill_summary.dart';
import '../../domain/usecases/create_bill.dart';
import '../../domain/usecases/delete_bill.dart';
import '../../domain/usecases/get_bills.dart';
import '../../domain/usecases/get_bills_summary.dart';
import '../../domain/usecases/mark_bill_as_paid.dart';
import '../../domain/usecases/nudge_member.dart';
import '../../domain/usecases/update_bill.dart';
import '../../domain/usecases/watch_bills.dart';

part 'living_tools_event.dart';
part 'living_tools_state.dart';

class LivingToolsBloc extends Bloc<LivingToolsEvent, LivingToolsState> {
  final GetBills getBills;
  final WatchBills watchBills;
  final CreateBill createBill;
  final DeleteBill deleteBill;
  final MarkBillAsPaid markBillAsPaid;
  final UpdateBill updateBill;
  final NudgeMember nudgeMember;
  final GetBillsSummary getBillsSummary;

  StreamSubscription? _billsSubscription;
  String? _lastUserId;
  List<String>? _lastChatRoomIds;

  LivingToolsBloc({
    required this.getBills,
    required this.watchBills,
    required this.createBill,
    required this.deleteBill,
    required this.markBillAsPaid,
    required this.updateBill,
    required this.nudgeMember,
    required this.getBillsSummary,
  }) : super(const LivingToolsState()) {
    on<LivingToolsLoadRequested>(_onLoadRequested);
    on<LivingToolsBillsUpdated>(_onBillsUpdated);
    on<LivingToolsBillCreated>(_onBillCreated);
    on<LivingToolsBillDeleted>(_onBillDeleted);
    on<LivingToolsBillMarkedAsPaid>(_onBillMarkedAsPaid);
    on<LivingToolsBillPaymentProofUploaded>(_onBillPaymentProofUploaded);
    on<LivingToolsBillPaymentStatusUpdated>(_onBillPaymentStatusUpdated);
    on<LivingToolsBillMemberNudged>(_onBillMemberNudged);
    on<LivingToolsTabChanged>(_onTabChanged);
  }

  Future<void> _onBillPaymentProofUploaded(
    LivingToolsBillPaymentProofUploaded event,
    Emitter<LivingToolsState> emit,
  ) async {
    final bill = state.allBills.firstWhere((b) => b.id == event.billId);
    final updatedMembers = bill.members.map((m) {
      if (m.userId == event.memberId || m.id == event.memberId) {
        return m.copyWith(
          paymentStatus: BillPaymentStatus.pending,
          proofImageUrl: event.proofImageUrl,
          transactionRef: event.transactionRef,
        );
      }
      return m;
    }).toList();

    final updatedBill = bill.copyWith(members: updatedMembers);
    await updateBill(UpdateBillParams(bill: updatedBill));
  }

  Future<void> _onBillPaymentStatusUpdated(
    LivingToolsBillPaymentStatusUpdated event,
    Emitter<LivingToolsState> emit,
  ) async {
    final bill = state.allBills.firstWhere((b) => b.id == event.billId);
    final updatedMembers = bill.members.map((m) {
      if (m.userId == event.memberId || m.id == event.memberId) {
        final isVerified = event.status == BillPaymentStatus.verified;
        return m.copyWith(
          paymentStatus: event.status,
          hasPaid: isVerified,
          paidAt: isVerified ? DateTime.now() : null,
        );
      }
      return m;
    }).toList();

    final allPaid = updatedMembers.every((m) => m.hasPaid);
    final updatedBill = bill.copyWith(
      members: updatedMembers,
      status: allPaid ? BillStatus.paid : bill.status,
    );
    await updateBill(UpdateBillParams(bill: updatedBill));
  }

  Future<void> _onBillMemberNudged(
    LivingToolsBillMemberNudged event,
    Emitter<LivingToolsState> emit,
  ) async {
    // Find the bill and member to check cooldown
    final bill = state.bills.where((b) => b.id == event.billId).firstOrNull;
    if (bill != null) {
      final member = bill.members.where((m) => m.id == event.memberId || m.userId == event.memberId).firstOrNull;
      if (member != null && member.lastNudgedAt != null) {
        final now = DateTime.now();
        final difference = now.difference(member.lastNudgedAt!);
        if (difference.inHours < 1) {
          // Too soon to nudge again (1 hour cooldown)
          return;
        }
      }
    }

    await nudgeMember(NudgeMemberParams(
      billId: event.billId,
      memberId: event.memberId,
    ));
  }

  Future<void> _onLoadRequested(
    LivingToolsLoadRequested event,
    Emitter<LivingToolsState> emit,
  ) async {
    emit(state.copyWith(status: LivingToolsStatus.loading));
    _lastUserId = event.userId;
    _lastChatRoomIds = event.chatRoomIds;

    await _billsSubscription?.cancel();
    _billsSubscription = watchBills(event.chatRoomIds).listen(
      (bills) => add(LivingToolsBillsUpdated(bills: bills)),
    );
  }

  Future<void> _onBillsUpdated(
    LivingToolsBillsUpdated event,
    Emitter<LivingToolsState> emit,
  ) async {
    if (_lastUserId == null || _lastChatRoomIds == null) {
      emit(state.copyWith(status: LivingToolsStatus.loaded, bills: event.bills));
      return;
    }

    final summaryResult = await getBillsSummary(
      GetBillsSummaryParams(userId: _lastUserId!, chatRoomIds: _lastChatRoomIds!),
    );

    summaryResult.fold(
      (failure) => emit(state.copyWith(
        status: LivingToolsStatus.loaded,
        bills: event.bills,
      )),
      (summary) => emit(state.copyWith(
        status: LivingToolsStatus.loaded,
        bills: event.bills,
        summary: summary,
      )),
    );
  }

  @override
  Future<void> close() {
    _billsSubscription?.cancel();
    return super.close();
  }

  Future<void> _onBillCreated(
    LivingToolsBillCreated event,
    Emitter<LivingToolsState> emit,
  ) async {
    final result = await createBill(CreateBillParams(bill: event.bill));

    result.fold(
      (failure) => emit(state.copyWith(
        status: LivingToolsStatus.error,
        errorMessage: failure.message,
      )),
      (bill) {
        final updatedBills = [...state.bills, bill];
        emit(state.copyWith(
          status: LivingToolsStatus.loaded,
          bills: updatedBills,
        ));
      },
    );
  }

  Future<void> _onBillDeleted(
    LivingToolsBillDeleted event,
    Emitter<LivingToolsState> emit,
  ) async {
    final result = await deleteBill(DeleteBillParams(id: event.billId));

    result.fold(
      (failure) => emit(state.copyWith(
        status: LivingToolsStatus.error,
        errorMessage: failure.message,
      )),
      (_) {
        final updatedBills = state.bills.where((b) => b.id != event.billId).toList();
        emit(state.copyWith(
          status: LivingToolsStatus.loaded,
          bills: updatedBills,
        ));
      },
    );
  }

  Future<void> _onBillMarkedAsPaid(
    LivingToolsBillMarkedAsPaid event,
    Emitter<LivingToolsState> emit,
  ) async {
    final result = await markBillAsPaid(
      MarkBillAsPaidParams(billId: event.billId, memberId: event.memberId),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: LivingToolsStatus.error,
        errorMessage: failure.message,
      )),
      (_) {
        final updatedBills = state.bills.map((bill) {
          if (bill.id == event.billId) {
            final updatedMembers = bill.members.map((m) {
              if (m.id == event.memberId) {
                return BillMember(
                  id: m.id,
                  userId: m.userId,
                  userName: m.userName,
                  share: m.share,
                  hasPaid: true,
                  paidAt: DateTime.now(),
                );
              }
              return m;
            }).toList();

            final allPaid = updatedMembers.every((m) => m.hasPaid);

            return Bill(
              id: bill.id,
              chatRoomId: bill.chatRoomId,
              type: bill.type,
              title: bill.title,
              amount: bill.amount,
              dueDate: bill.dueDate,
              status: allPaid ? BillStatus.paid : bill.status,
              members: updatedMembers,
              isRecurring: bill.isRecurring,
              recurringInterval: bill.recurringInterval,
              createdBy: bill.createdBy,
              createdAt: bill.createdAt,
            );
          }
          return bill;
        }).toList();

        emit(state.copyWith(
          status: LivingToolsStatus.loaded,
          bills: updatedBills,
        ));
      },
    );
  }

  void _onTabChanged(
    LivingToolsTabChanged event,
    Emitter<LivingToolsState> emit,
  ) {
    emit(state.copyWith(selectedTab: event.tabIndex));
  }
}
