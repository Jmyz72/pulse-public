import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/friends/presentation/bloc/friend_bloc.dart';
import 'package:pulse/features/friends/presentation/bloc/friend_event.dart';
import 'package:pulse/features/friends/presentation/bloc/friend_state.dart';
import 'package:pulse/features/friends/presentation/screens/user_profile_screen.dart';

class MockFriendBloc extends MockBloc<FriendEvent, FriendState>
    implements FriendBloc {}

class FakeFriendEvent extends Fake implements FriendEvent {}

void main() {
  late MockFriendBloc mockFriendBloc;

  setUpAll(() {
    registerFallbackValue(FakeFriendEvent());
  });

  setUp(() {
    mockFriendBloc = MockFriendBloc();
    when(() => mockFriendBloc.state).thenReturn(const FriendState());
    when(() => mockFriendBloc.add(any())).thenReturn(null);
    whenListen(
      mockFriendBloc,
      const Stream<FriendState>.empty(),
      initialState: const FriendState(),
    );
  });

  Widget buildSubject(UserProfileScreen child) {
    return MaterialApp(
      home: BlocProvider<FriendBloc>.value(value: mockFriendBloc, child: child),
    );
  }

  testWidgets('shows connected state for an existing friend', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        const UserProfileScreen(
          name: 'Alex Friend',
          username: 'alex',
          email: 'alex@test.com',
          phone: '+1987654321',
          profileContext: ProfileContext.searchResult,
          isFriend: true,
        ),
      ),
    );

    expect(find.text('Relationship status'), findsOneWidget);
    expect(find.text('Already connected'), findsOneWidget);
    expect(find.text('Friends'), findsWidgets);
  });

  testWidgets('dispatches accept event from pending request actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        const UserProfileScreen(
          name: 'Requester One',
          username: 'requester',
          email: 'requester@test.com',
          phone: '+1234567890',
          profileContext: ProfileContext.pendingRequest,
          friendshipId: 'friendship-1',
          currentUserId: 'user-123',
        ),
      ),
    );

    final acceptFinder = find.text('Accept');
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(acceptFinder);
    await tester.pump();

    verify(
      () => mockFriendBloc.add(
        const FriendRequestAcceptRequested('friendship-1', userId: 'user-123'),
      ),
    ).called(1);
  });
}
