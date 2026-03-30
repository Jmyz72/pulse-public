import 'package:equatable/equatable.dart';

import 'expense.dart';
import 'expense_item.dart';

class ExpenseParticipant extends Equatable {
  final String id;
  final String name;

  const ExpenseParticipant({required this.id, required this.name});

  @override
  List<Object> get props => [id, name];
}

class ExpenseSubmission extends Equatable {
  final String currentUserId;
  final String currentUserName;
  final String? ownerPaymentIdentity;
  final String title;
  final String description;
  final ExpenseType expenseType;
  final String? chatRoomId;
  final List<ExpenseParticipant> participants;
  final List<ExpenseItem> items;
  final double? manualAmount;
  final double? taxPercent;
  final double? serviceChargePercent;
  final double? discountPercent;
  final bool isCustomSplit;

  const ExpenseSubmission({
    required this.currentUserId,
    required this.currentUserName,
    this.ownerPaymentIdentity,
    required this.title,
    required this.description,
    required this.expenseType,
    this.chatRoomId,
    this.participants = const [],
    this.items = const [],
    this.manualAmount,
    this.taxPercent,
    this.serviceChargePercent,
    this.discountPercent,
    this.isCustomSplit = false,
  });

  bool get requiresChatRoom => expenseType != ExpenseType.adHoc;

  @override
  List<Object?> get props => [
    currentUserId,
    currentUserName,
    ownerPaymentIdentity,
    title,
    description,
    expenseType,
    chatRoomId,
    participants,
    items,
    manualAmount,
    taxPercent,
    serviceChargePercent,
    discountPercent,
    isCustomSplit,
  ];
}
