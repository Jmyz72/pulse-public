import 'package:equatable/equatable.dart';

enum ExpensePaymentStatus { unpaid, proofSubmitted, paid, proofRejected }

class ExpenseSplit extends Equatable {
  final String userId;
  final String userName;
  final double amount;
  final List<String> itemIds;
  final ExpensePaymentStatus paymentStatus;
  final DateTime? paidAt;
  final bool hasSelectedItems;
  final String? proofImageUrl;
  final DateTime? proofSubmittedAt;
  final DateTime? proofReviewedAt;
  final String? proofReviewedBy;
  final String? proofRejectionReason;
  final double? matchedAmount;
  final String? matchedRecipient;
  final double? matchConfidence;

  const ExpenseSplit({
    required this.userId,
    required this.userName,
    required this.amount,
    this.itemIds = const [],
    bool isPaid = false,
    ExpensePaymentStatus? paymentStatus,
    this.paidAt,
    this.hasSelectedItems = false,
    this.proofImageUrl,
    this.proofSubmittedAt,
    this.proofReviewedAt,
    this.proofReviewedBy,
    this.proofRejectionReason,
    this.matchedAmount,
    this.matchedRecipient,
    this.matchConfidence,
  }) : paymentStatus =
           paymentStatus ??
           (isPaid ? ExpensePaymentStatus.paid : ExpensePaymentStatus.unpaid);

  bool get isPaid => paymentStatus == ExpensePaymentStatus.paid;

  bool get needsReview => paymentStatus == ExpensePaymentStatus.proofSubmitted;

  bool get isRejected => paymentStatus == ExpensePaymentStatus.proofRejected;

  bool get locksItemSelection => isPaid || needsReview;

  ExpenseSplit copyWith({
    String? userId,
    String? userName,
    double? amount,
    List<String>? itemIds,
    bool? isPaid,
    ExpensePaymentStatus? paymentStatus,
    DateTime? paidAt,
    bool clearPaidAt = false,
    bool? hasSelectedItems,
    String? proofImageUrl,
    bool clearProofImageUrl = false,
    DateTime? proofSubmittedAt,
    bool clearProofSubmittedAt = false,
    DateTime? proofReviewedAt,
    bool clearProofReviewedAt = false,
    String? proofReviewedBy,
    bool clearProofReviewedBy = false,
    String? proofRejectionReason,
    bool clearProofRejectionReason = false,
    double? matchedAmount,
    bool clearMatchedAmount = false,
    String? matchedRecipient,
    bool clearMatchedRecipient = false,
    double? matchConfidence,
    bool clearMatchConfidence = false,
  }) {
    final resolvedPaymentStatus =
        paymentStatus ??
        (isPaid != null
            ? (isPaid ? ExpensePaymentStatus.paid : ExpensePaymentStatus.unpaid)
            : this.paymentStatus);

    return ExpenseSplit(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      amount: amount ?? this.amount,
      itemIds: itemIds ?? this.itemIds,
      isPaid: isPaid ?? this.isPaid,
      paymentStatus: resolvedPaymentStatus,
      paidAt: clearPaidAt ? null : (paidAt ?? this.paidAt),
      hasSelectedItems: hasSelectedItems ?? this.hasSelectedItems,
      proofImageUrl: clearProofImageUrl
          ? null
          : (proofImageUrl ?? this.proofImageUrl),
      proofSubmittedAt: clearProofSubmittedAt
          ? null
          : (proofSubmittedAt ?? this.proofSubmittedAt),
      proofReviewedAt: clearProofReviewedAt
          ? null
          : (proofReviewedAt ?? this.proofReviewedAt),
      proofReviewedBy: clearProofReviewedBy
          ? null
          : (proofReviewedBy ?? this.proofReviewedBy),
      proofRejectionReason: clearProofRejectionReason
          ? null
          : (proofRejectionReason ?? this.proofRejectionReason),
      matchedAmount: clearMatchedAmount
          ? null
          : (matchedAmount ?? this.matchedAmount),
      matchedRecipient: clearMatchedRecipient
          ? null
          : (matchedRecipient ?? this.matchedRecipient),
      matchConfidence: clearMatchConfidence
          ? null
          : (matchConfidence ?? this.matchConfidence),
    );
  }

  @override
  List<Object?> get props => [
    userId,
    userName,
    amount,
    itemIds,
    paymentStatus,
    paidAt,
    hasSelectedItems,
    proofImageUrl,
    proofSubmittedAt,
    proofReviewedAt,
    proofReviewedBy,
    proofRejectionReason,
    matchedAmount,
    matchedRecipient,
    matchConfidence,
  ];
}
