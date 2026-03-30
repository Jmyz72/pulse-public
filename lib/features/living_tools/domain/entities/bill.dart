import 'package:equatable/equatable.dart';

enum BillType { rent, utilities, internet, cleaning, water, other }
enum BillStatus { pending, paid, overdue }

/// Payment verification status for individual members
enum BillPaymentStatus {
  /// No payment or proof uploaded yet
  none,

  /// Proof uploaded, awaiting AI/Manual verification
  pending,

  /// Payment verified successfully
  verified,

  /// Payment rejected
  rejected,
}

/// Bank and DuitNow details for the bill recipient (who to pay)
class BillPaymentDetails extends Equatable {
  final String? bankName;
  final String? accountName;
  final String? accountNumber;
  final String? duitNowId; // Phone or IC
  final String? qrImageUrl;

  const BillPaymentDetails({
    this.bankName,
    this.accountName,
    this.accountNumber,
    this.duitNowId,
    this.qrImageUrl,
  });

  @override
  List<Object?> get props => [bankName, accountName, accountNumber, duitNowId, qrImageUrl];
}

class Bill extends Equatable {
  final String id;
  final String chatRoomId;
  final BillType type;
  final String title;
  final String? description;
  final double amount;
  final DateTime dueDate;
  final BillStatus status;
  final List<BillMember> members;
  final bool isRecurring;
  final String? recurringInterval;
  final String createdBy;
  final DateTime createdAt;

  // Payment details (who to pay)
  final BillPaymentDetails? paymentDetails;

  const Bill({
    required this.id,
    required this.chatRoomId,
    required this.type,
    required this.title,
    this.description,
    required this.amount,
    required this.dueDate,
    required this.status,
    required this.members,
    this.isRecurring = false,
    this.recurringInterval,
    required this.createdBy,
    required this.createdAt,
    this.paymentDetails,
  });

  double get totalPaid => members.where((m) => m.hasPaid).fold(0, (sum, m) => sum + m.share);
  double get totalOwed => amount - totalPaid;
  int get paidCount => members.where((m) => m.hasPaid).length;
  bool get isFullyPaid => members.every((m) => m.hasPaid);

  double getShareForUser(String userId) {
    final member = members.where((m) => m.userId == userId).firstOrNull;
    return member?.share ?? 0;
  }

  bool hasUserPaid(String userId) {
    final member = members.where((m) => m.userId == userId).firstOrNull;
    return member?.hasPaid ?? false;
  }

  Bill copyWith({
    String? id,
    String? chatRoomId,
    BillType? type,
    String? title,
    String? description,
    double? amount,
    DateTime? dueDate,
    BillStatus? status,
    List<BillMember>? members,
    bool? isRecurring,
    String? recurringInterval,
    String? createdBy,
    DateTime? createdAt,
    BillPaymentDetails? paymentDetails,
    bool clearPaymentDetails = false,
  }) {
    return Bill(
      id: id ?? this.id,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      members: members ?? this.members,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringInterval: recurringInterval ?? this.recurringInterval,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      paymentDetails: clearPaymentDetails ? null : (paymentDetails ?? this.paymentDetails),
    );
  }

  @override
  List<Object?> get props => [id, chatRoomId, type, title, description, amount, dueDate, status, members, isRecurring, paymentDetails];
}

class BillMember extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final double share;
  final bool hasPaid;
  final DateTime? paidAt;
  final DateTime? lastNudgedAt;

  // Fields for Payment Verification feature
  final BillPaymentStatus paymentStatus;
  final String? proofImageUrl;
  final String? transactionRef;

  const BillMember({
    required this.id,
    required this.userId,
    required this.userName,
    required this.share,
    this.hasPaid = false,
    this.paidAt,
    this.lastNudgedAt,
    this.paymentStatus = BillPaymentStatus.none,
    this.proofImageUrl,
    this.transactionRef,
  });

  BillMember copyWith({
    String? id,
    String? userId,
    String? userName,
    double? share,
    bool? hasPaid,
    DateTime? paidAt,
    DateTime? lastNudgedAt,
    BillPaymentStatus? paymentStatus,
    String? proofImageUrl,
    bool clearProofImageUrl = false,
    String? transactionRef,
    bool clearTransactionRef = false,
  }) {
    return BillMember(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      share: share ?? this.share,
      hasPaid: hasPaid ?? this.hasPaid,
      paidAt: paidAt ?? this.paidAt,
      lastNudgedAt: lastNudgedAt ?? this.lastNudgedAt,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      proofImageUrl: clearProofImageUrl ? null : (proofImageUrl ?? this.proofImageUrl),
      transactionRef: clearTransactionRef ? null : (transactionRef ?? this.transactionRef),
    );
  }

  @override
  List<Object?> get props => [id, userId, userName, share, hasPaid, paidAt, lastNudgedAt, paymentStatus, proofImageUrl, transactionRef];
}
