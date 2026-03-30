import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/constants/app_routes.dart';
import 'package:pulse/features/home/domain/entities/dashboard_data.dart';
import 'package:pulse/features/home/presentation/screens/home_tabs/home_tab.dart';
import 'package:pulse/features/home/presentation/widgets/dashboard_data_tile.dart';
import 'package:pulse/features/home/presentation/widgets/today_summary_card.dart';

void main() {
  const tUser = UserSummary(
    id: 'u1',
    name: 'Jimmy Hew',
    username: 'jimmy',
    email: 'jimmy@test.com',
    avatarInitial: 'J',
  );

  const tExpenses = ExpenseSummary(
    totalGroupExpenses: 1234.56,
    userShare: 308.00,
    pendingBillsCount: 4,
  );

  final tActivities = [
    RecentActivity(
      id: 'a1',
      sourceId: 'expense-1',
      type: DashboardActivityType.expense,
      title: 'Dinner',
      description: 'Split dinner bill',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      chatRoomId: 'room-1',
    ),
  ];

  Widget buildSubject({
    UserSummary? user = tUser,
    ExpenseSummary? expenses = tExpenses,
    int unreadNotificationsCount = 5,
    List<RecentActivity>? recentActivities,
    int pendingTasksCount = 3,
    int upcomingEventsCount = 2,
    int aroundNowCount = 0,
    HomeHeroAroundNowMode aroundNowMode = HomeHeroAroundNowMode.onlineFallback,
    VoidCallback? onViewAllActivities,
  }) {
    return MaterialApp(
      routes: {
        AppRoutes.notifications: (_) => const Scaffold(),
        AppRoutes.tasks: (_) => const Scaffold(),
        AppRoutes.livingTools: (_) => const Scaffold(),
        AppRoutes.events: (_) => const Scaffold(),
        AppRoutes.grocery: (_) => const Scaffold(),
        AppRoutes.addExpense: (_) => const Scaffold(),
        AppRoutes.groupChat: (_) => const Scaffold(),
        AppRoutes.timetable: (_) => const Scaffold(),
        AppRoutes.addFriend: (_) => const Scaffold(),
      },
      home: Scaffold(
        body: HomeTab(
          user: user,
          expenses: expenses,
          unreadNotificationsCount: unreadNotificationsCount,
          recentActivities: recentActivities ?? tActivities,
          pendingTasksCount: pendingTasksCount,
          upcomingEventsCount: upcomingEventsCount,
          groceryItemsCount: 0,
          aroundNowCount: aroundNowCount,
          aroundNowMode: aroundNowMode,
          onViewAllActivities: onViewAllActivities ?? () {},
          onRefresh: () async {},
        ),
      ),
    );
  }

  /// Pump enough frames to resolve stagger animations (6 groups x 100ms)
  Future<void> pumpStagger(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 700));
  }

  group('HomeTab', () {
    testWidgets('shows greeting with user first name', (tester) async {
      await tester.pumpWidget(buildSubject());
      await pumpStagger(tester);

      expect(find.text('Hello, Jimmy'), findsOneWidget);
    });

    testWidgets('shows formatted date in subtitle', (tester) async {
      await tester.pumpWidget(buildSubject());
      await pumpStagger(tester);

      // The date will be today's date - just check there's text with a day name
      final now = DateTime.now();
      const weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      expect(find.textContaining(weekdays[now.weekday - 1]), findsOneWidget);
    });

    testWidgets('shows notification badge', (tester) async {
      await tester.pumpWidget(buildSubject(unreadNotificationsCount: 5));
      await pumpStagger(tester);

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('renders today summary hero', (tester) async {
      await tester.pumpWidget(buildSubject());
      await pumpStagger(tester);

      expect(find.byType(TodaySummaryCard), findsOneWidget);
      expect(find.text('9 things need attention'), findsOneWidget);
    });

    testWidgets('renders DashboardDataTile for priority grid', (tester) async {
      await tester.pumpWidget(buildSubject());
      await pumpStagger(tester);

      // 4 tiles: Tasks, Bills, Events, Grocery
      expect(find.byType(DashboardDataTile), findsNWidgets(4));
      expect(find.text('TASKS'), findsOneWidget);
      expect(find.text('BILLS'), findsOneWidget);
    });

    testWidgets('does not render friends row or expense summary card', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await pumpStagger(tester);

      expect(find.text('Friends'), findsNothing);
      expect(find.text('RM 1234.56'), findsNothing);
      expect(find.text('RM 308.00'), findsNothing);
    });

    testWidgets('renders Events and Grocery tiles', (tester) async {
      await tester.pumpWidget(buildSubject());
      await pumpStagger(tester);

      expect(find.text('EVENTS'), findsOneWidget);
      expect(find.text('GROCERY'), findsOneWidget);
    });

    testWidgets('does not render quick actions section', (tester) async {
      await tester.pumpWidget(buildSubject());
      await pumpStagger(tester);

      expect(find.text('Quick actions', skipOffstage: false), findsNothing);
      expect(find.text('Quick add', skipOffstage: false), findsNothing);
    });

    testWidgets('renders latest updates section', (tester) async {
      await tester.pumpWidget(buildSubject());
      await pumpStagger(tester);

      expect(find.text('Latest updates', skipOffstage: false), findsOneWidget);
      expect(find.text('View All', skipOffstage: false), findsOneWidget);
    });

    testWidgets('invokes callback when View All is tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        buildSubject(onViewAllActivities: () => tapped = true),
      );
      await pumpStagger(tester);

      await tester.ensureVisible(find.text('View All', skipOffstage: false));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View All', skipOffstage: false));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('shows empty activity state when no activities', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(recentActivities: []));
      await pumpStagger(tester);

      expect(find.text('No updates yet', skipOffstage: false), findsOneWidget);
    });

    testWidgets('shows default user name when user is null', (tester) async {
      await tester.pumpWidget(buildSubject(user: null));
      await pumpStagger(tester);

      expect(find.text('Hello, User'), findsOneWidget);
    });

    testWidgets('limits preview to two activities', (tester) async {
      final threeActivities = [
        ...tActivities,
        RecentActivity(
          id: 'a2',
          sourceId: 'bill-1',
          type: DashboardActivityType.bill,
          title: 'Internet bill',
          description: 'RM 30 due',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        RecentActivity(
          id: 'a3',
          sourceId: 'task-1',
          type: DashboardActivityType.task,
          title: 'Kitchen cleanup',
          description: 'Task assigned',
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        ),
      ];

      await tester.pumpWidget(buildSubject(recentActivities: threeActivities));
      await pumpStagger(tester);

      await tester.ensureVisible(
        find.text('Latest updates', skipOffstage: false),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dinner'), findsOneWidget);
      expect(find.text('Internet bill'), findsOneWidget);
      expect(find.text('Kitchen cleanup'), findsNothing);
    });

    testWidgets('shows zero values when expenses is null', (tester) async {
      await tester.pumpWidget(buildSubject(expenses: null));
      await pumpStagger(tester);

      expect(find.text('5 things need attention'), findsOneWidget);
      expect(find.text('0'), findsWidgets);
    });
  });
}
