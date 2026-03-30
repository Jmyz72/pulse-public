import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/expense/domain/repositories/expense_repository.dart';
import 'package:pulse/features/expense/domain/usecases/delete_expense.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

void main() {
  late DeleteExpense usecase;
  late MockExpenseRepository mockRepository;

  setUp(() {
    mockRepository = MockExpenseRepository();
    usecase = DeleteExpense(mockRepository);
  });

  const tExpenseId = 'expense-1';

  test('should return void when deletion is successful', () async {
    // arrange
    when(() => mockRepository.deleteExpense(tExpenseId))
        .thenAnswer((_) async => const Right(null));

    // act
    final result = await usecase(const DeleteExpenseParams(id: tExpenseId));

    // assert
    expect(result, const Right(null));
    verify(() => mockRepository.deleteExpense(tExpenseId)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return ServerFailure when deletion fails', () async {
    // arrange
    when(() => mockRepository.deleteExpense(tExpenseId))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to delete')));

    // act
    final result = await usecase(const DeleteExpenseParams(id: tExpenseId));

    // assert
    expect(result, const Left(ServerFailure(message: 'Failed to delete')));
    verify(() => mockRepository.deleteExpense(tExpenseId)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return NetworkFailure when there is no internet', () async {
    // arrange
    when(() => mockRepository.deleteExpense(tExpenseId))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(const DeleteExpenseParams(id: tExpenseId));

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockRepository.deleteExpense(tExpenseId)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
