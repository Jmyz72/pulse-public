import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/expense/domain/entities/expense_item.dart';
import 'package:pulse/features/expense/presentation/widgets/expense_item_card.dart';

void main() {
  Widget buildSubject({
    required ExpenseItem item,
    List<String> selectedByNames = const [],
    List<String> paidByNames = const [],
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ExpenseItemCard(
          item: item,
          selectedByNames: selectedByNames,
          paidByNames: paidByNames,
        ),
      ),
    );
  }

  const item = ExpenseItem(
    id: 'item-1',
    name: 'Nasi Goreng Pattaya',
    price: 9.0,
    quantity: 1,
    assignedUserIds: ['user-1', 'user-2'],
  );

  testWidgets('shows selected and paid user names', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        item: item,
        selectedByNames: const ['Jimmy', 'Alice'],
        paidByNames: const ['Jimmy'],
      ),
    );

    expect(find.text('Selected by Jimmy, Alice'), findsNothing);
    expect(find.text('Paid by Jimmy'), findsOneWidget);
    expect(find.text('2 people selected'), findsNothing);
  });

  testWidgets('hides selected and paid labels when no names are provided', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject(item: item));

    expect(find.textContaining('Selected by'), findsNothing);
    expect(find.textContaining('Paid by'), findsNothing);
  });
}
