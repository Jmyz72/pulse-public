import 'package:equatable/equatable.dart';

import 'expense_item.dart';
import 'expense_split.dart';

/// Expense types based on context
enum ExpenseType {
  /// Group chat with 3+ members (e.g., housemates splitting rent)
  group,

  /// Private chat between 2 people (e.g., lunch with one friend)
  oneOnOne,

  /// Multiple friends with no common group (e.g., dinner with friends from different circles)
  adHoc,
}

/// Expense status
enum ExpenseStatus {
  /// Expense is pending settlement
  pending,

  /// Expense is fully settled (all members have paid)
  settled,
}

class Expense extends Equatable {
  final String id;
  final String ownerId;
  final String? chatRoomId;
  final String title;
  final String? description;
  final double totalAmount;
  final DateTime date;
  final ExpenseStatus status;
  final ExpenseType type;

  // Items
  final List<ExpenseItem> items;
  final double? taxPercent;
  final double? serviceChargePercent;
  final double? discountPercent;

  // Splits
  final List<ExpenseSplit> splits;

  // Ad-hoc linking
  final String? masterExpenseId;
  final List<String>? linkedExpenseIds;
  final List<String>? adHocParticipantIds;

  // Receipt image
  final String? imageUrl;
  final String? ownerPaymentIdentity;

  const Expense({
    required this.id,
    required this.ownerId,
    this.chatRoomId,
    required this.title,
    this.description,
    required this.totalAmount,
    required this.date,
    this.status = ExpenseStatus.pending,
    this.type = ExpenseType.group,
    this.items = const [],
    this.taxPercent,
    this.serviceChargePercent,
    this.discountPercent,
    this.splits = const [],
    this.masterExpenseId,
    this.linkedExpenseIds,
    this.adHocParticipantIds,
    this.imageUrl,
    this.ownerPaymentIdentity,
  });

  /// Calculate the subtotal from all items
  double get itemsSubtotal => items.fold(0, (sum, item) => sum + item.subtotal);

  /// Calculate tax amount
  double get taxAmount =>
      taxPercent != null ? itemsSubtotal * (taxPercent! / 100) : 0;

  /// Calculate service charge amount
  double get serviceChargeAmount => serviceChargePercent != null
      ? itemsSubtotal * (serviceChargePercent! / 100)
      : 0;

  /// Calculate discount amount
  double get discountAmount =>
      discountPercent != null ? itemsSubtotal * (discountPercent! / 100) : 0;

  /// Calculate the total amount from items with adjustments
  double get calculatedTotal =>
      itemsSubtotal + taxAmount + serviceChargeAmount - discountAmount;

  /// Check if this is the master record for ad-hoc expense
  bool get isAdHocMaster =>
      type == ExpenseType.adHoc && masterExpenseId == null;

  /// Check if this is a linked record for ad-hoc expense
  bool get isAdHocLinked =>
      type == ExpenseType.adHoc && masterExpenseId != null;

  /// Check if all items are assigned
  bool get allItemsAssigned =>
      items.isEmpty || items.every((item) => item.assignedUserIds.isNotEmpty);

  /// Check if all splits are paid
  bool get allSplitsPaid =>
      splits.isEmpty || splits.every((split) => split.isPaid);

  /// Count of paid splits
  int get paidSplitsCount => splits.where((split) => split.isPaid).length;

  /// Progress string (e.g., "2/4 paid")
  String get paymentProgress => '$paidSplitsCount/${splits.length} paid';

  Expense copyWith({
    String? id,
    String? ownerId,
    String? chatRoomId,
    bool clearChatRoomId = false,
    String? title,
    String? description,
    bool clearDescription = false,
    double? totalAmount,
    DateTime? date,
    ExpenseStatus? status,
    ExpenseType? type,
    List<ExpenseItem>? items,
    double? taxPercent,
    bool clearTaxPercent = false,
    double? serviceChargePercent,
    bool clearServiceChargePercent = false,
    double? discountPercent,
    bool clearDiscountPercent = false,
    List<ExpenseSplit>? splits,
    String? masterExpenseId,
    bool clearMasterExpenseId = false,
    List<String>? linkedExpenseIds,
    bool clearLinkedExpenseIds = false,
    List<String>? adHocParticipantIds,
    bool clearAdHocParticipantIds = false,
    String? imageUrl,
    bool clearImageUrl = false,
    String? ownerPaymentIdentity,
    bool clearOwnerPaymentIdentity = false,
  }) {
    return Expense(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      chatRoomId: clearChatRoomId ? null : (chatRoomId ?? this.chatRoomId),
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      totalAmount: totalAmount ?? this.totalAmount,
      date: date ?? this.date,
      status: status ?? this.status,
      type: type ?? this.type,
      items: items ?? this.items,
      taxPercent: clearTaxPercent ? null : (taxPercent ?? this.taxPercent),
      serviceChargePercent: clearServiceChargePercent
          ? null
          : (serviceChargePercent ?? this.serviceChargePercent),
      discountPercent: clearDiscountPercent
          ? null
          : (discountPercent ?? this.discountPercent),
      splits: splits ?? this.splits,
      masterExpenseId: clearMasterExpenseId
          ? null
          : (masterExpenseId ?? this.masterExpenseId),
      linkedExpenseIds: clearLinkedExpenseIds
          ? null
          : (linkedExpenseIds ?? this.linkedExpenseIds),
      adHocParticipantIds: clearAdHocParticipantIds
          ? null
          : (adHocParticipantIds ?? this.adHocParticipantIds),
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      ownerPaymentIdentity: clearOwnerPaymentIdentity
          ? null
          : (ownerPaymentIdentity ?? this.ownerPaymentIdentity),
    );
  }

  @override
  List<Object?> get props => [
    id,
    ownerId,
    chatRoomId,
    title,
    description,
    totalAmount,
    date,
    status,
    type,
    items,
    taxPercent,
    serviceChargePercent,
    discountPercent,
    splits,
    masterExpenseId,
    linkedExpenseIds,
    adHocParticipantIds,
    imageUrl,
    ownerPaymentIdentity,
  ];
}
