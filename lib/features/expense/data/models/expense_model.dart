import '../../domain/entities/expense.dart';
import 'expense_item_model.dart';
import 'expense_split_model.dart';

class ExpenseModel extends Expense {
  const ExpenseModel({
    required super.id,
    required super.ownerId,
    super.chatRoomId,
    required super.title,
    super.description,
    required super.totalAmount,
    required super.date,
    super.status,
    super.type,
    super.items,
    super.taxPercent,
    super.serviceChargePercent,
    super.discountPercent,
    super.splits,
    super.masterExpenseId,
    super.linkedExpenseIds,
    super.adHocParticipantIds,
    super.imageUrl,
    super.ownerPaymentIdentity,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] ?? '',
      ownerId: json['ownerId'] ?? json['userId'] ?? '',
      chatRoomId: json['chatRoomId'],
      title: json['title'] ?? '',
      description: json['description'],
      totalAmount: (json['totalAmount'] ?? json['amount'] ?? 0).toDouble(),
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      status: _parseExpenseStatus(json['status']),
      type: _parseExpenseType(json['type']),
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => ExpenseItemModel.fromJson(item))
              .toList() ??
          [],
      taxPercent: (json['taxPercent'] as num?)?.toDouble(),
      serviceChargePercent: (json['serviceChargePercent'] as num?)?.toDouble(),
      discountPercent: (json['discountPercent'] as num?)?.toDouble(),
      splits:
          (json['splits'] as List<dynamic>?)
              ?.map((split) => ExpenseSplitModel.fromJson(split))
              .toList() ??
          [],
      masterExpenseId: json['masterExpenseId'],
      linkedExpenseIds: (json['linkedExpenseIds'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      adHocParticipantIds: (json['adHocParticipantIds'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      imageUrl: json['imageUrl'],
      ownerPaymentIdentity: json['ownerPaymentIdentity'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'chatRoomId': chatRoomId,
      'title': title,
      'description': description,
      'totalAmount': totalAmount,
      'date': date.toIso8601String(),
      'status': status.name,
      'type': type.name,
      'items': items
          .map((item) => ExpenseItemModel.fromEntity(item).toJson())
          .toList(),
      'taxPercent': taxPercent,
      'serviceChargePercent': serviceChargePercent,
      'discountPercent': discountPercent,
      'splits': splits
          .map((split) => ExpenseSplitModel.fromEntity(split).toJson())
          .toList(),
      'masterExpenseId': masterExpenseId,
      'linkedExpenseIds': linkedExpenseIds,
      'adHocParticipantIds': adHocParticipantIds,
      'imageUrl': imageUrl,
      'ownerPaymentIdentity': ownerPaymentIdentity,
    };
  }

  factory ExpenseModel.fromEntity(Expense expense) {
    return ExpenseModel(
      id: expense.id,
      ownerId: expense.ownerId,
      chatRoomId: expense.chatRoomId,
      title: expense.title,
      description: expense.description,
      totalAmount: expense.totalAmount,
      date: expense.date,
      status: expense.status,
      type: expense.type,
      items: expense.items,
      taxPercent: expense.taxPercent,
      serviceChargePercent: expense.serviceChargePercent,
      discountPercent: expense.discountPercent,
      splits: expense.splits,
      masterExpenseId: expense.masterExpenseId,
      linkedExpenseIds: expense.linkedExpenseIds,
      adHocParticipantIds: expense.adHocParticipantIds,
      imageUrl: expense.imageUrl,
      ownerPaymentIdentity: expense.ownerPaymentIdentity,
    );
  }

  static ExpenseStatus _parseExpenseStatus(String? status) {
    switch (status) {
      case 'settled':
        return ExpenseStatus.settled;
      case 'pending':
      default:
        return ExpenseStatus.pending;
    }
  }

  static ExpenseType _parseExpenseType(String? type) {
    switch (type) {
      case 'oneOnOne':
        return ExpenseType.oneOnOne;
      case 'adHoc':
        return ExpenseType.adHoc;
      case 'group':
      default:
        return ExpenseType.group;
    }
  }
}
