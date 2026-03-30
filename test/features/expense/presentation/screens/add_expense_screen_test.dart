import 'dart:async';

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
import 'package:pulse/features/expense/domain/entities/expense.dart';
import 'package:pulse/features/expense/presentation/bloc/expense_bloc.dart';
import 'package:pulse/features/expense/presentation/screens/add_expense.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockChatBloc extends MockBloc<ChatEvent, ChatState> implements ChatBloc {}

class MockExpenseBloc extends MockBloc<ExpenseEvent, ExpenseState>
    implements ExpenseBloc {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class FakeChatEvent extends Fake implements ChatEvent {}

class FakeExpenseEvent extends Fake implements ExpenseEvent {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockChatBloc mockChatBloc;
  late MockExpenseBloc mockExpenseBloc;
  late MockNavigatorObserver navigatorObserver;

  const tUser = User(
    id: 'user-1',
    username: 'john',
    displayName: 'John Doe',
    email: 'john@test.com',
    phone: '1234567890',
  );

  final tGroupChatRoom = ChatRoom(
    id: 'group-1',
    name: 'House Group',
    members: const ['user-1', 'user-2', 'user-3'],
    memberNames: const {
      'user-1': 'John Doe',
      'user-2': 'Alice',
      'user-3': 'Bob',
    },
    createdAt: DateTime(2026, 1, 1),
    lastMessageAt: DateTime(2026, 3, 10),
    isGroup: true,
  );

  final tOneOnOneChatRoom = ChatRoom(
    id: 'direct-1',
    name: 'Alice',
    members: const ['user-1', 'user-2'],
    memberNames: const {'user-1': 'John Doe', 'user-2': 'Alice'},
    createdAt: DateTime(2026, 1, 1),
    lastMessageAt: DateTime(2026, 3, 11),
    isGroup: false,
  );

  setUpAll(() {
    registerFallbackValue(FakeChatEvent());
    registerFallbackValue(FakeExpenseEvent());
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockChatBloc = MockChatBloc();
    mockExpenseBloc = MockExpenseBloc();
    navigatorObserver = MockNavigatorObserver();

    when(() => mockAuthBloc.state).thenReturn(
      const AuthState(status: AuthStatus.authenticated, user: tUser),
    );
    when(
      () => mockExpenseBloc.state,
    ).thenReturn(ExpenseState(currentUserId: tUser.id));
    whenListen(
      mockExpenseBloc,
      const Stream<ExpenseState>.empty(),
      initialState: ExpenseState(currentUserId: tUser.id),
    );
  });

  Widget buildSubject({
    required ChatState chatState,
    Stream<ChatState>? chatStream,
    Stream<ExpenseState>? expenseStream,
    Map<String, dynamic>? routeArguments,
  }) {
    when(() => mockChatBloc.state).thenReturn(chatState);
    whenListen(
      mockChatBloc,
      chatStream ?? const Stream<ChatState>.empty(),
      initialState: chatState,
    );

    if (expenseStream != null) {
      whenListen(
        mockExpenseBloc,
        expenseStream,
        initialState: ExpenseState(currentUserId: tUser.id),
      );
    }

    return MaterialApp(
      navigatorObservers: [navigatorObserver],
      onGenerateInitialRoutes: (_) => [
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Launcher')),
        ),
        MaterialPageRoute<void>(
          settings: RouteSettings(arguments: routeArguments),
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              BlocProvider<ChatBloc>.value(value: mockChatBloc),
              BlocProvider<ExpenseBloc>.value(value: mockExpenseBloc),
            ],
            child: const AddExpenseScreen(),
          ),
        ),
      ],
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.itemSelection) {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          return MaterialPageRoute<void>(
            builder: (_) =>
                Scaffold(body: Text('Item selection ${args['expenseId']}')),
            settings: settings,
          );
        }
        return null;
      },
    );
  }

  Future<void> enterEqualSplitSetup(
    WidgetTester tester, {
    required String title,
    required String amount,
  }) async {
    await tester.enterText(find.byType(TextFormField).first, title);
    await tester.enterText(find.byType(TextFormField).at(2), amount);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
  }

  group('AddExpenseScreen context picker', () {
    testWidgets('shows 2-step flow and removes visible type and room radios', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          chatState: ChatState(
            status: ChatStatus.loaded,
            chatRooms: [tGroupChatRoom, tOneOnOneChatRoom],
          ),
        ),
      );

      expect(find.text('Setup'), findsOneWidget);
      expect(find.text('People'), findsOneWidget);
      expect(find.text('Who is this with?'), findsOneWidget);
      expect(find.text('Group Expense'), findsNothing);
      expect(find.text('1-on-1 Expense'), findsNothing);
      expect(find.text('Ad-hoc Expense'), findsNothing);
      expect(find.text('Select Chat Room'), findsNothing);
    });

    testWidgets('uses ChatBloc chat rooms when route args are missing', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          chatState: ChatState(
            status: ChatStatus.loaded,
            chatRooms: [tGroupChatRoom, tOneOnOneChatRoom],
          ),
        ),
      );

      expect(find.text('Who is this with?'), findsOneWidget);
      expect(find.text('Choose a chat'), findsOneWidget);
    });

    testWidgets('shows loading first and updates when chats arrive', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          chatState: const ChatState(status: ChatStatus.loading, chatRooms: []),
          chatStream: Stream<ChatState>.fromIterable([
            ChatState(
              status: ChatStatus.loaded,
              chatRooms: [tGroupChatRoom, tOneOnOneChatRoom],
            ),
          ]),
        ),
      );

      expect(find.text('Loading chats...'), findsOneWidget);

      await tester.pump();

      expect(find.text('Choose a chat'), findsOneWidget);
    });

    testWidgets('requests chat watch when no route args and no cached chats', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          chatState: const ChatState(status: ChatStatus.initial, chatRooms: []),
        ),
      );

      verify(
        () => mockChatBloc.add(any(that: isA<ChatRoomsWatchRequested>())),
      ).called(1);
    });

    testWidgets(
      'preselected chat room skips manual context selection and allows continue',
      (tester) async {
        await tester.pumpWidget(
          buildSubject(
            chatState: ChatState(
              status: ChatStatus.loaded,
              chatRooms: [tGroupChatRoom, tOneOnOneChatRoom],
            ),
            routeArguments: {
              'chatRooms': [tGroupChatRoom, tOneOnOneChatRoom],
              'preselectedChatRoomId': tGroupChatRoom.id,
            },
          ),
        );

        expect(find.text('House Group'), findsOneWidget);
        expect(find.text('Split with a group chat'), findsOneWidget);
        expect(find.text('Choose a chat'), findsNothing);

        await enterEqualSplitSetup(tester, title: 'Team Dinner', amount: '30');

        expect(find.text('People & Submit'), findsOneWidget);
        expect(find.text('Selected members'), findsOneWidget);
      },
    );

    testWidgets('generic entry opens a searchable bottom-sheet picker', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          chatState: ChatState(
            status: ChatStatus.loaded,
            chatRooms: [tGroupChatRoom, tOneOnOneChatRoom],
          ),
        ),
      );

      await tester.tap(find.text('Choose a chat'));
      await tester.pumpAndSettle();

      expect(find.text('Recent Direct Chats'), findsOneWidget);
      expect(find.text('Recent Group Chats'), findsOneWidget);
      expect(find.text('Alice'), findsWidgets);
      expect(find.text('House Group'), findsOneWidget);
      expect(find.text('Search chats'), findsOneWidget);
    });

    testWidgets('picker search filters chat rooms by display name', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          chatState: ChatState(
            status: ChatStatus.loaded,
            chatRooms: [tGroupChatRoom, tOneOnOneChatRoom],
          ),
        ),
      );

      await tester.tap(find.text('Choose a chat'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('chat_room_search_field')),
        'ali',
      );
      await tester.pumpAndSettle();

      expect(find.text('Recent Group Chats'), findsNothing);
      expect(find.text('Alice'), findsWidgets);
    });

    testWidgets(
      'selecting a direct room derives direct context and loads members',
      (tester) async {
        await tester.pumpWidget(
          buildSubject(
            chatState: ChatState(
              status: ChatStatus.loaded,
              chatRooms: [tGroupChatRoom, tOneOnOneChatRoom],
            ),
          ),
        );

        await tester.tap(find.text('Choose a chat'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Alice').first);
        await tester.pumpAndSettle();

        expect(find.text('Split with a direct chat'), findsOneWidget);

        await enterEqualSplitSetup(tester, title: 'Lunch', amount: '20');

        expect(find.text('John Doe (You)'), findsOneWidget);
        expect(find.text('Alice'), findsWidgets);
      },
    );

    testWidgets(
      'selecting a group room derives group context and loads members',
      (tester) async {
        await tester.pumpWidget(
          buildSubject(
            chatState: ChatState(
              status: ChatStatus.loaded,
              chatRooms: [tGroupChatRoom, tOneOnOneChatRoom],
            ),
          ),
        );

        await tester.tap(find.text('Choose a chat'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('House Group'));
        await tester.pumpAndSettle();

        expect(find.text('Split with a group chat'), findsOneWidget);

        await enterEqualSplitSetup(
          tester,
          title: 'House Supplies',
          amount: '60',
        );

        expect(find.text('Alice'), findsWidgets);
        expect(find.text('Bob'), findsWidgets);
      },
    );

    testWidgets('auto-selects the only available room without opening picker', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          chatState: ChatState(
            status: ChatStatus.loaded,
            chatRooms: [tOneOnOneChatRoom],
          ),
        ),
      );

      expect(find.text('Choose a chat'), findsNothing);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Split with a direct chat'), findsOneWidget);
    });

    testWidgets(
      'receipt payload prepopulates custom items and adjustments on setup',
      (tester) async {
        await tester.pumpWidget(
          buildSubject(
            chatState: ChatState(
              status: ChatStatus.loaded,
              chatRooms: [tGroupChatRoom],
            ),
            routeArguments: {
              'chatRooms': [tGroupChatRoom],
              'scannedItems': [
                {'name': 'Burger', 'price': 12.0, 'quantity': 1},
                {'name': 'Tea', 'price': 4.0, 'quantity': 2},
              ],
              'taxPercent': 6.0,
              'serviceChargePercent': 10.0,
              'discountPercent': 5.0,
            },
          ),
        );

        expect(find.text('Items (2)'), findsOneWidget);
        expect(find.text('Burger'), findsOneWidget);
        expect(find.text('Tea'), findsOneWidget);
        expect(find.text('Tax %'), findsOneWidget);
        expect(find.text('Service Charge %'), findsOneWidget);
        expect(find.text('Discount %'), findsOneWidget);
      },
    );

    testWidgets(
      'include me toggle immediately updates member selection and per-person amount',
      (tester) async {
        await tester.pumpWidget(
          buildSubject(
            chatState: ChatState(
              status: ChatStatus.loaded,
              chatRooms: [tGroupChatRoom],
            ),
            routeArguments: {
              'chatRooms': [tGroupChatRoom],
              'preselectedChatRoomId': tGroupChatRoom.id,
            },
          ),
        );

        await enterEqualSplitSetup(tester, title: 'Team Dinner', amount: '30');

        expect(find.text('RM 10.00'), findsOneWidget);

        await tester.ensureVisible(find.byType(Switch));
        await tester.tap(find.byType(Switch), warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(find.text('RM 15.00'), findsOneWidget);
      },
    );

    testWidgets('custom split create replaces screen with item selection', (
      tester,
    ) async {
      final expenseController = StreamController<ExpenseState>();
      await tester.pumpWidget(
        buildSubject(
          chatState: ChatState(
            status: ChatStatus.loaded,
            chatRooms: [tGroupChatRoom],
          ),
          expenseStream: expenseController.stream,
          routeArguments: {
            'chatRooms': [tGroupChatRoom],
            'scannedItems': [
              {'name': 'Burger', 'price': 12.0, 'quantity': 1},
              {'name': 'Tea', 'price': 4.0, 'quantity': 2},
            ],
          },
        ),
      );

      await tester.enterText(
        find.byType(TextFormField).first,
        'Scanned Dinner',
      );
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create Expense'));
      await tester.pump();

      final capturedEvent =
          verify(
                () => mockExpenseBloc.add(
                  captureAny(that: isA<ExpenseCreateRequested>()),
                ),
              ).captured.single
              as ExpenseCreateRequested;

      expect(capturedEvent.submission.title, 'Scanned Dinner');
      expect(capturedEvent.submission.isCustomSplit, isTrue);
      expect(capturedEvent.submission.items, hasLength(2));

      final createdExpense = Expense(
        id: 'server-expense-id',
        ownerId: tUser.id,
        title: 'Scanned Dinner',
        totalAmount: 20.0,
        date: DateTime(2026, 3, 12),
        chatRoomId: tGroupChatRoom.id,
        status: ExpenseStatus.pending,
        type: ExpenseType.group,
        items: capturedEvent.submission.items,
        splits: const [],
      );

      expenseController.add(
        ExpenseState(
          currentUserId: tUser.id,
          status: ExpenseLoadStatus.loaded,
          expenses: [createdExpense],
          selectedExpense: createdExpense,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Item selection server-expense-id'), findsOneWidget);
      await expenseController.close();
    });

    testWidgets(
      'equal split create pops back to previous screen after success',
      (tester) async {
        final expenseController = StreamController<ExpenseState>();
        await tester.pumpWidget(
          buildSubject(
            chatState: ChatState(
              status: ChatStatus.loaded,
              chatRooms: [tGroupChatRoom],
            ),
            expenseStream: expenseController.stream,
            routeArguments: {
              'chatRooms': [tGroupChatRoom],
              'preselectedChatRoomId': tGroupChatRoom.id,
            },
          ),
        );

        await enterEqualSplitSetup(tester, title: 'Team Dinner', amount: '30');
        await tester.tap(find.text('Create Expense'));
        await tester.pump();

        final capturedEvent =
            verify(
                  () => mockExpenseBloc.add(
                    captureAny(that: isA<ExpenseCreateRequested>()),
                  ),
                ).captured.single
                as ExpenseCreateRequested;

        expect(capturedEvent.submission.title, 'Team Dinner');
        expect(capturedEvent.submission.isCustomSplit, isFalse);
        expect(capturedEvent.submission.manualAmount, 30.0);

        final createdExpense = Expense(
          id: 'server-expense-id',
          ownerId: tUser.id,
          title: 'Team Dinner',
          totalAmount: 30.0,
          date: DateTime(2026, 3, 12),
          chatRoomId: tGroupChatRoom.id,
          status: ExpenseStatus.pending,
          type: ExpenseType.group,
          splits: const [],
        );

        expenseController.add(
          ExpenseState(
            currentUserId: tUser.id,
            status: ExpenseLoadStatus.loaded,
            expenses: [createdExpense],
            selectedExpense: createdExpense,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Launcher'), findsOneWidget);
        await expenseController.close();
      },
    );
  });
}
