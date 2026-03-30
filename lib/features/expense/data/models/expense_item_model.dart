import '../../domain/entities/expense_item.dart';

class ExpenseItemModel extends ExpenseItem {
  const ExpenseItemModel({
    required super.id,
    required super.name,
    required super.price,
    super.quantity,
    super.assignedUserIds,
  });

  factory ExpenseItemModel.fromJson(Map<String, dynamic> json) {
    return ExpenseItemModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      assignedUserIds: (json['assignedUserIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'assignedUserIds': assignedUserIds,
    };
  }

  factory ExpenseItemModel.fromEntity(ExpenseItem item) {
    return ExpenseItemModel(
      id: item.id,
      name: item.name,
      price: item.price,
      quantity: item.quantity,
      assignedUserIds: item.assignedUserIds,
    );
  }
}
