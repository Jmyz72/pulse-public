import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/grocery_item.dart';

class GroceryItemModel extends GroceryItem {
  const GroceryItemModel({
    required super.id,
    required super.name,
    super.brand,
    super.size,
    super.variant,
    required super.quantity,
    super.note,
    super.imageUrl,
    super.isPurchased,
    super.category,
    required super.chatRoomId,
    required super.addedBy,
    super.addedByName,
    super.purchasedBy,
    super.purchasedByName,
    required super.createdAt,
  });

  factory GroceryItemModel.fromJson(Map<String, dynamic> json) {
    return GroceryItemModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      brand: json['brand'],
      size: json['size'],
      variant: json['variant'],
      quantity: json['quantity'] ?? 1,
      note: json['note'],
      imageUrl: json['imageUrl'],
      isPurchased: json['isPurchased'] ?? false,
      category: json['category'],
      chatRoomId: json['chatRoomId'] ?? '',
      addedBy: json['addedBy'] ?? '',
      addedByName: json['addedByName'],
      purchasedBy: json['purchasedBy'],
      purchasedByName: json['purchasedByName'],
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'size': size,
      'variant': variant,
      'quantity': quantity,
      'note': note,
      'imageUrl': imageUrl,
      'isPurchased': isPurchased,
      'category': category,
      'chatRoomId': chatRoomId,
      'addedBy': addedBy,
      'addedByName': addedByName,
      'purchasedBy': purchasedBy,
      'purchasedByName': purchasedByName,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory GroceryItemModel.fromEntity(GroceryItem item) {
    return GroceryItemModel(
      id: item.id,
      name: item.name,
      brand: item.brand,
      size: item.size,
      variant: item.variant,
      quantity: item.quantity,
      note: item.note,
      imageUrl: item.imageUrl,
      isPurchased: item.isPurchased,
      category: item.category,
      chatRoomId: item.chatRoomId,
      addedBy: item.addedBy,
      addedByName: item.addedByName,
      purchasedBy: item.purchasedBy,
      purchasedByName: item.purchasedByName,
      createdAt: item.createdAt,
    );
  }
}
