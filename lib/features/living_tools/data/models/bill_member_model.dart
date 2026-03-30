import '../../domain/entities/bill.dart';

class BillMemberModel extends BillMember {
  const BillMemberModel({
    required super.id,
    required super.userId,
    required super.userName,
    required super.share,
    super.hasPaid,
    super.paidAt,
    super.lastNudgedAt,
    super.paymentStatus,
    super.proofImageUrl,
    super.transactionRef,
  });

  factory BillMemberModel.fromJson(Map<String, dynamic> json) {
    return BillMemberModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      share: (json['share'] ?? 0).toDouble(),
      hasPaid: json['hasPaid'] ?? false,
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      lastNudgedAt: json['lastNudgedAt'] != null ? DateTime.parse(json['lastNudgedAt']) : null,
      paymentStatus: _parsePaymentStatus(json['paymentStatus']),
      proofImageUrl: json['proofImageUrl'],
      transactionRef: json['transactionRef'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'share': share,
      'hasPaid': hasPaid,
      'paidAt': paidAt?.toIso8601String(),
      'lastNudgedAt': lastNudgedAt?.toIso8601String(),
      'paymentStatus': paymentStatus.name,
      'proofImageUrl': proofImageUrl,
      'transactionRef': transactionRef,
    };
  }

  factory BillMemberModel.fromEntity(BillMember member) {
    return BillMemberModel(
      id: member.id,
      userId: member.userId,
      userName: member.userName,
      share: member.share,
      hasPaid: member.hasPaid,
      paidAt: member.paidAt,
      lastNudgedAt: member.lastNudgedAt,
      paymentStatus: member.paymentStatus,
      proofImageUrl: member.proofImageUrl,
      transactionRef: member.transactionRef,
    );
  }

  static BillPaymentStatus _parsePaymentStatus(String? status) {
    if (status == null) return BillPaymentStatus.none;
    return BillPaymentStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => BillPaymentStatus.none,
    );
  }
}
