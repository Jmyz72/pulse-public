import '../../domain/entities/bill.dart';
import 'bill_member_model.dart';

class BillModel extends Bill {
  const BillModel({
    required super.id,
    required super.chatRoomId,
    required super.type,
    required super.title,
    super.description,
    required super.amount,
    required super.dueDate,
    required super.status,
    required super.members,
    super.isRecurring,
    super.recurringInterval,
    required super.createdBy,
    required super.createdAt,
    super.paymentDetails,
  });

  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      id: json['id'] ?? '',
      chatRoomId: json['chatRoomId'] ?? '',
      type: _parseBillType(json['type']),
      title: json['title'] ?? '',
      description: json['description'],
      amount: (json['amount'] ?? 0).toDouble(),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'])
          : DateTime.now(),
      status: _parseBillStatus(json['status']),
      members: (json['members'] as List<dynamic>?)
              ?.map((m) => BillMemberModel.fromJson(m))
              .toList() ??
          [],
      isRecurring: json['isRecurring'] ?? false,
      recurringInterval: json['recurringInterval'],
      createdBy: json['createdBy'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      paymentDetails: _parsePaymentDetails(json['paymentDetails']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatRoomId': chatRoomId,
      'type': type.name,
      'title': title,
      'description': description,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'status': status.name,
      'members': members.map((m) => BillMemberModel.fromEntity(m).toJson()).toList(),
      'isRecurring': isRecurring,
      'recurringInterval': recurringInterval,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'paymentDetails': paymentDetails != null
          ? {
              'bankName': paymentDetails!.bankName,
              'accountName': paymentDetails!.accountName,
              'accountNumber': paymentDetails!.accountNumber,
              'duitNowId': paymentDetails!.duitNowId,
              'qrImageUrl': paymentDetails!.qrImageUrl,
            }
          : null,
    };
  }

  factory BillModel.fromEntity(Bill bill) {
    return BillModel(
      id: bill.id,
      chatRoomId: bill.chatRoomId,
      type: bill.type,
      title: bill.title,
      description: bill.description,
      amount: bill.amount,
      dueDate: bill.dueDate,
      status: bill.status,
      members: bill.members.map(BillMemberModel.fromEntity).toList(),
      isRecurring: bill.isRecurring,
      recurringInterval: bill.recurringInterval,
      createdBy: bill.createdBy,
      createdAt: bill.createdAt,
      paymentDetails: bill.paymentDetails,
    );
  }

  static BillPaymentDetails? _parsePaymentDetails(dynamic json) {
    if (json == null) return null;
    return BillPaymentDetails(
      bankName: json['bankName'],
      accountName: json['accountName'],
      accountNumber: json['accountNumber'],
      duitNowId: json['duitNowId'],
      qrImageUrl: json['qrImageUrl'],
    );
  }

  static BillType _parseBillType(String? type) {
    switch (type) {
      case 'rent':
        return BillType.rent;
      case 'utilities':
        return BillType.utilities;
      case 'internet':
        return BillType.internet;
      case 'cleaning':
        return BillType.cleaning;
      case 'water':
        return BillType.water;
      default:
        return BillType.other;
    }
  }

  static BillStatus _parseBillStatus(String? status) {
    switch (status) {
      case 'paid':
        return BillStatus.paid;
      case 'overdue':
        return BillStatus.overdue;
      default:
        return BillStatus.pending;
    }
  }
}
