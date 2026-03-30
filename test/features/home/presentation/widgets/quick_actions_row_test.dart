import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/constants/app_routes.dart';
import 'package:pulse/features/auth/domain/entities/user.dart';
import 'package:pulse/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse/features/chat/domain/entities/message.dart';
import 'package:pulse/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:pulse/features/friends/presentation/bloc/friend_bloc.dart';
import 'package:pulse/features/friends/presentation/bloc/friend_event.dart';
import 'package:pulse/features/friends/presentation/bloc/friend_state.dart';
import 'package:pulse/features/home/presentation/widgets/quick_actions_row.dart';
import 'package:pulse/shared/widgets/glass_card.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockChatBloc extends MockBloc<ChatEvent, ChatState> implements ChatBloc {}

class MockFriendBloc extends MockBloc<FriendEvent, FriendState>
    implements FriendBloc {}

class FakeAuthEvent extends Fake implements AuthEvent {}

class FakeChatEvent extends Fake implements ChatEvent {}

class FakeFriendEvent extends Fake implements FriendEvent {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockChatBloc mockChatBloc;
  late MockFriendBloc mockFriendBloc;

  const tUser = User(
    id: 'u1',
    username: 'jimmy',
    displayName: 'Jimmy Hew',
    email: 'jimmy@test.com',
    phone: '+60123456789',
  );

  final tChatRooms = [
    ChatRoom(
      id: 'room-1',
      name: 'Room 1',
      members: const ['u1', 'u2', 'u3'],
      createdAt: DateTime(2026, 1, 1),
      isGroup: true,
    ),
    ChatRoom(
      id: 'room-2',
      name: 'Room 2',
      members: const ['u1', 'u2'],
      createdAt: DateTime(2026, 1, 2),
    ),
  ];

  setUpAll(() {
    registerFallbackValue(FakeAuthEvent());
    registerFallbackValue(FakeChatEvent());
    registerFallbackValue(FakeFriendEvent());
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockChatBloc = MockChatBloc();
    mockFriendBloc = MockFriendBloc();

    when(() => mockAuthBloc.state).thenReturn(
      const AuthState(status: AuthStatus.authenticated, user: tUser),
    );
    whenListen(
      mockAuthBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthState(
        status: AuthStatus.authenticated,
        user: tUser,
      ),
    );

    when(
      () => mockChatBloc.state,
    ).thenReturn(ChatState(status: ChatStatus.loaded, chatRooms: tChatRooms));
    whenListen(
      mockChatBloc,
      const Stream<ChatState>.empty(),
      initialState: ChatState(status: ChatStatus.loaded, chatRooms: tChatRooms),
    );

    when(
      () => mockFriendBloc.state,
    ).thenReturn(const FriendState(friendsStatus: FriendLoadStatus.loaded));
    whenListen(
      mockFriendBloc,
      const Stream<FriendState>.empty(),
      initialState: const FriendState(friendsStatus: FriendLoadStatus.loaded),
    );
  });

  Widget buildSubject({
    void Function(Map<String, dynamic>? args)? onAddExpense,
    VoidCallback? onAddFriend,
  }) {
    return MaterialApp(
      routes: {
        AppRoutes.addExpense: (context) {
          onAddExpense?.call(
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?,
          );
          return const Scaffold(body: Text('add-expense'));
        },
        AppRoutes.addFriend: (context) {
          onAddFriend?.call();
          return const Scaffold(body: Text('add-friend'));
        },
        AppRoutes.timetable: (_) => const Scaffold(body: Text('timetable')),
      },
      home: Scaffold(
        body: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            BlocProvider<ChatBloc>.value(value: mockChatBloc),
            BlocProvider<FriendBloc>.value(value: mockFriendBloc),
          ],
          child: const QuickActionsRow(),
        ),
      ),
    );
  }

  group('QuickActionsRow', () {
    testWidgets('renders 4 action buttons', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.byType(GlassContainer), findsNWidgets(4));
    });

    testWidgets('renders all labels', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Add Friend'), findsOneWidget);
      expect(find.text('New Chat'), findsOneWidget);
      expect(find.text('Schedule'), findsOneWidget);
    });

    testWidgets('renders all icons', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.byIcon(Icons.add_card), findsOneWidget);
      expect(find.byIcon(Icons.person_add_alt_1), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets(
      'Expense button navigates to /add-expense with chatRooms args',
      (tester) async {
        Map<String, dynamic>? addExpenseArgs;
        await tester.pumpWidget(
          buildSubject(onAddExpense: (args) => addExpenseArgs = args),
        );

        await tester.tap(find.text('Expense'));
        await tester.pumpAndSettle();

        expect(find.text('add-expense'), findsOneWidget);
        final chatRooms = addExpenseArgs?['chatRooms'] as List<ChatRoom>?;
        expect(chatRooms, isNotNull);
        expect(chatRooms!.map((room) => room.id).toList(), [
          'room-1',
          'room-2',
        ]);
      },
    );

    testWidgets('Add Friend button navigates to /friends/add', (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.tap(find.text('Add Friend'));
      await tester.pumpAndSettle();

      expect(find.text('add-friend'), findsOneWidget);
    });

    testWidgets('New Chat button opens new chat sheet', (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.tap(find.text('New Chat'));
      await tester.pumpAndSettle();

      expect(find.text('Search friends...'), findsOneWidget);
      expect(find.text('Add friends to start chatting'), findsOneWidget);
    });

    testWidgets('Schedule button navigates to /timetable', (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();

      expect(find.text('timetable'), findsOneWidget);
    });

    testWidgets('has Semantics labels for each button', (tester) async {
      await tester.pumpWidget(buildSubject());

      // Check that Semantics widgets exist for each action
      expect(find.bySemanticsLabel(RegExp('Expense')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Add Friend')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('New Chat')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Schedule')), findsOneWidget);
    });
  });
}
