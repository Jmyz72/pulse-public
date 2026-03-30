import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/grocery/presentation/widgets/grocery_summary_card.dart';

void main() {
  Widget buildSubject({
    required int totalItems,
    required int neededCount,
    required int purchasedCount,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: GrocerySummaryCard(
          totalItems: totalItems,
          neededCount: neededCount,
          purchasedCount: purchasedCount,
        ),
      ),
    );
  }

  testWidgets('renders summary card when grocery list is empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(totalItems: 0, neededCount: 0, purchasedCount: 0),
    );

    expect(find.text('Shopping List'), findsOneWidget);
    expect(find.text('0 items to buy'), findsOneWidget);
    expect(find.text('0 Needed'), findsOneWidget);
    expect(find.text('0 Done'), findsOneWidget);
  });

  testWidgets('shows total item count when grocery list has items', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(totalItems: 3, neededCount: 2, purchasedCount: 1),
    );

    expect(find.text('3 items total'), findsOneWidget);
    expect(find.text('2 items to buy'), findsOneWidget);
  });
}
