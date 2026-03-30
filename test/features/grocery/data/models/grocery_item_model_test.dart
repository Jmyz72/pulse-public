import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/grocery/data/models/grocery_item_model.dart';
import 'package:pulse/features/grocery/domain/entities/grocery_item.dart';

void main() {
  final tDate = DateTime(2024, 1, 1);

  test(
    'fromJson should support legacy grocery documents without new fields',
    () {
      final model = GroceryItemModel.fromJson({
        'id': 'item-1',
        'name': 'Milk',
        'quantity': 2,
        'chatRoomId': 'chat-1',
        'addedBy': 'user-1',
        'createdAt': tDate.toIso8601String(),
      });

      expect(model.brand, isNull);
      expect(model.size, isNull);
      expect(model.variant, isNull);
      expect(model.imageUrl, isNull);
      expect(model.name, 'Milk');
    },
  );

  test('toJson should include enriched grocery fields', () {
    final model = GroceryItemModel(
      id: 'item-1',
      name: 'Milk',
      brand: 'Dutch Lady',
      size: '2L',
      variant: 'Low fat',
      quantity: 2,
      note: 'Blue cap only',
      imageUrl: 'https://example.com/milk.jpg',
      category: 'Dairy',
      chatRoomId: 'chat-1',
      addedBy: 'user-1',
      createdAt: DateTime(2024, 1, 1),
    );

    final json = model.toJson();

    expect(json['brand'], 'Dutch Lady');
    expect(json['size'], '2L');
    expect(json['variant'], 'Low fat');
    expect(json['imageUrl'], 'https://example.com/milk.jpg');
  });

  test('fromEntity should preserve enriched grocery fields', () {
    final entity = GroceryItem(
      id: 'item-1',
      name: 'Milk',
      brand: 'Dutch Lady',
      size: '2L',
      variant: 'Low fat',
      quantity: 2,
      note: 'Blue cap only',
      imageUrl: 'https://example.com/milk.jpg',
      category: 'Dairy',
      chatRoomId: 'chat-1',
      addedBy: 'user-1',
      createdAt: tDate,
    );

    final model = GroceryItemModel.fromEntity(entity);

    expect(model.brand, entity.brand);
    expect(model.size, entity.size);
    expect(model.variant, entity.variant);
    expect(model.imageUrl, entity.imageUrl);
  });
}
