import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/home/domain/entities/dashboard_data.dart';
import 'package:pulse/features/home/presentation/screens/home_tabs/home_tab.dart';

void main() {
  const friends = FriendsSummary(
    friendCount: 4,
    friends: [
      MemberSummary(
        id: 'friend-1',
        name: 'Alice',
        avatarInitial: 'A',
        isOnline: true,
      ),
      MemberSummary(
        id: 'friend-2',
        name: 'Bob',
        avatarInitial: 'B',
        isOnline: true,
      ),
    ],
  );

  Widget buildSubject({
    required int aroundNowCount,
    required HomeHeroAroundNowMode aroundNowMode,
    int pendingTasksCount = 2,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: HomeTab(
          friends: friends,
          unreadNotificationsCount: 0,
          recentActivities: const [],
          pendingTasksCount: pendingTasksCount,
          upcomingEventsCount: 0,
          groceryItemsCount: 0,
          aroundNowCount: aroundNowCount,
          aroundNowMode: aroundNowMode,
          onViewAllActivities: () {},
          onRefresh: () async {},
        ),
      ),
    );
  }

  Future<void> pumpHero(WidgetTester tester, Widget widget) async {
    await tester.pumpWidget(widget);
    await tester.pump(const Duration(milliseconds: 700));
  }

  int countMatches(Iterable<String> options) {
    return options
        .where(
          (text) => find.text(text, skipOffstage: false).evaluate().isNotEmpty,
        )
        .length;
  }

  testWidgets('shows around now label and nearby copy in nearby mode', (
    tester,
  ) async {
    await pumpHero(
      tester,
      buildSubject(
        aroundNowCount: 2,
        aroundNowMode: HomeHeroAroundNowMode.nearby,
      ),
    );

    expect(find.text('Around now', skipOffstage: false), findsOneWidget);
    expect(find.text('Online now', skipOffstage: false), findsNothing);
    expect(find.text('2', skipOffstage: false), findsWidgets);
    expect(
      countMatches([
        '2 of 4 are within 5 km right now, so this is a good time to clear things up.',
        'Some of your group is physically nearby, and a few items are waiting.',
        'People are close by if you want to sort something out quickly.',
      ]),
      greaterThan(0),
    );
  });

  testWidgets('shows online now label and online copy in fallback mode', (
    tester,
  ) async {
    await pumpHero(
      tester,
      buildSubject(
        aroundNowCount: 3,
        aroundNowMode: HomeHeroAroundNowMode.onlineFallback,
      ),
    );

    expect(find.text('Online now', skipOffstage: false), findsOneWidget);
    expect(find.text('Around now', skipOffstage: false), findsNothing);
    expect(find.text('3', skipOffstage: false), findsWidgets);
    expect(
      countMatches([
        '3 of 4 are online, so this is a good time to clear things up.',
        'Your group is active right now, and a few items are waiting.',
        'People are around if you want to close the loop quickly.',
      ]),
      greaterThan(0),
    );
  });
}
