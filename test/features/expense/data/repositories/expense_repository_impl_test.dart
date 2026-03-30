import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/exceptions.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/core/network/network_info.dart';
import 'package:pulse/features/expense/data/datasources/expense_remote_datasource.dart';
import 'package:pulse/features/expense/data/models/expense_model.dart';
import 'package:pulse/features/expense/data/repositories/expense_repository_impl.dart';
import 'package:pulse/features/expense/domain/entities/expense.dart';
import 'package:pulse/features/expense/domain/entities/expense_item.dart';
import 'package:pulse/features/expense/domain/entities/expense_split.dart';

class MockExpenseRemoteDataSource extends Mock
    implements ExpenseRemoteDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late ExpenseRepositoryImpl repository;
  late MockExpenseRemoteDataSource mockRemoteDataSource;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockRemoteDataSource = MockExpenseRemoteDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = ExpenseRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  final tDate = DateTime(2024, 1, 15);

  final tExpenseModel = ExpenseModel(
    id: 'expense-1',
    ownerId: 'owner-1',
    chatRoomId: 'chat-1',
    title: 'Test Expense',
    totalAmount: 100.0,
    date: tDate,
    status: ExpenseStatus.pending,
    type: ExpenseType.group,
    splits: const [],
  );

  final tExpenseModel2 = ExpenseModel(
    id: 'expense-2',
    ownerId: 'owner-1',
    chatRoomId: 'chat-1',
    title: 'Another Expense',
    totalAmount: 50.0,
    date: tDate,
    status: ExpenseStatus.pending,
    type: ExpenseType.group,
    splits: const [],
  );

  final tExpense = Expense(
    id: 'expense-1',
    ownerId: 'owner-1',
    chatRoomId: 'chat-1',
    title: 'Test Expense',
    totalAmount: 100.0,
    date: tDate,
    status: ExpenseStatus.pending,
    type: ExpenseType.group,
    splits: const [],
  );

  final tAdHocMasterModel = ExpenseModel(
    id: 'master-1',
    ownerId: 'owner-1',
    title: 'Ad-hoc Expense',
    totalAmount: 150.0,
    date: tDate,
    type: ExpenseType.adHoc,
    linkedExpenseIds: const ['linked-1', 'linked-2'],
    adHocParticipantIds: const ['owner-1', 'user-1', 'user-2'],
    splits: const [],
  );

  final tExpenseWithItems = ExpenseModel(
    id: 'expense-1',
    ownerId: 'owner-1',
    chatRoomId: 'chat-1',
    title: 'Test Expense',
    totalAmount: 100.0,
    date: tDate,
    items: const [
      ExpenseItem(id: 'item-1', name: 'Item 1', price: 50.0),
      ExpenseItem(id: 'item-2', name: 'Item 2', price: 50.0),
    ],
    splits: const [
      ExpenseSplit(userId: 'user-1', userName: 'User 1', amount: 50.0),
      ExpenseSplit(userId: 'user-2', userName: 'User 2', amount: 50.0),
    ],
  );

  const tChatRoomIds = ['chat-1', 'chat-2'];

  setUpAll(() {
    registerFallbackValue(tExpenseModel);
    registerFallbackValue(tExpense);
  });

  void runTestsOnline(Function body) {
    group('device is online', () {
      setUp(() {
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      });
      body();
    });
  }

  void runTestsOffline(Function body) {
    group('device is offline', () {
      setUp(() {
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      });
      body();
    });
  }

  group('getExpenses', () {
    runTestsOnline(() {
      test('should return list of expenses when call is successful', () async {
        // arrange
        when(
          () => mockRemoteDataSource.getExpenses(tChatRoomIds),
        ).thenAnswer((_) async => [tExpenseModel, tExpenseModel2]);

        // act
        final result = await repository.getExpenses(tChatRoomIds);

        // assert
        expect(result.isRight(), true);
        result.fold((l) => fail('Expected Right'), (r) {
          expect(r.length, 2);
          expect(r[0].id, 'expense-1');
          expect(r[1].id, 'expense-2');
        });
        verify(() => mockRemoteDataSource.getExpenses(tChatRoomIds)).called(1);
      });

      test(
        'should return ServerFailure when ServerException is thrown',
        () async {
          // arrange
          when(
            () => mockRemoteDataSource.getExpenses(tChatRoomIds),
          ).thenThrow(const ServerException(message: 'Server error'));

          // act
          final result = await repository.getExpenses(tChatRoomIds);

          // assert
          expect(result, const Left(ServerFailure(message: 'Server error')));
        },
      );
    });

    runTestsOffline(() {
      test('should return NetworkFailure when offline', () async {
        // act
        final result = await repository.getExpenses(tChatRoomIds);

        // assert
        expect(result, const Left(NetworkFailure()));
        verifyNever(() => mockRemoteDataSource.getExpenses(any()));
      });
    });
  });

  group('getExpenseById', () {
    const tExpenseId = 'expense-1';

    runTestsOnline(() {
      test('should return expense when call is successful', () async {
        // arrange
        when(
          () => mockRemoteDataSource.getExpenseById(tExpenseId),
        ).thenAnswer((_) async => tExpenseModel);

        // act
        final result = await repository.getExpenseById(tExpenseId);

        // assert
        expect(result, Right(tExpenseModel));
        verify(() => mockRemoteDataSource.getExpenseById(tExpenseId)).called(1);
      });

      test('should return ServerFailure when expense not found', () async {
        // arrange
        when(
          () => mockRemoteDataSource.getExpenseById(tExpenseId),
        ).thenThrow(const ServerException(message: 'Expense not found'));

        // act
        final result = await repository.getExpenseById(tExpenseId);

        // assert
        expect(result, const Left(ServerFailure(message: 'Expense not found')));
      });
    });

    runTestsOffline(() {
      test('should return NetworkFailure when offline', () async {
        // act
        final result = await repository.getExpenseById(tExpenseId);

        // assert
        expect(result, const Left(NetworkFailure()));
        verifyNever(() => mockRemoteDataSource.getExpenseById(any()));
      });
    });
  });

  group('createExpense', () {
    runTestsOnline(() {
      test('should return created expense when call is successful', () async {
        // arrange
        when(
          () => mockRemoteDataSource.createExpense(any()),
        ).thenAnswer((_) async => tExpenseModel);

        // act
        final result = await repository.createExpense(tExpense);

        // assert
        expect(result.isRight(), true);
        result.fold(
          (l) => fail('Expected Right'),
          (r) => expect(r.id, tExpenseModel.id),
        );
        verify(() => mockRemoteDataSource.createExpense(any())).called(1);
      });

      test(
        'should return ServerFailure when ServerException is thrown',
        () async {
          // arrange
          when(
            () => mockRemoteDataSource.createExpense(any()),
          ).thenThrow(const ServerException(message: 'Create failed'));

          // act
          final result = await repository.createExpense(tExpense);

          // assert
          expect(result, const Left(ServerFailure(message: 'Create failed')));
        },
      );
    });

    runTestsOffline(() {
      test('should return NetworkFailure when offline', () async {
        // act
        final result = await repository.createExpense(tExpense);

        // assert
        expect(result, const Left(NetworkFailure()));
        verifyNever(() => mockRemoteDataSource.createExpense(any()));
      });
    });
  });

  group('updateExpense', () {
    runTestsOnline(() {
      test('should return updated expense when call is successful', () async {
        // arrange
        when(
          () => mockRemoteDataSource.updateExpense(any()),
        ).thenAnswer((_) async => tExpenseModel);

        // act
        final result = await repository.updateExpense(tExpense);

        // assert
        expect(result.isRight(), true);
        verify(() => mockRemoteDataSource.updateExpense(any())).called(1);
      });

      test(
        'should return ServerFailure when ServerException is thrown',
        () async {
          // arrange
          when(
            () => mockRemoteDataSource.updateExpense(any()),
          ).thenThrow(const ServerException(message: 'Update failed'));

          // act
          final result = await repository.updateExpense(tExpense);

          // assert
          expect(result, const Left(ServerFailure(message: 'Update failed')));
        },
      );
    });

    runTestsOffline(() {
      test('should return NetworkFailure when offline', () async {
        // act
        final result = await repository.updateExpense(tExpense);

        // assert
        expect(result, const Left(NetworkFailure()));
        verifyNever(() => mockRemoteDataSource.updateExpense(any()));
      });
    });
  });

  group('deleteExpense', () {
    const tExpenseId = 'expense-1';

    runTestsOnline(() {
      test('should return void when delete is successful', () async {
        // arrange
        when(
          () => mockRemoteDataSource.deleteExpense(tExpenseId),
        ).thenAnswer((_) async {});

        // act
        final result = await repository.deleteExpense(tExpenseId);

        // assert
        expect(result, const Right(null));
        verify(() => mockRemoteDataSource.deleteExpense(tExpenseId)).called(1);
      });

      test(
        'should return ServerFailure when ServerException is thrown',
        () async {
          // arrange
          when(
            () => mockRemoteDataSource.deleteExpense(tExpenseId),
          ).thenThrow(const ServerException(message: 'Delete failed'));

          // act
          final result = await repository.deleteExpense(tExpenseId);

          // assert
          expect(result, const Left(ServerFailure(message: 'Delete failed')));
        },
      );
    });

    runTestsOffline(() {
      test('should return NetworkFailure when offline', () async {
        // act
        final result = await repository.deleteExpense(tExpenseId);

        // assert
        expect(result, const Left(NetworkFailure()));
        verifyNever(() => mockRemoteDataSource.deleteExpense(any()));
      });
    });
  });

  group('getExpensesByChatRoom', () {
    const tChatRoomId = 'chat-1';

    runTestsOnline(() {
      test('should return list of expenses when call is successful', () async {
        // arrange
        when(
          () => mockRemoteDataSource.getExpensesByChatRoom(tChatRoomId),
        ).thenAnswer((_) async => [tExpenseModel]);

        // act
        final result = await repository.getExpensesByChatRoom(tChatRoomId);

        // assert
        expect(result.isRight(), true);
        result.fold((l) => fail('Expected Right'), (r) => expect(r.length, 1));
        verify(
          () => mockRemoteDataSource.getExpensesByChatRoom(tChatRoomId),
        ).called(1);
      });

      test(
        'should return ServerFailure when ServerException is thrown',
        () async {
          // arrange
          when(
            () => mockRemoteDataSource.getExpensesByChatRoom(tChatRoomId),
          ).thenThrow(const ServerException(message: 'Server error'));

          // act
          final result = await repository.getExpensesByChatRoom(tChatRoomId);

          // assert
          expect(result, const Left(ServerFailure(message: 'Server error')));
        },
      );
    });

    runTestsOffline(() {
      test('should return NetworkFailure when offline', () async {
        // act
        final result = await repository.getExpensesByChatRoom(tChatRoomId);

        // assert
        expect(result, const Left(NetworkFailure()));
        verifyNever(() => mockRemoteDataSource.getExpensesByChatRoom(any()));
      });
    });
  });

  group('createAdHocExpense', () {
    final tMasterExpense = Expense(
      id: '',
      ownerId: 'owner-1',
      title: 'Ad-hoc Expense',
      totalAmount: 150.0,
      date: tDate,
      type: ExpenseType.adHoc,
      splits: const [],
    );

    const tParticipantIds = ['owner-1', 'user-1', 'user-2'];
    const tChatRoomIdsByParticipant = {'user-1': 'chat-1', 'user-2': 'chat-2'};

    runTestsOnline(() {
      test(
        'should return created master expense when call is successful',
        () async {
          // arrange
          when(
            () => mockRemoteDataSource.createAdHocExpense(
              masterExpense: any(named: 'masterExpense'),
              participantIds: any(named: 'participantIds'),
              chatRoomIdsByParticipant: any(named: 'chatRoomIdsByParticipant'),
            ),
          ).thenAnswer((_) async => tAdHocMasterModel);

          // act
          final result = await repository.createAdHocExpense(
            masterExpense: tMasterExpense,
            participantIds: tParticipantIds,
            chatRoomIdsByParticipant: tChatRoomIdsByParticipant,
          );

          // assert
          expect(result.isRight(), true);
          result.fold((l) => fail('Expected Right'), (r) {
            expect(r.id, 'master-1');
            expect(r.type, ExpenseType.adHoc);
            expect(r.linkedExpenseIds, ['linked-1', 'linked-2']);
          });
        },
      );

      test(
        'should return ServerFailure when ServerException is thrown',
        () async {
          // arrange
          when(
            () => mockRemoteDataSource.createAdHocExpense(
              masterExpense: any(named: 'masterExpense'),
              participantIds: any(named: 'participantIds'),
              chatRoomIdsByParticipant: any(named: 'chatRoomIdsByParticipant'),
            ),
          ).thenThrow(const ServerException(message: 'Create ad-hoc failed'));

          // act
          final result = await repository.createAdHocExpense(
            masterExpense: tMasterExpense,
            participantIds: tParticipantIds,
            chatRoomIdsByParticipant: tChatRoomIdsByParticipant,
          );

          // assert
          expect(
            result,
            const Left(ServerFailure(message: 'Create ad-hoc failed')),
          );
        },
      );
    });

    runTestsOffline(() {
      test('should return NetworkFailure when offline', () async {
        // act
        final result = await repository.createAdHocExpense(
          masterExpense: tMasterExpense,
          participantIds: tParticipantIds,
          chatRoomIdsByParticipant: tChatRoomIdsByParticipant,
        );

        // assert
        expect(result, const Left(NetworkFailure()));
      });
    });
  });

  group('updateExpenseItems', () {
    const tExpenseId = 'expense-1';
    const tItems = [ExpenseItem(id: 'item-1', name: 'New Item', price: 75.0)];

    runTestsOnline(() {
      test('should return updated expense when call is successful', () async {
        // arrange
        when(
          () => mockRemoteDataSource.updateExpenseItems(
            expenseId: any(named: 'expenseId'),
            items: any(named: 'items'),
            taxPercent: any(named: 'taxPercent'),
            serviceChargePercent: any(named: 'serviceChargePercent'),
            discountPercent: any(named: 'discountPercent'),
          ),
        ).thenAnswer((_) async => tExpenseWithItems);

        // act
        final result = await repository.updateExpenseItems(
          expenseId: tExpenseId,
          items: tItems,
          taxPercent: 10.0,
        );

        // assert
        expect(result.isRight(), true);
        verify(
          () => mockRemoteDataSource.updateExpenseItems(
            expenseId: tExpenseId,
            items: tItems,
            taxPercent: 10.0,
            serviceChargePercent: null,
            discountPercent: null,
          ),
        ).called(1);
      });

      test(
        'should return ServerFailure when ServerException is thrown',
        () async {
          // arrange
          when(
            () => mockRemoteDataSource.updateExpenseItems(
              expenseId: any(named: 'expenseId'),
              items: any(named: 'items'),
              taxPercent: any(named: 'taxPercent'),
              serviceChargePercent: any(named: 'serviceChargePercent'),
              discountPercent: any(named: 'discountPercent'),
            ),
          ).thenThrow(const ServerException(message: 'Update items failed'));

          // act
          final result = await repository.updateExpenseItems(
            expenseId: tExpenseId,
            items: tItems,
          );

          // assert
          expect(
            result,
            const Left(ServerFailure(message: 'Update items failed')),
          );
        },
      );
    });

    runTestsOffline(() {
      test('should return NetworkFailure when offline', () async {
        // act
        final result = await repository.updateExpenseItems(
          expenseId: tExpenseId,
          items: tItems,
        );

        // assert
        expect(result, const Left(NetworkFailure()));
      });
    });
  });

  group('selectItems', () {
    const tExpenseId = 'expense-1';
    const tUserId = 'user-1';
    const tItemIds = ['item-1', 'item-2'];

    runTestsOnline(() {
      test('should return updated expense when call is successful', () async {
        // arrange
        when(
          () => mockRemoteDataSource.selectItems(
            expenseId: any(named: 'expenseId'),
            userId: any(named: 'userId'),
            itemIds: any(named: 'itemIds'),
          ),
        ).thenAnswer((_) async => tExpenseWithItems);

        // act
        final result = await repository.selectItems(
          expenseId: tExpenseId,
          userId: tUserId,
          itemIds: tItemIds,
        );

        // assert
        expect(result.isRight(), true);
        verify(
          () => mockRemoteDataSource.selectItems(
            expenseId: tExpenseId,
            userId: tUserId,
            itemIds: tItemIds,
          ),
        ).called(1);
      });

      test(
        'should return ServerFailure when ServerException is thrown',
        () async {
          // arrange
          when(
            () => mockRemoteDataSource.selectItems(
              expenseId: any(named: 'expenseId'),
              userId: any(named: 'userId'),
              itemIds: any(named: 'itemIds'),
            ),
          ).thenThrow(const ServerException(message: 'Select items failed'));

          // act
          final result = await repository.selectItems(
            expenseId: tExpenseId,
            userId: tUserId,
            itemIds: tItemIds,
          );

          // assert
          expect(
            result,
            const Left(ServerFailure(message: 'Select items failed')),
          );
        },
      );

      test(
        'should return lock failure message when remote rejects paid selection changes',
        () async {
          when(
            () => mockRemoteDataSource.selectItems(
              expenseId: any(named: 'expenseId'),
              userId: any(named: 'userId'),
              itemIds: any(named: 'itemIds'),
            ),
          ).thenThrow(
            const ServerException(
              message:
                  'This item is locked because payment is under review or already recorded',
            ),
          );

          final result = await repository.selectItems(
            expenseId: tExpenseId,
            userId: tUserId,
            itemIds: tItemIds,
          );

          expect(
            result,
            const Left(
              ServerFailure(
                message:
                    'This item is locked because payment is under review or already recorded',
              ),
            ),
          );
        },
      );

      test(
        'should return review lock failure message when remote rejects pending-review selection changes',
        () async {
          when(
            () => mockRemoteDataSource.selectItems(
              expenseId: any(named: 'expenseId'),
              userId: any(named: 'userId'),
              itemIds: any(named: 'itemIds'),
            ),
          ).thenThrow(
            const ServerException(
              message:
                  'Your payment proof is waiting for owner review; item selection is locked',
            ),
          );

          final result = await repository.selectItems(
            expenseId: tExpenseId,
            userId: tUserId,
            itemIds: tItemIds,
          );

          expect(
            result,
            const Left(
              ServerFailure(
                message:
                    'Your payment proof is waiting for owner review; item selection is locked',
              ),
            ),
          );
        },
      );
    });

    runTestsOffline(() {
      test('should return NetworkFailure when offline', () async {
        // act
        final result = await repository.selectItems(
          expenseId: tExpenseId,
          userId: tUserId,
          itemIds: tItemIds,
        );

        // assert
        expect(result, const Left(NetworkFailure()));
      });
    });
  });

  group('markSplitAsPaid', () {
    const tExpenseId = 'expense-1';
    const tUserId = 'user-1';

    final tExpenseWithPaidSplit = ExpenseModel(
      id: 'expense-1',
      ownerId: 'owner-1',
      chatRoomId: 'chat-1',
      title: 'Test Expense',
      totalAmount: 100.0,
      date: tDate,
      splits: [
        ExpenseSplit(
          userId: 'user-1',
          userName: 'User 1',
          amount: 50.0,
          isPaid: true,
          paidAt: tDate,
        ),
        const ExpenseSplit(userId: 'user-2', userName: 'User 2', amount: 50.0),
      ],
    );

    runTestsOnline(() {
      test('should return updated expense when marking as paid', () async {
        // arrange
        when(
          () => mockRemoteDataSource.markSplitAsPaid(
            expenseId: any(named: 'expenseId'),
            userId: any(named: 'userId'),
            isPaid: any(named: 'isPaid'),
          ),
        ).thenAnswer((_) async => tExpenseWithPaidSplit);

        // act
        final result = await repository.markSplitAsPaid(
          expenseId: tExpenseId,
          userId: tUserId,
          isPaid: true,
        );

        // assert
        expect(result.isRight(), true);
        result.fold((l) => fail('Expected Right'), (r) {
          final userSplit = r.splits.firstWhere((s) => s.userId == tUserId);
          expect(userSplit.isPaid, true);
        });
      });

      test(
        'should return ServerFailure when ServerException is thrown',
        () async {
          // arrange
          when(
            () => mockRemoteDataSource.markSplitAsPaid(
              expenseId: any(named: 'expenseId'),
              userId: any(named: 'userId'),
              isPaid: any(named: 'isPaid'),
            ),
          ).thenThrow(const ServerException(message: 'Mark paid failed'));

          // act
          final result = await repository.markSplitAsPaid(
            expenseId: tExpenseId,
            userId: tUserId,
            isPaid: true,
          );

          // assert
          expect(
            result,
            const Left(ServerFailure(message: 'Mark paid failed')),
          );
        },
      );
    });

    runTestsOffline(() {
      test('should return NetworkFailure when offline', () async {
        // act
        final result = await repository.markSplitAsPaid(
          expenseId: tExpenseId,
          userId: tUserId,
          isPaid: true,
        );

        // assert
        expect(result, const Left(NetworkFailure()));
      });
    });
  });

  group('syncLinkedExpenses', () {
    const tMasterExpenseId = 'master-1';

    runTestsOnline(() {
      test('should return void when sync is successful', () async {
        // arrange
        when(
          () => mockRemoteDataSource.syncLinkedExpenses(tMasterExpenseId),
        ).thenAnswer((_) async {});

        // act
        final result = await repository.syncLinkedExpenses(tMasterExpenseId);

        // assert
        expect(result, const Right(null));
        verify(
          () => mockRemoteDataSource.syncLinkedExpenses(tMasterExpenseId),
        ).called(1);
      });

      test(
        'should return ServerFailure when ServerException is thrown',
        () async {
          // arrange
          when(
            () => mockRemoteDataSource.syncLinkedExpenses(tMasterExpenseId),
          ).thenThrow(const ServerException(message: 'Sync failed'));

          // act
          final result = await repository.syncLinkedExpenses(tMasterExpenseId);

          // assert
          expect(result, const Left(ServerFailure(message: 'Sync failed')));
        },
      );
    });

    runTestsOffline(() {
      test('should return NetworkFailure when offline', () async {
        // act
        final result = await repository.syncLinkedExpenses(tMasterExpenseId);

        // assert
        expect(result, const Left(NetworkFailure()));
        verifyNever(() => mockRemoteDataSource.syncLinkedExpenses(any()));
      });
    });
  });

  group('getExpensesForUser', () {
    const tUserId = 'user-1';

    runTestsOnline(() {
      test('should return list of expenses when call is successful', () async {
        // arrange
        when(
          () => mockRemoteDataSource.getExpensesForUser(tUserId),
        ).thenAnswer((_) async => [tExpenseModel, tAdHocMasterModel]);

        // act
        final result = await repository.getExpensesForUser(tUserId);

        // assert
        expect(result.isRight(), true);
        result.fold((l) => fail('Expected Right'), (r) => expect(r.length, 2));
        verify(
          () => mockRemoteDataSource.getExpensesForUser(tUserId),
        ).called(1);
      });

      test(
        'should return ServerFailure when ServerException is thrown',
        () async {
          // arrange
          when(
            () => mockRemoteDataSource.getExpensesForUser(tUserId),
          ).thenThrow(const ServerException(message: 'Server error'));

          // act
          final result = await repository.getExpensesForUser(tUserId);

          // assert
          expect(result, const Left(ServerFailure(message: 'Server error')));
        },
      );
    });

    runTestsOffline(() {
      test('should return NetworkFailure when offline', () async {
        // act
        final result = await repository.getExpensesForUser(tUserId);

        // assert
        expect(result, const Left(NetworkFailure()));
        verifyNever(() => mockRemoteDataSource.getExpensesForUser(any()));
      });
    });
  });
}
