import 'dart:io';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:pulse/features/auth/domain/entities/user.dart';
import 'package:pulse/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse/features/expense/domain/entities/expense.dart';
import 'package:pulse/features/expense/domain/entities/expense_item.dart';
import 'package:pulse/features/expense/domain/entities/expense_split.dart';
import 'package:pulse/features/expense/presentation/bloc/expense_bloc.dart';
import 'package:pulse/features/expense/presentation/screens/expense_details_screen.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockExpenseBloc extends MockBloc<ExpenseEvent, ExpenseState>
    implements ExpenseBloc {}

class FakeAuthEvent extends Fake implements AuthEvent {}

class FakeExpenseEvent extends Fake implements ExpenseEvent {}

class FakeImagePickerPlatform extends ImagePickerPlatform
    with MockPlatformInterfaceMixin {
  XFile? pickedImage;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    return pickedImage;
  }
}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockExpenseBloc mockExpenseBloc;
  late FakeImagePickerPlatform fakeImagePickerPlatform;
  late ImagePickerPlatform originalImagePickerPlatform;
  late String tempImagePath;

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
    splits: const [
      ExpenseSplit(
        userId: 'owner-1',
        userName: 'Owner',
        amount: 50.68,
        isPaid: true,
      ),
      ExpenseSplit(userId: 'user-2', userName: 'Participant', amount: 3),
    ],
  );

  final ownerViewableProofExpense = Expense(
    id: 'expense-2',
    ownerId: 'owner-1',
    title: 'Dinner',
    totalAmount: 53.68,
    date: DateTime(2026, 3, 13),
    status: ExpenseStatus.settled,
    splits: const [
      ExpenseSplit(
        userId: 'owner-1',
        userName: 'Owner',
        amount: 50.68,
        isPaid: true,
      ),
      ExpenseSplit(
        userId: 'user-2',
        userName: 'Participant',
        amount: 3,
        paymentStatus: ExpensePaymentStatus.paid,
        proofImageUrl: 'https://example.com/proof.jpg',
        matchedAmount: 3,
        matchedRecipient: 'Owner',
        matchConfidence: 0.9,
      ),
    ],
  );

  final ownerReviewExpense = Expense(
    id: 'expense-3',
    ownerId: 'owner-1',
    title: 'Dinner',
    totalAmount: 53.68,
    date: DateTime(2026, 3, 13),
    splits: const [
      ExpenseSplit(
        userId: 'owner-1',
        userName: 'Owner',
        amount: 50.68,
        isPaid: true,
      ),
      ExpenseSplit(
        userId: 'user-2',
        userName: 'Participant',
        amount: 3,
        paymentStatus: ExpensePaymentStatus.proofSubmitted,
        proofImageUrl: 'https://example.com/proof.jpg',
        matchedAmount: 3,
        matchedRecipient: 'Owner',
        matchConfidence: 0.9,
      ),
    ],
  );

  final paidUserItemsExpense = Expense(
    id: 'expense-4',
    ownerId: 'owner-1',
    title: 'Dinner',
    totalAmount: 53.68,
    date: DateTime(2026, 3, 13),
    items: const [ExpenseItem(id: 'item-1', name: 'Nasi Goreng', price: 9)],
    splits: const [
      ExpenseSplit(userId: 'owner-1', userName: 'Owner', amount: 40.68),
      ExpenseSplit(
        userId: 'user-2',
        userName: 'Participant',
        amount: 13,
        paymentStatus: ExpensePaymentStatus.paid,
      ),
    ],
  );

  final reviewUserItemsExpense = Expense(
    id: 'expense-5',
    ownerId: 'owner-1',
    title: 'Dinner',
    totalAmount: 53.68,
    date: DateTime(2026, 3, 13),
    items: const [ExpenseItem(id: 'item-1', name: 'Nasi Goreng', price: 9)],
    splits: const [
      ExpenseSplit(userId: 'owner-1', userName: 'Owner', amount: 40.68),
      ExpenseSplit(
        userId: 'user-2',
        userName: 'Participant',
        amount: 13,
        paymentStatus: ExpensePaymentStatus.proofSubmitted,
      ),
    ],
  );

  Future<String> createTempImage() async {
    const pngBytes = <int>[
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
      0x00,
      0x00,
      0x00,
      0x0D,
      0x49,
      0x48,
      0x44,
      0x52,
      0x00,
      0x00,
      0x00,
      0x01,
      0x00,
      0x00,
      0x00,
      0x01,
      0x08,
      0x06,
      0x00,
      0x00,
      0x00,
      0x1F,
      0x15,
      0xC4,
      0x89,
      0x00,
      0x00,
      0x00,
      0x0D,
      0x49,
      0x44,
      0x41,
      0x54,
      0x78,
      0x9C,
      0x63,
      0xF8,
      0xCF,
      0xC0,
      0x00,
      0x00,
      0x03,
      0x01,
      0x01,
      0x00,
      0x18,
      0xDD,
      0x8D,
      0xB1,
      0x00,
      0x00,
      0x00,
      0x00,
      0x49,
      0x45,
      0x4E,
      0x44,
      0xAE,
      0x42,
      0x60,
      0x82,
    ];

    final file = File(
      '${Directory.systemTemp.path}/expense-proof-test-${DateTime.now().microsecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(Uint8List.fromList(pngBytes));
    return file.path;
  }

  ExpenseState buildExpenseState({
    Expense? selectedExpense,
    String currentUserId = 'user-2',
    ExpenseDetailStatus detailStatus = ExpenseDetailStatus.loaded,
    ExpenseDetailAction detailAction = ExpenseDetailAction.none,
  }) {
    return ExpenseState(
      currentUserId: currentUserId,
      expenses: [selectedExpense ?? expense],
      selectedExpense: selectedExpense ?? expense,
      detailStatus: detailStatus,
      detailAction: detailAction,
    );
  }

  Widget buildSubject(
    ExpenseState state, {
    Stream<ExpenseState>? expenseStream,
  }) {
    when(() => mockAuthBloc.state).thenReturn(
      const AuthState(status: AuthStatus.authenticated, user: currentUser),
    );
    when(() => mockExpenseBloc.state).thenReturn(state);
    whenListen(
      mockExpenseBloc,
      expenseStream ?? const Stream<ExpenseState>.empty(),
      initialState: state,
    );

    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<ExpenseBloc>.value(value: mockExpenseBloc),
        ],
        child: const ExpenseDetailsScreen(expenseId: 'expense-1'),
      ),
    );
  }

  setUpAll(() {
    registerFallbackValue(FakeAuthEvent());
    registerFallbackValue(FakeExpenseEvent());
  });

  setUp(() async {
    mockAuthBloc = MockAuthBloc();
    mockExpenseBloc = MockExpenseBloc();
    originalImagePickerPlatform = ImagePickerPlatform.instance;
    fakeImagePickerPlatform = FakeImagePickerPlatform();
    ImagePickerPlatform.instance = fakeImagePickerPlatform;
    tempImagePath = await createTempImage();
    fakeImagePickerPlatform.pickedImage = XFile(tempImagePath);
  });

  tearDown(() async {
    ImagePickerPlatform.instance = originalImagePickerPlatform;
    final tempFile = File(tempImagePath);
    if (await tempFile.exists()) {
      await tempFile.delete();
    }
  });

  testWidgets(
    'shows compact blocking dialog while payment proof is submitting',
    (tester) async {
      await tester.pumpWidget(
        buildSubject(
          buildExpenseState(),
          expenseStream: Stream<ExpenseState>.fromIterable([
            buildExpenseState(
              detailAction: ExpenseDetailAction.submittingPaymentProof,
            ),
          ]),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(
        find.byKey(const ValueKey('payment-proof-progress-dialog')),
        findsOneWidget,
      );
      expect(find.text('Submitting payment proof...'), findsOneWidget);
      expect(
        find.text('Analyzing receipt and saving payment. Please wait.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'hides select items action when current user split is already paid',
    (tester) async {
      await tester.pumpWidget(
        buildSubject(buildExpenseState(selectedExpense: paidUserItemsExpense)),
      );

      expect(find.text('Items (1)'), findsOneWidget);
      expect(find.text('Select Items'), findsNothing);
    },
  );

  testWidgets(
    'hides select items action when current user payment proof is awaiting review',
    (tester) async {
      await tester.pumpWidget(
        buildSubject(
          buildExpenseState(selectedExpense: reviewUserItemsExpense),
        ),
      );

      expect(find.text('Items (1)'), findsOneWidget);
      expect(find.text('Select Items'), findsNothing);
    },
  );

  testWidgets('asks for preview confirmation before uploading payment proof', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject(buildExpenseState()));

    await tester.tap(find.text('Upload Payment Proof'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Choose from Gallery'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('payment-proof-preview-sheet')),
      findsOneWidget,
    );
    expect(find.text('Upload this payment proof?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Upload'), findsWidgets);
    verifyNever(() => mockExpenseBloc.add(any()));

    await tester.tap(
      find.byKey(const ValueKey('payment-proof-upload-preview-image')),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Close'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('payment-proof-preview-sheet')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('confirm-payment-proof-upload')),
    );
    await tester.pumpAndSettle();

    verify(
      () => mockExpenseBloc.add(
        ExpensePaymentProofSubmissionRequested(
          expenseId: 'expense-1',
          userId: 'user-2',
          imagePath: tempImagePath,
        ),
      ),
    ).called(1);
  });

  testWidgets('owner can still view proof after payment is recorded', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        buildExpenseState(
          selectedExpense: ownerViewableProofExpense,
          currentUserId: 'owner-1',
        ),
      ),
    );

    expect(find.text('View Proof'), findsOneWidget);

    await tester.tap(find.text('View Proof'));
    await tester.pumpAndSettle();

    expect(find.text('Payment Proof'), findsOneWidget);
    expect(find.text('Expected amount'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
    expect(find.text('Approve'), findsNothing);
    expect(find.text('Reject'), findsNothing);
  });

  testWidgets('payment proof preview opens full-screen lightbox on tap', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        buildExpenseState(
          selectedExpense: ownerViewableProofExpense,
          currentUserId: 'owner-1',
        ),
      ),
    );

    await tester.tap(find.text('View Proof'));
    await tester.pumpAndSettle();

    expect(find.text('Tap image to view full size'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('payment-proof-image-preview')));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Close'), findsOneWidget);
  });

  testWidgets('owner can cancel reject dialog without dispatching rejection', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        buildExpenseState(
          selectedExpense: ownerReviewExpense,
          currentUserId: 'owner-1',
        ),
      ),
    );

    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();

    expect(find.text('Review Payment Proof'), findsOneWidget);

    await tester.tap(find.text('Reject'));
    await tester.pumpAndSettle();

    expect(find.text('Reject Payment Proof'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Reject Payment Proof'), findsNothing);
    verifyNever(
      () => mockExpenseBloc.add(any(that: isA<ExpensePaymentProofRejected>())),
    );
  });
}
