import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/auth/domain/entities/user.dart';
import 'package:pulse/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse/features/friends/domain/entities/friendship.dart';
import 'package:pulse/features/friends/presentation/bloc/friend_bloc.dart';
import 'package:pulse/features/friends/presentation/bloc/friend_event.dart';
import 'package:pulse/features/friends/presentation/bloc/friend_state.dart';
import 'package:pulse/features/friends/presentation/screens/friends_screen.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockFriendBloc extends MockBloc<FriendEvent, FriendState>
    implements FriendBloc {}

class FakeAuthEvent extends Fake implements AuthEvent {}

class FakeFriendEvent extends Fake implements FriendEvent {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockFriendBloc mockFriendBloc;

  const tCurrentUser = User(
    id: 'user-123',
    username: 'jimmy',
    displayName: 'Jimmy Hew',
    email: 'jimmy@test.com',
    phone: '+1234567890',
  );

  final tFriend = Friendship(
    id: 'friendship-1',
    userId: 'user-123',
    friendId: 'friend-1',
    friendUsername: 'friend_one',
    friendDisplayName: 'Friend One',
    friendEmail: 'friend@test.com',
    friendPhone: '+111111111',
    requesterUsername: 'jimmy',
    requesterDisplayName: 'Jimmy Hew',
    requesterEmail: 'jimmy@test.com',
    requesterPhone: '+1234567890',
    status: FriendshipStatus.accepted,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 2),
  );

  final tRequest = Friendship(
    id: 'request-1',
    userId: 'requester-1',
    friendId: 'user-123',
    friendUsername: 'jimmy',
    friendDisplayName: 'Jimmy Hew',
    friendEmail: 'jimmy@test.com',
    friendPhone: '+1234567890',
    requesterUsername: 'requester_one',
    requesterDisplayName: 'Requester One',
    requesterEmail: 'requester@test.com',
    requesterPhone: '+222222222',
    status: FriendshipStatus.pending,
    createdAt: DateTime(2024, 2, 1),
    updatedAt: DateTime(2024, 2, 1),
  );

  final tSentRequest = Friendship(
    id: 'sent-1',
    userId: 'user-123',
    friendId: 'friend-2',
    friendUsername: 'sent_one',
    friendDisplayName: 'Sent One',
    friendEmail: 'sent@test.com',
    friendPhone: '+333333333',
    requesterUsername: 'jimmy',
    requesterDisplayName: 'Jimmy Hew',
    requesterEmail: 'jimmy@test.com',
    requesterPhone: '+1234567890',
    status: FriendshipStatus.pending,
    createdAt: DateTime(2024, 2, 3),
    updatedAt: DateTime(2024, 2, 3),
  );

  setUpAll(() {
    registerFallbackValue(FakeAuthEvent());
    registerFallbackValue(FakeFriendEvent());
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockFriendBloc = MockFriendBloc();

    when(() => mockAuthBloc.state).thenReturn(
      const AuthState(status: AuthStatus.authenticated, user: tCurrentUser),
    );
    when(() => mockFriendBloc.state).thenReturn(const FriendState());
    when(() => mockFriendBloc.add(any())).thenReturn(null);

    whenListen(
      mockAuthBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthState(
        status: AuthStatus.authenticated,
        user: tCurrentUser,
      ),
    );
    whenListen(
      mockFriendBloc,
      const Stream<FriendState>.empty(),
      initialState: const FriendState(),
    );
  });

  Widget buildSubject() {
    return MaterialApp(
      onGenerateRoute: (_) =>
          MaterialPageRoute<void>(builder: (_) => const SizedBox.shrink()),
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<FriendBloc>.value(value: mockFriendBloc),
        ],
        child: const FriendsScreen(),
      ),
    );
  }

  testWidgets('loads friends and requests when screen opens', (tester) async {
    await tester.pumpWidget(buildSubject());

    verify(
      () => mockFriendBloc.add(const FriendsLoadRequested('user-123')),
    ).called(1);
    verify(
      () => mockFriendBloc.add(const PendingRequestsLoadRequested('user-123')),
    ).called(1);
  });

  testWidgets('shows summary header and friend cards by default', (
    tester,
  ) async {
    final state = FriendState(
      friendsStatus: FriendLoadStatus.loaded,
      requestsStatus: FriendLoadStatus.loaded,
      friends: [tFriend],
      pendingRequests: [tRequest],
      sentRequests: [tRequest],
    );

    when(() => mockFriendBloc.state).thenReturn(state);
    whenListen(
      mockFriendBloc,
      Stream<FriendState>.fromIterable([state]),
      initialState: state,
    );

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('friends_header_card')), findsOneWidget);
    expect(find.text('Friend One'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('Incoming'), findsWidgets);
    expect(find.text('Sent'), findsOneWidget);
  });

  testWidgets('switches to requests section when tapped', (tester) async {
    final state = FriendState(
      friendsStatus: FriendLoadStatus.loaded,
      requestsStatus: FriendLoadStatus.loaded,
      friends: [tFriend],
      pendingRequests: [tRequest],
      sentRequests: [tSentRequest],
    );

    when(() => mockFriendBloc.state).thenReturn(state);
    whenListen(
      mockFriendBloc,
      Stream<FriendState>.fromIterable([state]),
      initialState: state,
    );

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    final finder = find.byKey(const Key('requests_section_button'));
    await tester.ensureVisible(finder);
    final rect = tester.getRect(finder);
    await tester.tapAt(Offset(rect.left + 24, rect.top + 24));
    await tester.pumpAndSettle();

    expect(find.text('Requester One'), findsOneWidget);
    expect(find.text('Incoming'), findsWidgets);
    expect(find.text('Sent'), findsWidgets);
    expect(find.text('Sent One'), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Friend One'), findsNothing);
  });
}
