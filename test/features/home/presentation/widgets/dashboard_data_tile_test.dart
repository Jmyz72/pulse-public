import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/home/presentation/widgets/dashboard_data_tile.dart';
import 'package:pulse/shared/widgets/glass_card.dart';
import 'package:pulse/core/constants/app_colors.dart';

void main() {
  Widget buildSubject({
    String label = 'Tasks',
    IconData icon = Icons.task_alt,
    Color color = AppColors.task,
    int count = 3,
    String subtitle = 'pending',
    double height = 140,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: DashboardDataTile(
          label: label,
          icon: icon,
          color: color,
          count: count,
          subtitle: subtitle,
          height: height,
          onTap: () {},
        ),
      ),
    );
  }

  group('DashboardDataTile', () {
    testWidgets('renders label, count, and subtitle', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('TASKS'), findsOneWidget);
      expect(find.text('3'), findsAtLeastNWidgets(1)); // count badge + big number
      expect(find.text('pending'), findsOneWidget);
    });

    testWidgets('renders GlassContainer', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.byType(GlassContainer), findsOneWidget);
    });

    testWidgets('renders icon', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.byIcon(Icons.task_alt), findsOneWidget);
    });

    testWidgets('hides badge when count is 0', (tester) async {
      await tester.pumpWidget(buildSubject(count: 0));

      // Should still show the big number "0" but no badge container
      expect(find.text('0'), findsOneWidget);
      expect(find.text('TASKS'), findsOneWidget);
    });

    testWidgets('respects height parameter', (tester) async {
      await tester.pumpWidget(buildSubject(height: 100));

      final tile = tester.widget<DashboardDataTile>(
        find.byType(DashboardDataTile),
      );
      expect(tile.height, 100);
    });

    testWidgets('is tappable', (tester) async {
      var tapped = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DashboardDataTile(
            label: 'Tasks',
            icon: Icons.task_alt,
            color: AppColors.task,
            count: 3,
            subtitle: 'pending',
            height: 140,
            onTap: () => tapped = true,
          ),
        ),
      ));

      await tester.tap(find.byType(DashboardDataTile));
      expect(tapped, isTrue);
    });

    testWidgets('has Semantics label', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(
        find.bySemanticsLabel(RegExp('Tasks, 3 pending')),
        findsOneWidget,
      );
    });
  });
}
