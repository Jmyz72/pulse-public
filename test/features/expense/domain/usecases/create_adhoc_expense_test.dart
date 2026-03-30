import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/expense/domain/entities/expense.dart';
import 'package:pulse/features/expense/domain/repositories/expense_repository.dart';
import 'package:pulse/features/expense/domain/usecases/create_adhoc_expense.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

void main() {
  late CreateAdHocExpense usecase;
  late MockExpenseRepository mockRepository;

  setUp(() {
    mockRepository = MockExpenseRepository();
    usecase = CreateAdHocExpense(mockRepository);
  });

  final tMasterExpense = Expense(
    id: '',
    ownerId: 'owner-1',
    title: 'Ad-hoc Dinner',
    totalAmount: 200.0,
    date: DateTime(2024, 1, 15),
    status: ExpenseStatus.pending,
    type: ExpenseType.adHoc,
    splits: const [],
  );

  final tCreatedMasterExpense = Expense(
    id: 'master-expense-1',
    ownerId: 'owner-1',
    title: 'Ad-hoc Dinner',
    totalAmount: 200.0,
    date: DateTime(2024, 1, 15),
    status: ExpenseStatus.pending,
    type: ExpenseType.adHoc,
    linkedExpenseIds: const ['linked-1', 'linked-2'],
    adHocParticipantIds: const ['user-1', 'user-2'],
    splits: const [],
  );

  const tParticipantIds = ['user-1', 'user-2'];
  const tChatRoomIdsByParticipant = {
    'user-1': 'chat-1',
    'user-2': 'chat-2',
  };

  setUpAll(() {
    registerFallbackValue(tMasterExpense);
  });

  group('CreateAdHocExpense', () {
    test('should return master expense with linked IDs when successful', () async {
      // arrange
      when(() => mockRepository.createAdHocExpense(
            masterExpense: any(named: 'masterExpense'),
            participantIds: any(named: 'participantIds'),
            chatRoomIdsByParticipant: any(named: 'chatRoomIdsByParticipant'),
          )).thenAnswer((_) async => Right(tCreatedMasterExpense));

      // act
      final result = await usecase(CreateAdHocExpenseParams(
        masterExpense: tMasterExpense,
        participantIds: tParticipantIds,
        chatRoomIdsByParticipant: tChatRoomIdsByParticipant,
      ));

      // assert
      expect(result, Right(tCreatedMasterExpense));
      verify(() => mockRepository.createAdHocExpense(
            masterExpense: tMasterExpense,
            participantIds: tParticipantIds,
            chatRoomIdsByParticipant: tChatRoomIdsByParticipant,
          )).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return ServerFailure when repository throws server error', () async {
      // arrange
      when(() => mockRepository.createAdHocExpense(
            masterExpense: any(named: 'masterExpense'),
            participantIds: any(named: 'participantIds'),
            chatRoomIdsByParticipant: any(named: 'chatRoomIdsByParticipant'),
          )).thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to create ad-hoc expense')));

      // act
      final result = await usecase(CreateAdHocExpenseParams(
        masterExpense: tMasterExpense,
        participantIds: tParticipantIds,
        chatRoomIdsByParticipant: tChatRoomIdsByParticipant,
      ));

      // assert
      expect(result, const Left(ServerFailure(message: 'Failed to create ad-hoc expense')));
    });

    test('should return NetworkFailure when there is no internet', () async {
      // arrange
      when(() => mockRepository.createAdHocExpense(
            masterExpense: any(named: 'masterExpense'),
            participantIds: any(named: 'participantIds'),
            chatRoomIdsByParticipant: any(named: 'chatRoomIdsByParticipant'),
          )).thenAnswer((_) async => const Left(NetworkFailure()));

      // act
      final result = await usecase(CreateAdHocExpenseParams(
        masterExpense: tMasterExpense,
        participantIds: tParticipantIds,
        chatRoomIdsByParticipant: tChatRoomIdsByParticipant,
      ));

      // assert
      expect(result, const Left(NetworkFailure()));
    });
  });

  group('CreateAdHocExpenseParams', () {
    test('should have correct props', () {
      final params = CreateAdHocExpenseParams(
        masterExpense: tMasterExpense,
        participantIds: tParticipantIds,
        chatRoomIdsByParticipant: tChatRoomIdsByParticipant,
      );
      expect(params.props, [tMasterExpense, tParticipantIds, tChatRoomIdsByParticipant]);
    });

    test('should be equal when all props are the same', () {
      final params1 = CreateAdHocExpenseParams(
        masterExpense: tMasterExpense,
        participantIds: tParticipantIds,
        chatRoomIdsByParticipant: tChatRoomIdsByParticipant,
      );
      final params2 = CreateAdHocExpenseParams(
        masterExpense: tMasterExpense,
        participantIds: tParticipantIds,
        chatRoomIdsByParticipant: tChatRoomIdsByParticipant,
      );
      expect(params1, params2);
    });

    test('should not be equal when masterExpense is different', () {
      final params1 = CreateAdHocExpenseParams(
        masterExpense: tMasterExpense,
        participantIds: tParticipantIds,
        chatRoomIdsByParticipant: tChatRoomIdsByParticipant,
      );
      final params2 = CreateAdHocExpenseParams(
        masterExpense: tMasterExpense.copyWith(title: 'Different'),
        participantIds: tParticipantIds,
        chatRoomIdsByParticipant: tChatRoomIdsByParticipant,
      );
      expect(params1, isNot(params2));
    });

    test('should not be equal when participantIds is different', () {
      final params1 = CreateAdHocExpenseParams(
        masterExpense: tMasterExpense,
        participantIds: const ['user-1', 'user-2'],
        chatRoomIdsByParticipant: tChatRoomIdsByParticipant,
      );
      final params2 = CreateAdHocExpenseParams(
        masterExpense: tMasterExpense,
        participantIds: const ['user-1', 'user-3'],
        chatRoomIdsByParticipant: tChatRoomIdsByParticipant,
      );
      expect(params1, isNot(params2));
    });
  });
}
