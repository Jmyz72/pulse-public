import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/expense/domain/entities/expense.dart';
import 'package:pulse/features/expense/domain/entities/expense_submission.dart';
import 'package:pulse/features/expense/domain/repositories/expense_repository.dart';
import 'package:pulse/features/expense/domain/services/expense_submission_service.dart';
import 'package:pulse/features/expense/domain/usecases/update_expense.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

void main() {
  late UpdateExpense usecase;
  late MockExpenseRepository mockRepository;

  final tExistingExpense = Expense(
    id: 'expense-1',
    ownerId: 'owner-1',
    title: 'Dinner',
    totalAmount: 150.0,
    date: DateTime(2024, 1, 15),
    status: ExpenseStatus.pending,
    type: ExpenseType.group,
    chatRoomId: 'chat-1',
    splits: const [],
  );

  const tSubmission = ExpenseSubmission(
    currentUserId: 'owner-1',
    currentUserName: 'Owner',
    title: 'Updated Expense',
    description: '',
    expenseType: ExpenseType.group,
    chatRoomId: 'chat-1',
    participants: [
      ExpenseParticipant(id: 'owner-1', name: 'Owner'),
      ExpenseParticipant(id: 'friend-1', name: 'Friend'),
    ],
    manualAmount: 150.0,
  );

  final tUpdatedExpense = tExistingExpense.copyWith(
    title: 'Updated Expense',
    totalAmount: 150.0,
  );

  setUpAll(() {
    registerFallbackValue(tExistingExpense);
  });

  setUp(() {
    mockRepository = MockExpenseRepository();
    usecase = UpdateExpense(
      repository: mockRepository,
      submissionService: ExpenseSubmissionService(),
    );
  });

  group('UpdateExpense', () {
    test('rebuilds the expense in-domain before updating', () async {
      when(
        () => mockRepository.updateExpense(any()),
      ).thenAnswer((_) async => Right(tUpdatedExpense));

      final result = await usecase(
        UpdateExpenseParams(
          existingExpense: tExistingExpense,
          submission: tSubmission,
        ),
      );

      expect(result, Right(tUpdatedExpense));

      final capturedExpense =
          verify(
                () => mockRepository.updateExpense(captureAny()),
              ).captured.single
              as Expense;
      expect(capturedExpense.id, tExistingExpense.id);
      expect(capturedExpense.title, 'Updated Expense');
      expect(capturedExpense.description, isNull);
      expect(capturedExpense.totalAmount, 150.0);
      expect(capturedExpense.splits, hasLength(2));
    });

    test('returns InvalidInputFailure when submission is invalid', () async {
      const invalidSubmission = ExpenseSubmission(
        currentUserId: 'owner-1',
        currentUserName: 'Owner',
        title: 'Updated Expense',
        description: '',
        expenseType: ExpenseType.group,
        participants: [ExpenseParticipant(id: 'owner-1', name: 'Owner')],
        manualAmount: 150.0,
      );

      final result = await usecase(
        UpdateExpenseParams(
          existingExpense: tExistingExpense,
          submission: invalidSubmission,
        ),
      );

      expect(
        result,
        const Left(
          InvalidInputFailure(message: 'Please select at least 2 members'),
        ),
      );
      verifyNever(() => mockRepository.updateExpense(any()));
    });

    test('returns repository failure when update fails', () async {
      when(() => mockRepository.updateExpense(any())).thenAnswer(
        (_) async =>
            const Left(ServerFailure(message: 'Failed to update expense')),
      );

      final result = await usecase(
        UpdateExpenseParams(
          existingExpense: tExistingExpense,
          submission: tSubmission,
        ),
      );

      expect(
        result,
        const Left(ServerFailure(message: 'Failed to update expense')),
      );
      verify(() => mockRepository.updateExpense(any())).called(1);
    });
  });

  group('UpdateExpenseParams', () {
    test('should have correct props', () {
      final params = UpdateExpenseParams(
        existingExpense: tExistingExpense,
        submission: tSubmission,
      );
      expect(params.props, [tExistingExpense, tSubmission]);
    });
  });
}
