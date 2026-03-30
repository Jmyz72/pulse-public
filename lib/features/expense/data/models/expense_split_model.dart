import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/expense_split.dart';

class ExpenseSplitModel extends ExpenseSplit {
  const ExpenseSplitModel({
    required super.userId,
    required super.userName,
    required super.amount,
    super.itemIds,
    super.isPaid,
    super.paymentStatus,
    super.paidAt,
    super.hasSelectedItems,
    super.proofImageUrl,
    super.proofSubmittedAt,
    super.proofReviewedAt,
    super.proofReviewedBy,
    super.proofRejectionReason,
    super.matchedAmount,
    super.matchedRecipient,
    super.matchConfidence,
  });

  factory ExpenseSplitModel.fromJson(Map<String, dynamic> json) {
    final legacyIsPaid = json['isPaid'] == true;
    final parsedStatus = _parsePaymentStatus(json['paymentStatus'] as String?);

    return ExpenseSplitModel(
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      itemIds:
          (json['itemIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isPaid: legacyIsPaid,
      paymentStatus:
          parsedStatus ??
          (legacyIsPaid
              ? ExpensePaymentStatus.paid
              : ExpensePaymentStatus.unpaid),
      paidAt: _parseDateTime(json['paidAt']),
      hasSelectedItems: json['hasSelectedItems'] ?? false,
      proofImageUrl: json['proofImageUrl'] as String?,
      proofSubmittedAt: _parseDateTime(json['proofSubmittedAt']),
      proofReviewedAt: _parseDateTime(json['proofReviewedAt']),
      proofReviewedBy: json['proofReviewedBy'] as String?,
      proofRejectionReason: json['proofRejectionReason'] as String?,
      matchedAmount: (json['matchedAmount'] as num?)?.toDouble(),
      matchedRecipient: json['matchedRecipient'] as String?,
      matchConfidence: (json['matchConfidence'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'amount': amount,
      'itemIds': itemIds,
      'isPaid': isPaid,
      'paymentStatus': paymentStatus.name,
      'paidAt': paidAt?.toIso8601String(),
      'hasSelectedItems': hasSelectedItems,
      'proofImageUrl': proofImageUrl,
      'proofSubmittedAt': proofSubmittedAt?.toIso8601String(),
      'proofReviewedAt': proofReviewedAt?.toIso8601String(),
      'proofReviewedBy': proofReviewedBy,
      'proofRejectionReason': proofRejectionReason,
      'matchedAmount': matchedAmount,
      'matchedRecipient': matchedRecipient,
      'matchConfidence': matchConfidence,
    };
  }

  factory ExpenseSplitModel.fromEntity(ExpenseSplit split) {
    return ExpenseSplitModel(
      userId: split.userId,
      userName: split.userName,
      amount: split.amount,
      itemIds: split.itemIds,
      isPaid: split.isPaid,
      paymentStatus: split.paymentStatus,
      paidAt: split.paidAt,
      hasSelectedItems: split.hasSelectedItems,
      proofImageUrl: split.proofImageUrl,
      proofSubmittedAt: split.proofSubmittedAt,
      proofReviewedAt: split.proofReviewedAt,
      proofReviewedBy: split.proofReviewedBy,
      proofRejectionReason: split.proofRejectionReason,
      matchedAmount: split.matchedAmount,
      matchedRecipient: split.matchedRecipient,
      matchConfidence: split.matchConfidence,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static ExpensePaymentStatus? _parsePaymentStatus(String? value) {
    switch (value) {
      case 'proofSubmitted':
        return ExpensePaymentStatus.proofSubmitted;
      case 'paid':
        return ExpensePaymentStatus.paid;
      case 'proofRejected':
        return ExpensePaymentStatus.proofRejected;
      case 'unpaid':
        return ExpensePaymentStatus.unpaid;
      default:
        return null;
    }
  }
}
