import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/chat/presentation/widgets/special_message_cards.dart';

void main() {
  Widget buildSubject(Map<String, dynamic> message) {
    return MaterialApp(
      home: Scaffold(body: GroceryMessageCard(message: message, isMe: false)),
    );
  }

  testWidgets('renders enriched grocery item details', (tester) async {
    await tester.pumpWidget(
      buildSubject({
        'senderName': 'Jimmy',
        'timestamp': DateTime(2026, 3, 14, 10, 0),
        'grocery': {
          'items': [
            {
              'name': 'Milk',
              'quantity': 2,
              'brand': 'Dutch Lady',
              'size': '2L',
              'variant': 'Low fat',
              'category': 'Dairy',
              'note': 'Blue cap only',
            },
          ],
        },
      }),
    );

    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Dutch Lady • 2L • Low fat • Dairy'), findsOneWidget);
    expect(find.text('Blue cap only'), findsOneWidget);
    expect(find.text('x2'), findsOneWidget);
  });

  testWidgets('renders legacy grocery payload quantity strings', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject({
        'senderName': 'Jimmy',
        'timestamp': DateTime(2026, 3, 14, 10, 0),
        'grocery': {
          'items': [
            {'name': 'Eggs', 'quantity': 'x12'},
          ],
        },
      }),
    );

    expect(find.text('Eggs'), findsOneWidget);
    expect(find.text('x12'), findsOneWidget);
  });
}
