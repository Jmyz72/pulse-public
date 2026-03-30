import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/expense/domain/entities/expense.dart';
import 'package:pulse/features/expense/domain/repositories/expense_repository.dart';
import 'package:pulse/features/expense/domain/usecases/get_expenses.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

void main() {
  late GetExpenses usecase;
  late MockExpenseRepository mockRepository;

  setUp(() {
    mockRepository = MockExpenseRepository();
    usecase = GetExpenses(mockRepository);
  });

  const tChatRoomIds = ['chat-1', 'chat-2'];

  final tExpenses = [
    Expense(
      id: '1',
      ownerId: 'user-1',
      title: 'Groceries',
      totalAmount: 50.0,
      date: DateTime(2024, 1, 1),
      chatRoomId: 'chat-1',
      status: ExpenseStatus.pending,
      type: ExpenseType.group,
      splits: const [],
    ),
    Expense(
      id: '2',
      ownerId: 'user-1',
      title: 'Electricity Bill',
      totalAmount: 100.0,
      date: DateTime(2024, 1, 5),
      chatRoomId: 'chat-1',
      status: ExpenseStatus.pending,
      type: ExpenseType.group,
      splits: const [],
    ),
  ];

  test('should return list of expenses when successful', () async {
    // arrange
    when(() => mockRepository.getExpenses(tChatRoomIds))
        .thenAnswer((_) async => Right(tExpenses));

    // act
    final result = await usecase(const GetExpensesParams(chatRoomIds: tChatRoomIds));

    // assert
    expect(result, Right(tExpenses));
    verify(() => mockRepository.getExpenses(tChatRoomIds)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return empty list when no expenses exist', () async {
    // arrange
    when(() => mockRepository.getExpenses(tChatRoomIds))
        .thenAnswer((_) async => const Right([]));

    // act
    final result = await usecase(const GetExpensesParams(chatRoomIds: tChatRoomIds));

    // assert
    expect(result, const Right(<Expense>[]));
    verify(() => mockRepository.getExpenses(tChatRoomIds)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return ServerFailure when server error occurs', () async {
    // arrange
    when(() => mockRepository.getExpenses(tChatRoomIds))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Server error')));

    // act
    final result = await usecase(const GetExpensesParams(chatRoomIds: tChatRoomIds));

    // assert
    expect(result, const Left(ServerFailure(message: 'Server error')));
    verify(() => mockRepository.getExpenses(tChatRoomIds)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return NetworkFailure when there is no internet', () async {
    // arrange
    when(() => mockRepository.getExpenses(tChatRoomIds))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(const GetExpensesParams(chatRoomIds: tChatRoomIds));

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockRepository.getExpenses(tChatRoomIds)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
