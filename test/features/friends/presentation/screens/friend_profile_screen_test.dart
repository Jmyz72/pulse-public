import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/auth/domain/entities/user.dart';
import 'package:pulse/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse/features/friends/domain/entities/friend_profile_stats.dart';
import 'package:pulse/features/friends/domain/entities/friendship.dart';
import 'package:pulse/features/friends/presentation/bloc/friend_bloc.dart';
import 'package:pulse/features/friends/presentation/bloc/friend_event.dart';
import 'package:pulse/features/friends/presentation/bloc/friend_state.dart';
import 'package:pulse/features/friends/presentation/screens/friend_profile_screen.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockFriendBloc extends MockBloc<FriendEvent, FriendState>
    implements FriendBloc {}

class FakeAuthEvent extends Fake implements AuthEvent {}

class FakeFriendEvent extends Fake implements FriendEvent {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockFriendBloc mockFriendBloc;

  const tUser = User(
    id: 'user-123',
    username: 'jimmy',
    displayName: 'Jimmy Hew',
    email: 'jimmy@test.com',
    phone: '+1234567890',
  );

  final tFriendship = Friendship(
    id: 'friendship-1',
    userId: tUser.id,
    friendId: 'friend-123',
    friendUsername: 'alex',
    friendDisplayName: 'Alex Friend',
    friendEmail: 'alex@test.com',
    friendPhone: '+1987654321',
    friendPhotoUrl: '',
    requesterUsername: tUser.username,
    requesterDisplayName: tUser.displayName,
    requesterEmail: tUser.email,
    requesterPhone: tUser.phone,
    status: FriendshipStatus.accepted,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 2),
  );

  setUpAll(() {
    registerFallbackValue(FakeAuthEvent());
    registerFallbackValue(FakeFriendEvent());
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockFriendBloc = MockFriendBloc();

    when(() => mockAuthBloc.state).thenReturn(
      const AuthState(status: AuthStatus.authenticated, user: tUser),
    );
    when(() => mockFriendBloc.state).thenReturn(const FriendState());
    when(() => mockFriendBloc.add(any())).thenReturn(null);

    whenListen(
      mockAuthBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthState(
        status: AuthStatus.authenticated,
        user: tUser,
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
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<FriendBloc>.value(value: mockFriendBloc),
        ],
        child: FriendProfileScreen(friendship: tFriendship),
      ),
    );
  }

  testWidgets(
    'does not render header network image for empty friend photo URL',
    (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 300));

      final hasNetworkImage = tester
          .widgetList<Image>(find.byType(Image))
          .any((image) => image.image is NetworkImage);

      expect(hasNetworkImage, isFalse);
    },
  );

  testWidgets('renders stats from state instead of hardcoded values', (
    tester,
  ) async {
    const tStats = FriendProfileStats(
      mutualRoomsCount: 17,
      mutualFriendsCount: 23,
      isOnline: false,
    );

    when(() => mockFriendBloc.state).thenReturn(
      const FriendState(
        profileStatsStatus: FriendLoadStatus.loaded,
        friendProfileStats: tStats,
      ),
    );
    whenListen(
      mockFriendBloc,
      const Stream<FriendState>.empty(),
      initialState: const FriendState(
        profileStatsStatus: FriendLoadStatus.loaded,
        friendProfileStats: tStats,
      ),
    );

    await tester.pumpWidget(buildSubject());
    await tester.pump(const Duration(milliseconds: 300));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -450));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('17'), findsOneWidget);
    expect(find.text('23'), findsOneWidget);
    expect(find.text('Quick actions'), findsNothing);
    expect(find.text('Friends for'), findsNothing);
    expect(find.text('Status'), findsNothing);
  });
}
