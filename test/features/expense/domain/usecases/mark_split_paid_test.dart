import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/expense/domain/entities/expense.dart';
import 'package:pulse/features/expense/domain/entities/expense_split.dart';
import 'package:pulse/features/expense/domain/repositories/expense_repository.dart';
import 'package:pulse/features/expense/domain/services/expense_payment_announcement_service.dart';
import 'package:pulse/features/expense/domain/usecases/mark_split_paid.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockExpensePaymentAnnouncementService extends Mock
    implements ExpensePaymentAnnouncementService {}

void main() {
  late MarkSplitPaid usecase;
  late MockExpenseRepository mockRepository;
  late MockExpensePaymentAnnouncementService mockAnnouncementService;

  setUp(() {
    mockRepository = MockExpenseRepository();
    mockAnnouncementService = MockExpensePaymentAnnouncementService();
    usecase = MarkSplitPaid(
      repository: mockRepository,
      announcementService: mockAnnouncementService,
    );
  });

  const tExpenseId = 'expense-1';
  const tUserId = 'user-1';
  final tPaidAt = DateTime(2024, 1, 16);

  final tExpenseBeforePay = Expense(
    id: tExpenseId,
    ownerId: 'owner-1',
    title: 'Test Expense',
    totalAmount: 100.0,
    date: DateTime(2024, 1, 15),
    status: ExpenseStatus.pending,
    type: ExpenseType.group,
    chatRoomId: 'chat-1',
    splits: const [
      ExpenseSplit(
        userId: tUserId,
        userName: 'User 1',
        amount: 50.0,
        isPaid: false,
      ),
      ExpenseSplit(
        userId: 'user-2',
        userName: 'User 2',
        amount: 50.0,
        isPaid: false,
      ),
    ],
  );

  final tExpenseAfterPay = Expense(
    id: tExpenseId,
    ownerId: 'owner-1',
    title: 'Test Expense',
    totalAmount: 100.0,
    date: DateTime(2024, 1, 15),
    status: ExpenseStatus.pending,
    type: ExpenseType.group,
    chatRoomId: 'chat-1',
    splits: [
      ExpenseSplit(
        userId: tUserId,
        userName: 'User 1',
        amount: 50.0,
        isPaid: true,
        paidAt: tPaidAt,
      ),
      const ExpenseSplit(
        userId: 'user-2',
        userName: 'User 2',
        amount: 50.0,
        isPaid: false,
      ),
    ],
  );

  final tExpenseFullyPaid = Expense(
    id: tExpenseId,
    ownerId: 'owner-1',
    title: 'Test Expense',
    totalAmount: 100.0,
    date: DateTime(2024, 1, 15),
    status: ExpenseStatus.settled,
    type: ExpenseType.group,
    chatRoomId: 'chat-1',
    splits: [
      ExpenseSplit(
        userId: tUserId,
        userName: 'User 1',
        amount: 50.0,
        isPaid: true,
        paidAt: tPaidAt,
      ),
      ExpenseSplit(
        userId: 'user-2',
        userName: 'User 2',
        amount: 50.0,
        isPaid: true,
        paidAt: tPaidAt,
      ),
    ],
  );

  setUpAll(() {
    registerFallbackValue(tExpenseBeforePay);
    registerFallbackValue(
      const ExpenseSplit(userId: 'fallback', userName: 'Fallback', amount: 0),
    );
  });

  group('MarkSplitPaid', () {
    test('should return updated expense when marking split as paid', () async {
      // arrange
      when(
        () => mockRepository.getExpenseById(tExpenseId),
      ).thenAnswer((_) async => Right(tExpenseBeforePay));
      when(
        () => mockRepository.markSplitAsPaid(
          expenseId: any(named: 'expenseId'),
          userId: any(named: 'userId'),
          isPaid: any(named: 'isPaid'),
        ),
      ).thenAnswer((_) async => Right(tExpenseAfterPay));
      when(
        () => mockAnnouncementService.announceSplitPaid(
          expense: tExpenseAfterPay,
          split: tExpenseAfterPay.splits.first,
        ),
      ).thenAnswer((_) async {});

      // act
      final result = await usecase(
        const MarkSplitPaidParams(
          expenseId: tExpenseId,
          userId: tUserId,
          isPaid: true,
        ),
      );

      // assert
      expect(result, Right(tExpenseAfterPay));
      verify(() => mockRepository.getExpenseById(tExpenseId)).called(1);
      verify(
        () => mockRepository.markSplitAsPaid(
          expenseId: tExpenseId,
          userId: tUserId,
          isPaid: true,
        ),
      ).called(1);
      verify(
        () => mockAnnouncementService.announceSplitPaid(
          expense: tExpenseAfterPay,
          split: tExpenseAfterPay.splits.first,
        ),
      ).called(1);
    });

    test(
      'should return expense with settled status when all splits are paid',
      () async {
        // arrange
        when(
          () => mockRepository.getExpenseById(tExpenseId),
        ).thenAnswer((_) async => Right(tExpenseBeforePay));
        when(
          () => mockRepository.markSplitAsPaid(
            expenseId: any(named: 'expenseId'),
            userId: any(named: 'userId'),
            isPaid: any(named: 'isPaid'),
          ),
        ).thenAnswer((_) async => Right(tExpenseFullyPaid));
        when(
          () => mockAnnouncementService.announceSplitPaid(
            expense: tExpenseFullyPaid,
            split: tExpenseFullyPaid.splits[1],
          ),
        ).thenAnswer((_) async {});

        // act
        final result = await usecase(
          const MarkSplitPaidParams(
            expenseId: tExpenseId,
            userId: 'user-2',
            isPaid: true,
          ),
        );

        // assert
        expect(result.isRight(), true);
        result.fold((l) => fail('Expected Right'), (r) {
          expect(r.status, ExpenseStatus.settled);
          expect(r.allSplitsPaid, true);
        });
        verify(
          () => mockAnnouncementService.announceSplitPaid(
            expense: tExpenseFullyPaid,
            split: tExpenseFullyPaid.splits[1],
          ),
        ).called(1);
      },
    );

    test('should handle marking split as unpaid', () async {
      // arrange
      when(
        () => mockRepository.getExpenseById(tExpenseId),
      ).thenAnswer((_) async => Right(tExpenseAfterPay));
      when(
        () => mockRepository.markSplitAsPaid(
          expenseId: any(named: 'expenseId'),
          userId: any(named: 'userId'),
          isPaid: any(named: 'isPaid'),
        ),
      ).thenAnswer((_) async => Right(tExpenseBeforePay));

      // act
      final result = await usecase(
        const MarkSplitPaidParams(
          expenseId: tExpenseId,
          userId: tUserId,
          isPaid: false,
        ),
      );

      // assert
      expect(result, Right(tExpenseBeforePay));
      verify(
        () => mockRepository.markSplitAsPaid(
          expenseId: tExpenseId,
          userId: tUserId,
          isPaid: false,
        ),
      ).called(1);
      verifyNever(
        () => mockAnnouncementService.announceSplitPaid(
          expense: any(named: 'expense'),
          split: any(named: 'split'),
        ),
      );
    });

    test('should return ServerFailure when expense is not found', () async {
      // arrange
      when(() => mockRepository.getExpenseById(tExpenseId)).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'Expense not found')),
      );
      when(
        () => mockRepository.markSplitAsPaid(
          expenseId: any(named: 'expenseId'),
          userId: any(named: 'userId'),
          isPaid: any(named: 'isPaid'),
        ),
      ).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'Expense not found')),
      );

      // act
      final result = await usecase(
        const MarkSplitPaidParams(
          expenseId: tExpenseId,
          userId: tUserId,
          isPaid: true,
        ),
      );

      // assert
      expect(result, const Left(ServerFailure(message: 'Expense not found')));
      verifyNever(
        () => mockAnnouncementService.announceSplitPaid(
          expense: any(named: 'expense'),
          split: any(named: 'split'),
        ),
      );
    });

    test('should return ServerFailure when user split is not found', () async {
      // arrange
      when(
        () => mockRepository.getExpenseById(tExpenseId),
      ).thenAnswer((_) async => Right(tExpenseBeforePay));
      when(
        () => mockRepository.markSplitAsPaid(
          expenseId: any(named: 'expenseId'),
          userId: any(named: 'userId'),
          isPaid: any(named: 'isPaid'),
        ),
      ).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'User split not found')),
      );

      // act
      final result = await usecase(
        const MarkSplitPaidParams(
          expenseId: tExpenseId,
          userId: 'unknown-user',
          isPaid: true,
        ),
      );

      // assert
      expect(
        result,
        const Left(ServerFailure(message: 'User split not found')),
      );
      verifyNever(
        () => mockAnnouncementService.announceSplitPaid(
          expense: any(named: 'expense'),
          split: any(named: 'split'),
        ),
      );
    });

    test('should return NetworkFailure when there is no internet', () async {
      // arrange
      when(
        () => mockRepository.getExpenseById(tExpenseId),
      ).thenAnswer((_) async => Right(tExpenseBeforePay));
      when(
        () => mockRepository.markSplitAsPaid(
          expenseId: any(named: 'expenseId'),
          userId: any(named: 'userId'),
          isPaid: any(named: 'isPaid'),
        ),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      // act
      final result = await usecase(
        const MarkSplitPaidParams(
          expenseId: tExpenseId,
          userId: tUserId,
          isPaid: true,
        ),
      );

      // assert
      expect(result, const Left(NetworkFailure()));
      verifyNever(
        () => mockAnnouncementService.announceSplitPaid(
          expense: any(named: 'expense'),
          split: any(named: 'split'),
        ),
      );
    });
  });

  group('MarkSplitPaidParams', () {
    test('should have correct props', () {
      const params = MarkSplitPaidParams(
        expenseId: tExpenseId,
        userId: tUserId,
        isPaid: true,
      );
      expect(params.props, [tExpenseId, tUserId, true]);
    });

    test('should be equal when all props are the same', () {
      const params1 = MarkSplitPaidParams(
        expenseId: 'expense-1',
        userId: 'user-1',
        isPaid: true,
      );
      const params2 = MarkSplitPaidParams(
        expenseId: 'expense-1',
        userId: 'user-1',
        isPaid: true,
      );
      expect(params1, params2);
    });

    test('should not be equal when expenseId is different', () {
      const params1 = MarkSplitPaidParams(
        expenseId: 'expense-1',
        userId: 'user-1',
        isPaid: true,
      );
      const params2 = MarkSplitPaidParams(
        expenseId: 'expense-2',
        userId: 'user-1',
        isPaid: true,
      );
      expect(params1, isNot(params2));
    });

    test('should not be equal when isPaid is different', () {
      const params1 = MarkSplitPaidParams(
        expenseId: 'expense-1',
        userId: 'user-1',
        isPaid: true,
      );
      const params2 = MarkSplitPaidParams(
        expenseId: 'expense-1',
        userId: 'user-1',
        isPaid: false,
      );
      expect(params1, isNot(params2));
    });
  });
}
