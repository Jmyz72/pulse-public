import 'package:equatable/equatable.dart';

class GroceryItem extends Equatable {
  final String id;
  final String name;
  final String? brand;
  final String? size;
  final String? variant;
  final int quantity;
  final String? note;
  final String? imageUrl;
  final bool isPurchased;
  final String? category;
  final String chatRoomId;
  final String addedBy;
  final String? addedByName;
  final String? purchasedBy;
  final String? purchasedByName;
  final DateTime createdAt;

  const GroceryItem({
    required this.id,
    required this.name,
    this.brand,
    this.size,
    this.variant,
    required this.quantity,
    this.note,
    this.imageUrl,
    this.isPurchased = false,
    this.category,
    required this.chatRoomId,
    required this.addedBy,
    this.addedByName,
    this.purchasedBy,
    this.purchasedByName,
    required this.createdAt,
  });

  GroceryItem copyWith({
    String? id,
    String? name,
    String? brand,
    bool clearBrand = false,
    String? size,
    bool clearSize = false,
    String? variant,
    bool clearVariant = false,
    int? quantity,
    String? note,
    bool clearNote = false,
    String? imageUrl,
    bool clearImageUrl = false,
    bool? isPurchased,
    String? category,
    bool clearCategory = false,
    String? chatRoomId,
    String? addedBy,
    String? addedByName,
    bool clearAddedByName = false,
    String? purchasedBy,
    bool clearPurchasedBy = false,
    String? purchasedByName,
    bool clearPurchasedByName = false,
    DateTime? createdAt,
  }) {
    return GroceryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: clearBrand ? null : (brand ?? this.brand),
      size: clearSize ? null : (size ?? this.size),
      variant: clearVariant ? null : (variant ?? this.variant),
      quantity: quantity ?? this.quantity,
      note: clearNote ? null : (note ?? this.note),
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      isPurchased: isPurchased ?? this.isPurchased,
      category: clearCategory ? null : (category ?? this.category),
      chatRoomId: chatRoomId ?? this.chatRoomId,
      addedBy: addedBy ?? this.addedBy,
      addedByName: clearAddedByName ? null : (addedByName ?? this.addedByName),
      purchasedBy: clearPurchasedBy ? null : (purchasedBy ?? this.purchasedBy),
      purchasedByName: clearPurchasedByName
          ? null
          : (purchasedByName ?? this.purchasedByName),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    brand,
    size,
    variant,
    quantity,
    note,
    imageUrl,
    isPurchased,
    category,
    chatRoomId,
    addedBy,
    addedByName,
    purchasedBy,
    purchasedByName,
    createdAt,
  ];
}
