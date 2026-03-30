import 'package:equatable/equatable.dart';

class ExpenseItem extends Equatable {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final List<String> assignedUserIds;

  const ExpenseItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.assignedUserIds = const [],
  });

  /// Calculate the subtotal for this item (price * quantity)
  double get subtotal => price * quantity;

  /// Calculate the cost per person for this item
  /// If no users are assigned, returns the full subtotal
  double get costPerPerson =>
      assignedUserIds.isEmpty ? subtotal : subtotal / assignedUserIds.length;

  /// Check if this item is assigned to anyone
  bool get isAssigned => assignedUserIds.isNotEmpty;

  /// Check if a specific user is assigned to this item
  bool isAssignedTo(String userId) => assignedUserIds.contains(userId);

  ExpenseItem copyWith({
    String? id,
    String? name,
    double? price,
    int? quantity,
    List<String>? assignedUserIds,
  }) {
    return ExpenseItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      assignedUserIds: assignedUserIds ?? this.assignedUserIds,
    );
  }

  @override
  List<Object?> get props => [id, name, price, quantity, assignedUserIds];
}
