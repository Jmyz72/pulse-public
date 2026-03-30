import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/constants/app_strings.dart';
import 'package:pulse/features/auth/domain/entities/user.dart';
import 'package:pulse/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse/features/chat/domain/entities/message.dart';
import 'package:pulse/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:pulse/features/chat/presentation/widgets/chat_tile.dart';
import 'package:pulse/features/friends/presentation/bloc/friend_bloc.dart';
import 'package:pulse/features/friends/presentation/bloc/friend_event.dart';
import 'package:pulse/features/friends/presentation/bloc/friend_state.dart';
import 'package:pulse/features/home/presentation/screens/home_tabs/chat_tab.dart';
import 'package:pulse/features/home/presentation/widgets/skeletons/chat_skeleton.dart';

class MockChatBloc extends MockBloc<ChatEvent, ChatState> implements ChatBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockFriendBloc extends MockBloc<FriendEvent, FriendState>
    implements FriendBloc {}

class FakeChatEvent extends Fake implements ChatEvent {}

void main() {
  late MockChatBloc mockChatBloc;
  late MockAuthBloc mockAuthBloc;
  late MockFriendBloc mockFriendBloc;

  setUpAll(() {
    registerFallbackValue(FakeChatEvent());
  });

  const tUser = User(
    id: 'user-1',
    username: 'john',
    displayName: 'John Doe',
    email: 'john@test.com',
    phone: '1234567890',
  );

  final tChatRooms = [
    ChatRoom(
      id: 'room-1',
      name: 'Room Alpha',
      members: const ['user-1', 'user-2'],
      createdAt: DateTime(2026, 1, 1),
      lastMessage: Message(
        id: 'msg-1',
        senderId: 'user-2',
        senderName: 'Jane',
        content: 'Hello',
        chatRoomId: 'room-1',
        timestamp: DateTime(2026, 1, 1, 12),
      ),
    ),
    ChatRoom(
      id: 'room-2',
      name: 'Room Beta',
      members: const ['user-1', 'user-3'],
      createdAt: DateTime(2026, 1, 2),
      isGroup: true,
    ),
  ];

  setUp(() {
    mockChatBloc = MockChatBloc();
    mockAuthBloc = MockAuthBloc();
    mockFriendBloc = MockFriendBloc();

    when(() => mockAuthBloc.state).thenReturn(
      const AuthState(
        status: AuthStatus.authenticated,
        user: tUser,
      ),
    );
    when(() => mockFriendBloc.state).thenReturn(const FriendState());
  });

  Widget buildSubject({required ChatState chatState}) {
    when(() => mockChatBloc.state).thenReturn(chatState);
    whenListen(
      mockChatBloc,
      const Stream<ChatState>.empty(),
      initialState: chatState,
    );

    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<ChatBloc>.value(value: mockChatBloc),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<FriendBloc>.value(value: mockFriendBloc),
        ],
        child: const Scaffold(
          body: ChatTab(onNewChat: _noOp),
        ),
      ),
    );
  }

  /// Pump enough frames to resolve stagger animations (3 groups x 100ms)
  Future<void> pumpStagger(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 500));
  }

  group('ChatTab', () {
    testWidgets('dispatches ChatRoomsWatchRequested on init',
        (tester) async {
      await tester.pumpWidget(buildSubject(
        chatState: const ChatState(status: ChatStatus.initial),
      ));
      await pumpStagger(tester);

      verify(() => mockChatBloc.add(any(that: isA<ChatRoomsWatchRequested>())))
          .called(1);
    });

    testWidgets('does NOT dispatch load when status is loaded',
        (tester) async {
      await tester.pumpWidget(buildSubject(
        chatState: ChatState(
          status: ChatStatus.loaded,
          chatRooms: tChatRooms,
        ),
      ));
      await pumpStagger(tester);

      verifyNever(
          () => mockChatBloc.add(any(that: isA<ChatRoomsLoadRequested>())));
    });

    testWidgets('shows ChatSkeleton on loading state', (tester) async {
      await tester.pumpWidget(buildSubject(
        chatState: const ChatState(status: ChatStatus.loading),
      ));
      // Use pump (not pumpAndSettle) — Shimmer animation never settles
      await pumpStagger(tester);

      expect(find.byType(ChatSkeleton), findsOneWidget);
    });

    testWidgets('shows error state with retry button', (tester) async {
      await tester.pumpWidget(buildSubject(
        chatState: const ChatState(
          status: ChatStatus.error,
          errorMessage: 'Network error',
        ),
      ));
      await pumpStagger(tester);

      expect(find.text(AppStrings.failedToLoadMessages), findsOneWidget);
      expect(find.text(AppStrings.retry), findsOneWidget);
    });

    testWidgets('retry button dispatches ChatRoomsLoadRequested',
        (tester) async {
      await tester.pumpWidget(buildSubject(
        chatState: const ChatState(
          status: ChatStatus.error,
          errorMessage: 'Network error',
        ),
      ));
      await pumpStagger(tester);

      clearInteractions(mockChatBloc);

      await tester.tap(find.text(AppStrings.retry));
      await tester.pump();

      verify(() => mockChatBloc.add(any(that: isA<ChatRoomsLoadRequested>())))
          .called(1);
    });

    testWidgets('shows empty state when no chat rooms', (tester) async {
      await tester.pumpWidget(buildSubject(
        chatState: const ChatState(
          status: ChatStatus.loaded,
          chatRooms: [],
        ),
      ));
      await pumpStagger(tester);

      expect(find.text(AppStrings.noConversations), findsOneWidget);
      expect(find.text(AppStrings.startNewChat), findsOneWidget);
    });

    testWidgets('shows chat room list on loaded state', (tester) async {
      await tester.pumpWidget(buildSubject(
        chatState: ChatState(
          status: ChatStatus.loaded,
          chatRooms: tChatRooms,
        ),
      ));
      await pumpStagger(tester);

      expect(find.byType(ChatTile), findsNWidgets(2));
      expect(find.text('Room Alpha'), findsOneWidget);
      expect(find.text('Room Beta'), findsOneWidget);
    });

    testWidgets('shows Messages header', (tester) async {
      await tester.pumpWidget(buildSubject(
        chatState: const ChatState(
          status: ChatStatus.loaded,
          chatRooms: [],
        ),
      ));
      await pumpStagger(tester);

      expect(find.text(AppStrings.messages), findsOneWidget);
    });

    testWidgets('search filters chat rooms by name', (tester) async {
      await tester.pumpWidget(buildSubject(
        chatState: ChatState(
          status: ChatStatus.loaded,
          chatRooms: tChatRooms,
        ),
      ));
      await pumpStagger(tester);

      expect(find.byType(ChatTile), findsNWidgets(2));

      await tester.enterText(find.byType(TextField), 'Alpha');
      await tester.pump();

      expect(find.byType(ChatTile), findsOneWidget);
      expect(find.text('Room Alpha'), findsOneWidget);
    });
  });
}

void _noOp() {}
