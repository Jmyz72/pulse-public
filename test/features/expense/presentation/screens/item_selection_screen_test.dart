import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/auth/domain/entities/user.dart';
import 'package:pulse/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse/features/expense/domain/entities/expense.dart';
import 'package:pulse/features/expense/domain/entities/expense_item.dart';
import 'package:pulse/features/expense/domain/entities/expense_split.dart';
import 'package:pulse/features/expense/presentation/bloc/expense_bloc.dart';
import 'package:pulse/features/expense/presentation/screens/item_selection_screen.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockExpenseBloc extends MockBloc<ExpenseEvent, ExpenseState>
    implements ExpenseBloc {}

class FakeAuthEvent extends Fake implements AuthEvent {}

class FakeExpenseEvent extends Fake implements ExpenseEvent {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockExpenseBloc mockExpenseBloc;

  const currentUser = User(
    id: 'user-2',
    username: 'user2',
    displayName: 'User Two',
    email: 'user2@test.com',
    phone: '123456789',
  );

  final expense = Expense(
    id: 'expense-1',
    ownerId: 'owner-1',
    title: 'Dinner',
    totalAmount: 53.68,
    date: DateTime(2026, 3, 13),
    items: const [
      ExpenseItem(
        id: 'item-1',
        name: 'Nasi Goreng',
        price: 9,
        assignedUserIds: ['user-2'],
      ),
      ExpenseItem(
        id: 'item-2',
        name: 'Teh O Ice',
        price: 4,
        assignedUserIds: [],
      ),
    ],
    splits: const [
      ExpenseSplit(
        userId: 'owner-1',
        userName: 'Owner',
        amount: 40.68,
        isPaid: true,
      ),
      ExpenseSplit(userId: 'user-2', userName: 'User Two', amount: 13),
    ],
  );

  final lockedItemExpense = Expense(
    id: 'expense-1',
    ownerId: 'owner-1',
    title: 'Dinner',
    totalAmount: 53.68,
    date: DateTime(2026, 3, 13),
    items: const [
      ExpenseItem(
        id: 'item-1',
        name: 'Nasi Goreng',
        price: 9,
        assignedUserIds: ['owner-1'],
      ),
      ExpenseItem(
        id: 'item-2',
        name: 'Teh O Ice',
        price: 4,
        assignedUserIds: ['user-2'],
      ),
    ],
    splits: const [
      ExpenseSplit(
        userId: 'owner-1',
        userName: 'Owner',
        amount: 40.68,
        paymentStatus: ExpensePaymentStatus.paid,
      ),
      ExpenseSplit(userId: 'user-2', userName: 'User Two', amount: 13),
    ],
  );

  final paidUserExpense = Expense(
    id: 'expense-1',
    ownerId: 'owner-1',
    title: 'Dinner',
    totalAmount: 53.68,
    date: DateTime(2026, 3, 13),
    items: const [
      ExpenseItem(
        id: 'item-1',
        name: 'Nasi Goreng',
        price: 9,
        assignedUserIds: ['user-2'],
      ),
    ],
    splits: const [
      ExpenseSplit(userId: 'owner-1', userName: 'Owner', amount: 40.68),
      ExpenseSplit(
        userId: 'user-2',
        userName: 'User Two',
        amount: 13,
        paymentStatus: ExpensePaymentStatus.paid,
      ),
    ],
  );

  final reviewLockedItemExpense = Expense(
    id: 'expense-1',
    ownerId: 'owner-1',
    title: 'Dinner',
    totalAmount: 53.68,
    date: DateTime(2026, 3, 13),
    items: const [
      ExpenseItem(
        id: 'item-1',
        name: 'Nasi Goreng',
        price: 9,
        assignedUserIds: ['owner-1'],
      ),
      ExpenseItem(
        id: 'item-2',
        name: 'Teh O Ice',
        price: 4,
        assignedUserIds: ['user-2'],
      ),
    ],
    splits: const [
      ExpenseSplit(
        userId: 'owner-1',
        userName: 'Owner',
        amount: 40.68,
        paymentStatus: ExpensePaymentStatus.proofSubmitted,
      ),
      ExpenseSplit(userId: 'user-2', userName: 'User Two', amount: 13),
    ],
  );

  final reviewUserExpense = Expense(
    id: 'expense-1',
    ownerId: 'owner-1',
    title: 'Dinner',
    totalAmount: 53.68,
    date: DateTime(2026, 3, 13),
    items: const [
      ExpenseItem(
        id: 'item-1',
        name: 'Nasi Goreng',
        price: 9,
        assignedUserIds: ['user-2'],
      ),
    ],
    splits: const [
      ExpenseSplit(userId: 'owner-1', userName: 'Owner', amount: 40.68),
      ExpenseSplit(
        userId: 'user-2',
        userName: 'User Two',
        amount: 13,
        paymentStatus: ExpensePaymentStatus.proofSubmitted,
      ),
    ],
  );

  Widget buildSubject(ExpenseState state) {
    when(() => mockAuthBloc.state).thenReturn(
      const AuthState(status: AuthStatus.authenticated, user: currentUser),
    );
    when(() => mockExpenseBloc.state).thenReturn(state);
    whenListen(
      mockExpenseBloc,
      const Stream<ExpenseState>.empty(),
      initialState: state,
    );

    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<ExpenseBloc>.value(value: mockExpenseBloc),
        ],
        child: const ItemSelectionScreen(expenseId: 'expense-1'),
      ),
    );
  }

  setUpAll(() {
    registerFallbackValue(FakeAuthEvent());
    registerFallbackValue(FakeExpenseEvent());
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockExpenseBloc = MockExpenseBloc();
  });

  testWidgets(
    'hydrates previously selected items from expenses list when selectedExpense is null',
    (tester) async {
      final state = ExpenseState(
        currentUserId: 'user-2',
        expenses: [expense],
        selectedExpense: null,
        detailStatus: ExpenseDetailStatus.loaded,
      );

      await tester.pumpWidget(buildSubject(state));
      await tester.pump();

      expect(find.text('1 of 2'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    },
  );

  testWidgets('shows locked item as non-interactive when assigned user is paid', (
    tester,
  ) async {
    final state = ExpenseState(
      currentUserId: 'user-2',
      expenses: [lockedItemExpense],
      selectedExpense: lockedItemExpense,
      detailStatus: ExpenseDetailStatus.loaded,
    );

    await tester.pumpWidget(buildSubject(state));
    await tester.pump();

    expect(find.text('Locked'), findsOneWidget);
    expect(find.text('Locked Items'), findsOneWidget);
    expect(
      find.text('Payment is under review or already recorded for these items.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Selection locked because payment is under review or already recorded.',
      ),
      findsOneWidget,
    );
    expect(find.text('1 of 2'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Teh O Ice')).dy,
      lessThan(tester.getTopLeft(find.text('Locked Items')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Locked Items')).dy,
      lessThan(tester.getTopLeft(find.text('Nasi Goreng')).dy),
    );

    await tester.ensureVisible(find.text('Nasi Goreng'));
    await tester.tap(find.text('Nasi Goreng'), warnIfMissed: false);
    await tester.pump();

    expect(find.text('1 of 2'), findsOneWidget);
  });

  testWidgets(
    'shows read-only notice and hides save when current user is paid',
    (tester) async {
      final state = ExpenseState(
        currentUserId: 'user-2',
        expenses: [paidUserExpense],
        selectedExpense: paidUserExpense,
        detailStatus: ExpenseDetailStatus.loaded,
      );

      await tester.pumpWidget(buildSubject(state));
      await tester.pump();

      expect(
        find.text(
          'Your payment is already recorded. Item selection is locked.',
        ),
        findsOneWidget,
      );
      expect(find.text('Save'), findsNothing);
      expect(find.text('Selection Locked'), findsOneWidget);
    },
  );

  testWidgets(
    'shows locked item as non-interactive when assigned user is awaiting review',
    (tester) async {
      final state = ExpenseState(
        currentUserId: 'user-2',
        expenses: [reviewLockedItemExpense],
        selectedExpense: reviewLockedItemExpense,
        detailStatus: ExpenseDetailStatus.loaded,
      );

      await tester.pumpWidget(buildSubject(state));
      await tester.pump();

      expect(find.text('Locked Items'), findsOneWidget);
      expect(
        find.text(
          'Selection locked because payment is under review or already recorded.',
        ),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(find.text('Teh O Ice')).dy,
        lessThan(tester.getTopLeft(find.text('Locked Items')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Locked Items')).dy,
        lessThan(tester.getTopLeft(find.text('Nasi Goreng')).dy),
      );
    },
  );

  testWidgets(
    'shows read-only notice and hides save when current user proof is awaiting review',
    (tester) async {
      final state = ExpenseState(
        currentUserId: 'user-2',
        expenses: [reviewUserExpense],
        selectedExpense: reviewUserExpense,
        detailStatus: ExpenseDetailStatus.loaded,
      );

      await tester.pumpWidget(buildSubject(state));
      await tester.pump();

      expect(
        find.text(
          'Your payment proof is waiting for owner review. Item selection is locked.',
        ),
        findsOneWidget,
      );
      expect(find.text('Save'), findsNothing);
      expect(find.text('Selection Locked'), findsOneWidget);
    },
  );
}
