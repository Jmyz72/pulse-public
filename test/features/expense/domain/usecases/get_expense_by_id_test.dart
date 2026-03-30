import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/expense/domain/entities/expense.dart';
import 'package:pulse/features/expense/domain/repositories/expense_repository.dart';
import 'package:pulse/features/expense/domain/usecases/get_expense_by_id.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

void main() {
  late GetExpenseById usecase;
  late MockExpenseRepository mockRepository;

  setUp(() {
    mockRepository = MockExpenseRepository();
    usecase = GetExpenseById(mockRepository);
  });

  const tExpenseId = 'expense-1';

  final tExpense = Expense(
    id: tExpenseId,
    ownerId: 'owner-1',
    title: 'Test Expense',
    totalAmount: 100.0,
    date: DateTime(2024, 1, 15),
    status: ExpenseStatus.pending,
    type: ExpenseType.group,
    chatRoomId: 'chat-1',
    splits: const [],
  );

  group('GetExpenseById', () {
    test('should return expense when repository call is successful', () async {
      // arrange
      when(() => mockRepository.getExpenseById(tExpenseId))
          .thenAnswer((_) async => Right(tExpense));

      // act
      final result = await usecase(const GetExpenseByIdParams(id: tExpenseId));

      // assert
      expect(result, Right(tExpense));
      verify(() => mockRepository.getExpenseById(tExpenseId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return ServerFailure when expense is not found', () async {
      // arrange
      when(() => mockRepository.getExpenseById(tExpenseId))
          .thenAnswer((_) async => const Left(ServerFailure(message: 'Expense not found')));

      // act
      final result = await usecase(const GetExpenseByIdParams(id: tExpenseId));

      // assert
      expect(result, const Left(ServerFailure(message: 'Expense not found')));
      verify(() => mockRepository.getExpenseById(tExpenseId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return NetworkFailure when there is no internet', () async {
      // arrange
      when(() => mockRepository.getExpenseById(tExpenseId))
          .thenAnswer((_) async => const Left(NetworkFailure()));

      // act
      final result = await usecase(const GetExpenseByIdParams(id: tExpenseId));

      // assert
      expect(result, const Left(NetworkFailure()));
      verify(() => mockRepository.getExpenseById(tExpenseId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });

  group('GetExpenseByIdParams', () {
    test('should have correct props', () {
      const params = GetExpenseByIdParams(id: tExpenseId);
      expect(params.props, [tExpenseId]);
    });

    test('should be equal when id is the same', () {
      const params1 = GetExpenseByIdParams(id: 'expense-1');
      const params2 = GetExpenseByIdParams(id: 'expense-1');
      expect(params1, params2);
    });

    test('should not be equal when id is different', () {
      const params1 = GetExpenseByIdParams(id: 'expense-1');
      const params2 = GetExpenseByIdParams(id: 'expense-2');
      expect(params1, isNot(params2));
    });
  });
}
