import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/constants/app_routes.dart';
import 'package:pulse/features/home/domain/entities/dashboard_data.dart';
import 'package:pulse/features/home/presentation/screens/home_tabs/activity_tab.dart';

void main() {
  final now = DateTime.now();
  final activities = [
    RecentActivity(
      id: 'expense:1',
      sourceId: 'expense-1',
      type: DashboardActivityType.expense,
      title: 'Dinner split',
      description: 'Alex added an expense',
      timestamp: now.subtract(const Duration(hours: 1)),
      chatRoomId: 'room-1',
      userId: 'user-1',
      userName: 'Alex',
    ),
    RecentActivity(
      id: 'bill:1',
      sourceId: 'bill-1',
      type: DashboardActivityType.bill,
      title: 'Internet bill',
      description: 'RM 129.00',
      timestamp: now.subtract(const Duration(days: 1)),
      chatRoomId: 'room-1',
    ),
    RecentActivity(
      id: 'chat:1',
      sourceId: 'room-2',
      type: DashboardActivityType.chat,
      title: 'Housemates',
      description: 'Jamie: Can someone grab milk?',
      timestamp: now.subtract(const Duration(days: 10)),
      chatRoomId: 'room-2',
      userId: 'user-2',
      userName: 'Jamie',
    ),
  ];

  Widget buildSubject({
    List<RecentActivity>? items,
    bool isLoading = false,
    String? errorMessage,
  }) {
    return MaterialApp(
      routes: {
        AppRoutes.tasks: (_) => const Scaffold(body: Text('Tasks Screen')),
        AppRoutes.livingTools: (_) =>
            const Scaffold(body: Text('Bills Screen')),
        AppRoutes.grocery: (_) => const Scaffold(body: Text('Grocery Screen')),
        AppRoutes.groupChat: (_) =>
            const Scaffold(body: Text('Group Chat Screen')),
      },
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.expenseDetails) {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (_) =>
                Scaffold(body: Text('Expense ${args?['expenseId']}')),
          );
        }
        return null;
      },
      home: Scaffold(
        body: ActivityTab(
          activities: items ?? activities,
          onRefresh: () async {},
          isLoading: isLoading,
          errorMessage: errorMessage,
        ),
      ),
    );
  }

  Future<void> pumpSettled(WidgetTester tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();
  }

  testWidgets('renders section headers for grouped shared activity', (
    tester,
  ) async {
    await pumpSettled(tester);

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('Older'), findsOneWidget);
  });

  testWidgets('shows filter counts in chip labels', (tester) async {
    await pumpSettled(tester);

    expect(find.text('All (3)'), findsOneWidget);
    expect(find.text('Bills (1)'), findsOneWidget);
    expect(find.text('Messages (1)'), findsOneWidget);
  });

  testWidgets('filters activity by selected chip', (tester) async {
    await pumpSettled(tester);

    await tester.tap(find.text('Bills (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Internet bill'), findsOneWidget);
    expect(find.text('Dinner split'), findsNothing);
    expect(find.text('Housemates'), findsNothing);
  });

  testWidgets('shows feed empty state when feed is empty', (tester) async {
    await tester.pumpWidget(buildSubject(items: const []));
    await tester.pumpAndSettle();

    expect(find.text('No household updates yet'), findsOneWidget);
  });

  testWidgets('shows filter-specific empty state', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        items: [
          RecentActivity(
            id: 'chat:1',
            sourceId: 'room-2',
            type: DashboardActivityType.chat,
            title: 'Housemates',
            description: 'Jamie: Can someone grab milk?',
            timestamp: now.subtract(const Duration(days: 10)),
            chatRoomId: 'room-2',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bills (0)'));
    await tester.pumpAndSettle();

    expect(find.text('No bills updates'), findsOneWidget);
  });

  testWidgets('opens expense details when expense activity is tapped', (
    tester,
  ) async {
    await pumpSettled(tester);

    await tester.tap(find.text('Dinner split'));
    await tester.pumpAndSettle();

    expect(find.text('Expense expense-1'), findsOneWidget);
  });
}
