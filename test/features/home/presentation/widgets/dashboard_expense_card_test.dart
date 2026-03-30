import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/home/presentation/widgets/dashboard_expense_card.dart';
import 'package:pulse/shared/widgets/glass_card.dart';

void main() {
  Widget buildSubject({
    double totalExpenses = 1234.56,
    double userShare = 308.00,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: DashboardExpenseCard(
          totalExpenses: totalExpenses,
          userShare: userShare,
          onTap: () {},
        ),
      ),
    );
  }

  group('DashboardExpenseCard', () {
    testWidgets('renders EXPENSES header', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('EXPENSES'), findsOneWidget);
    });

    testWidgets('renders total and user share values', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('RM 1234.56'), findsOneWidget);
      expect(find.text('RM 308.00'), findsOneWidget);
    });

    testWidgets('renders Total and Your Share labels', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Your Share'), findsOneWidget);
    });

    testWidgets('renders GlassContainer', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.byType(GlassContainer), findsOneWidget);
    });

    testWidgets('renders wallet and person icons', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.byIcon(Icons.account_balance_wallet), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('is tappable', (tester) async {
      var tapped = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DashboardExpenseCard(
            totalExpenses: 100.0,
            userShare: 50.0,
            onTap: () => tapped = true,
          ),
        ),
      ));

      await tester.tap(find.byType(DashboardExpenseCard));
      expect(tapped, isTrue);
    });

    testWidgets('shows zero values correctly', (tester) async {
      await tester.pumpWidget(buildSubject(
        totalExpenses: 0.0,
        userShare: 0.0,
      ));

      expect(find.text('RM 0.00'), findsNWidgets(2));
    });
  });
}
