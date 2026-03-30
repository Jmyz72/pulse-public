part of 'living_tools_bloc.dart';

abstract class LivingToolsEvent extends Equatable {
  const LivingToolsEvent();

  @override
  List<Object?> get props => [];
}

class LivingToolsLoadRequested extends LivingToolsEvent {
  final String userId;
  final List<String> chatRoomIds;

  const LivingToolsLoadRequested({
    required this.userId,
    required this.chatRoomIds,
  });

  @override
  List<Object> get props => [userId, chatRoomIds];
}

class LivingToolsBillCreated extends LivingToolsEvent {
  final Bill bill;

  const LivingToolsBillCreated({required this.bill});

  @override
  List<Object> get props => [bill];
}

class LivingToolsBillDeleted extends LivingToolsEvent {
  final String billId;

  const LivingToolsBillDeleted({required this.billId});

  @override
  List<Object> get props => [billId];
}

class LivingToolsBillMarkedAsPaid extends LivingToolsEvent {
  final String billId;
  final String memberId;

  const LivingToolsBillMarkedAsPaid({
    required this.billId,
    required this.memberId,
  });

  @override
  List<Object> get props => [billId, memberId];
}

class LivingToolsBillPaymentProofUploaded extends LivingToolsEvent {
  final String billId;
  final String memberId;
  final String proofImageUrl;
  final String? transactionRef;

  const LivingToolsBillPaymentProofUploaded({
    required this.billId,
    required this.memberId,
    required this.proofImageUrl,
    this.transactionRef,
  });

  @override
  List<Object?> get props => [billId, memberId, proofImageUrl, transactionRef];
}

class LivingToolsBillPaymentStatusUpdated extends LivingToolsEvent {
  final String billId;
  final String memberId;
  final BillPaymentStatus status;

  const LivingToolsBillPaymentStatusUpdated({
    required this.billId,
    required this.memberId,
    required this.status,
  });

  @override
  List<Object> get props => [billId, memberId, status];
}

class LivingToolsBillMemberNudged extends LivingToolsEvent {
  final String billId;
  final String memberId;

  const LivingToolsBillMemberNudged({
    required this.billId,
    required this.memberId,
  });

  @override
  List<Object> get props => [billId, memberId];
}

class LivingToolsBillsUpdated extends LivingToolsEvent {
  final List<Bill> bills;

  const LivingToolsBillsUpdated({required this.bills});

  @override
  List<Object> get props => [bills];
}

class LivingToolsTabChanged extends LivingToolsEvent {
  final int tabIndex;

  const LivingToolsTabChanged({required this.tabIndex});

  @override
  List<Object> get props => [tabIndex];
}
