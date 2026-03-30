import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/chat/domain/entities/message.dart';
import 'package:pulse/features/chat/domain/usecases/send_message.dart';
import 'package:pulse/features/expense/domain/entities/expense.dart';
import 'package:pulse/features/expense/domain/entities/expense_submission.dart';
import 'package:pulse/features/expense/domain/repositories/expense_repository.dart';
import 'package:pulse/features/expense/domain/services/expense_submission_service.dart';
import 'package:pulse/features/expense/domain/usecases/create_expense.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockSendMessage extends Mock implements SendMessage {}

void main() {
  late CreateExpense usecase;
  late MockExpenseRepository mockRepository;
  late MockSendMessage mockSendMessage;

  const tSubmission = ExpenseSubmission(
    currentUserId: 'user-1',
    currentUserName: 'John Doe',
    title: 'Groceries',
    description: 'Weekly groceries',
    expenseType: ExpenseType.group,
    chatRoomId: 'chat-1',
    participants: [
      ExpenseParticipant(id: 'user-1', name: 'John Doe'),
      ExpenseParticipant(id: 'user-2', name: 'Alice'),
    ],
    manualAmount: 50.0,
  );

  final tCreatedExpense = Expense(
    id: 'expense-1',
    ownerId: 'user-1',
    title: 'Groceries',
    description: 'Weekly groceries',
    totalAmount: 50.0,
    date: DateTime(2024, 1, 1),
    chatRoomId: 'chat-1',
    status: ExpenseStatus.pending,
    type: ExpenseType.group,
    splits: const [],
  );

  final tSentMessage = Message(
    id: 'message-1',
    senderId: 'user-1',
    senderName: 'John Doe',
    content: 'Shared a split: Groceries',
    chatRoomId: 'chat-1',
    timestamp: DateTime(2024, 1, 1),
    type: MessageType.expense,
  );

  setUpAll(() {
    registerFallbackValue(tCreatedExpense);
    registerFallbackValue(SendMessageParams(message: tSentMessage));
  });

  setUp(() {
    mockRepository = MockExpenseRepository();
    mockSendMessage = MockSendMessage();
    usecase = CreateExpense(
      repository: mockRepository,
      submissionService: ExpenseSubmissionService(),
      sendMessage: mockSendMessage,
    );
  });

  test(
    'builds the expense in-domain, persists it, and sends chat message',
    () async {
      when(
        () => mockRepository.createExpense(any()),
      ).thenAnswer((_) async => Right(tCreatedExpense));
      when(
        () => mockSendMessage(any()),
      ).thenAnswer((_) async => Right(tSentMessage));

      final result = await usecase(
        const CreateExpenseParams(submission: tSubmission),
      );

      expect(result, Right(tCreatedExpense));

      final capturedExpense =
          verify(
                () => mockRepository.createExpense(captureAny()),
              ).captured.single
              as Expense;
      expect(capturedExpense.id, '');
      expect(capturedExpense.title, 'Groceries');
      expect(capturedExpense.totalAmount, 50.0);
      expect(capturedExpense.splits, hasLength(2));
      expect(capturedExpense.splits.first.isPaid, isTrue);
      expect(capturedExpense.splits.last.amount, 25.0);

      final capturedMessage =
          verify(() => mockSendMessage(captureAny())).captured.single
              as SendMessageParams;
      expect(capturedMessage.message.chatRoomId, 'chat-1');
      expect(capturedMessage.message.content, 'Shared a split: Groceries');
      expect(capturedMessage.message.eventData?['memberCount'], 2);
    },
  );

  test('returns InvalidInputFailure when submission is invalid', () async {
    const invalidSubmission = ExpenseSubmission(
      currentUserId: 'user-1',
      currentUserName: 'John Doe',
      title: '',
      description: '',
      expenseType: ExpenseType.group,
      participants: [ExpenseParticipant(id: 'user-1', name: 'John Doe')],
      manualAmount: 0,
    );

    final result = await usecase(
      const CreateExpenseParams(submission: invalidSubmission),
    );

    expect(
      result,
      const Left(InvalidInputFailure(message: 'Please enter a title')),
    );
    verifyNever(() => mockRepository.createExpense(any()));
    verifyNever(() => mockSendMessage(any()));
  });

  test(
    'returns repository failure and skips chat send when create fails',
    () async {
      when(() => mockRepository.createExpense(any())).thenAnswer(
        (_) async =>
            const Left(ServerFailure(message: 'Failed to create expense')),
      );

      final result = await usecase(
        const CreateExpenseParams(submission: tSubmission),
      );

      expect(
        result,
        const Left(ServerFailure(message: 'Failed to create expense')),
      );
      verify(() => mockRepository.createExpense(any())).called(1);
      verifyNever(() => mockSendMessage(any()));
    },
  );
}
