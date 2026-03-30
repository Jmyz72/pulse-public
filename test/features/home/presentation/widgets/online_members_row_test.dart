import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/home/domain/entities/dashboard_data.dart';
import 'package:pulse/features/home/presentation/widgets/online_members_row.dart';
import 'package:pulse/features/home/presentation/widgets/member_avatar_card.dart';
import 'package:pulse/shared/widgets/glass_card.dart';

void main() {
  final tMembers = [
    const MemberSummary(
      id: '1',
      name: 'Alice Smith',
      avatarInitial: 'A',
      isOnline: true,
    ),
    const MemberSummary(
      id: '2',
      name: 'Bob Jones',
      avatarInitial: 'B',
      isOnline: false,
    ),
    const MemberSummary(
      id: '3',
      name: 'Charlie Brown',
      avatarInitial: 'C',
      isOnline: true,
    ),
  ];

  Widget buildSubject({
    List<MemberSummary> members = const [],
    VoidCallback? onSeeAll,
    VoidCallback? onAddFriends,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: OnlineMembersRow(
            members: members,
            onSeeAll: onSeeAll,
            onAddFriends: onAddFriends,
          ),
        ),
      ),
    );
  }

  group('OnlineMembersRow', () {
    testWidgets('does not render ONLINE FRIENDS header text', (tester) async {
      await tester.pumpWidget(buildSubject(members: tMembers));

      expect(find.text('ONLINE FRIENDS'), findsNothing);
    });

    testWidgets('renders GlassContainer', (tester) async {
      await tester.pumpWidget(buildSubject(members: tMembers));

      expect(find.byType(GlassContainer), findsOneWidget);
    });

    testWidgets('shows online count badge', (tester) async {
      await tester.pumpWidget(buildSubject(members: tMembers));

      expect(find.text('2 Online Friends'), findsOneWidget);
    });

    testWidgets('renders MemberAvatarCard for each member', (tester) async {
      await tester.pumpWidget(buildSubject(members: tMembers));

      expect(find.byType(MemberAvatarCard), findsNWidgets(3));
    });

    testWidgets('passes photoUrl to avatar cards', (tester) async {
      const photoUrl = 'https://example.com/avatar.jpg';
      await tester.pumpWidget(
        buildSubject(
          members: const [
            MemberSummary(
              id: '1',
              name: 'Alice Smith',
              avatarInitial: 'A',
              photoUrl: photoUrl,
              isOnline: true,
            ),
          ],
        ),
      );

      final card = tester.widget<MemberAvatarCard>(
        find.byType(MemberAvatarCard),
      );
      expect(card.imageUrl, photoUrl);
    });

    testWidgets('sorts online members first', (tester) async {
      await tester.pumpWidget(buildSubject(members: tMembers));

      final cards = tester
          .widgetList<MemberAvatarCard>(find.byType(MemberAvatarCard))
          .toList();

      // Online members should come first
      expect(cards[0].isOnline, isTrue);
      expect(cards[1].isOnline, isTrue);
      expect(cards[2].isOnline, isFalse);
    });

    testWidgets('uses compact mode for avatars', (tester) async {
      await tester.pumpWidget(buildSubject(members: tMembers));

      final cards = tester.widgetList<MemberAvatarCard>(
        find.byType(MemberAvatarCard),
      );

      for (final card in cards) {
        expect(card.compact, isTrue);
      }
    });

    testWidgets('shows empty state when no members', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('No friends yet'), findsOneWidget);
      expect(find.byType(MemberAvatarCard), findsNothing);
    });

    testWidgets('shows 0 Online Friends when no one is online', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          members: const [
            MemberSummary(
              id: '1',
              name: 'Alice',
              avatarInitial: 'A',
              isOnline: false,
            ),
          ],
        ),
      );

      expect(find.text('0 Online Friends'), findsOneWidget);
    });

    testWidgets('shows See All button when onSeeAll is provided', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        buildSubject(members: tMembers, onSeeAll: () => tapped = true),
      );

      final seeAll = find.text('See All');
      expect(seeAll, findsOneWidget);

      await tester.tap(seeAll);
      expect(tapped, isTrue);
    });

    testWidgets('hides See All button when onSeeAll is null', (tester) async {
      await tester.pumpWidget(buildSubject(members: tMembers));

      expect(find.text('See All'), findsNothing);
    });

    testWidgets(
      'shows Add Friend button in empty state when onAddFriends is provided',
      (tester) async {
        var tapped = false;
        await tester.pumpWidget(
          buildSubject(onAddFriends: () => tapped = true),
        );

        expect(find.text('No friends yet'), findsOneWidget);
        final addButton = find.text('Add Friend');
        expect(addButton, findsOneWidget);

        await tester.tap(addButton);
        expect(tapped, isTrue);
      },
    );

    testWidgets(
      'hides Add Friend button in empty state when onAddFriends is null',
      (tester) async {
        await tester.pumpWidget(buildSubject());

        expect(find.text('No friends yet'), findsOneWidget);
        expect(find.text('Add Friend'), findsNothing);
      },
    );
  });
}
