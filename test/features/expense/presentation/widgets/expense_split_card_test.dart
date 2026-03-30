import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/expense/domain/entities/expense_split.dart';
import 'package:pulse/features/expense/presentation/widgets/expense_split_card.dart';

void main() {
  testWidgets('renders without overflow on narrow widths', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: ExpenseSplitCard(
              split: ExpenseSplit(
                userId: 'user-1',
                userName: 'Hew Mann Jie With A Very Long Name',
                amount: 26.84,
                itemIds: ['1', '2'],
                hasSelectedItems: true,
              ),
              isCurrentUser: true,
              isOwner: true,
              isExpenseOwner: true,
              isPending: true,
              hasItems: true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Hew Mann Jie With A Very Long Name'), findsOneWidget);
    expect(find.text('Owner'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
