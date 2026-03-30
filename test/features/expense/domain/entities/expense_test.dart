import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/expense/domain/entities/expense.dart';
import 'package:pulse/features/expense/domain/entities/expense_item.dart';
import 'package:pulse/features/expense/domain/entities/expense_split.dart';

void main() {
  group('ExpenseType', () {
    test('should have three types', () {
      expect(ExpenseType.values.length, 3);
      expect(ExpenseType.values, contains(ExpenseType.group));
      expect(ExpenseType.values, contains(ExpenseType.oneOnOne));
      expect(ExpenseType.values, contains(ExpenseType.adHoc));
    });
  });

  group('ExpenseStatus', () {
    test('should have two statuses', () {
      expect(ExpenseStatus.values.length, 2);
      expect(ExpenseStatus.values, contains(ExpenseStatus.pending));
      expect(ExpenseStatus.values, contains(ExpenseStatus.settled));
    });
  });

  group('Expense', () {
    final tDate = DateTime(2024, 1, 15);

    const tItems = [
      ExpenseItem(id: 'item-1', name: 'Item 1', price: 10.0, quantity: 2),
      ExpenseItem(id: 'item-2', name: 'Item 2', price: 15.0, quantity: 1),
    ];

    final tSplits = [
      const ExpenseSplit(
        userId: 'user-1',
        userName: 'User 1',
        amount: 17.5,
        isPaid: true,
      ),
      const ExpenseSplit(
        userId: 'user-2',
        userName: 'User 2',
        amount: 17.5,
        isPaid: false,
      ),
    ];

    final tExpense = Expense(
      id: 'expense-1',
      ownerId: 'owner-1',
      chatRoomId: 'chat-1',
      title: 'Test Expense',
      description: 'Test Description',
      totalAmount: 35.0,
      date: tDate,
      status: ExpenseStatus.pending,
      type: ExpenseType.group,
      items: tItems,
      taxPercent: 6.0,
      serviceChargePercent: 10.0,
      discountPercent: 5.0,
      splits: tSplits,
    );

    group('constructor', () {
      test('should create an Expense with required fields only', () {
        final expense = Expense(
          id: 'expense-1',
          ownerId: 'owner-1',
          title: 'Simple Expense',
          totalAmount: 100.0,
          date: tDate,
        );

        expect(expense.id, 'expense-1');
        expect(expense.ownerId, 'owner-1');
        expect(expense.chatRoomId, null);
        expect(expense.title, 'Simple Expense');
        expect(expense.description, null);
        expect(expense.totalAmount, 100.0);
        expect(expense.date, tDate);
        expect(expense.status, ExpenseStatus.pending); // default
        expect(expense.type, ExpenseType.group); // default
        expect(expense.items, []); // default
        expect(expense.taxPercent, null);
        expect(expense.serviceChargePercent, null);
        expect(expense.discountPercent, null);
        expect(expense.splits, []); // default
        expect(expense.masterExpenseId, null);
        expect(expense.linkedExpenseIds, null);
        expect(expense.adHocParticipantIds, null);
        expect(expense.imageUrl, null);
      });

      test('should create an Expense with all fields', () {
        expect(tExpense.id, 'expense-1');
        expect(tExpense.ownerId, 'owner-1');
        expect(tExpense.chatRoomId, 'chat-1');
        expect(tExpense.title, 'Test Expense');
        expect(tExpense.description, 'Test Description');
        expect(tExpense.totalAmount, 35.0);
        expect(tExpense.date, tDate);
        expect(tExpense.status, ExpenseStatus.pending);
        expect(tExpense.type, ExpenseType.group);
        expect(tExpense.items, tItems);
        expect(tExpense.taxPercent, 6.0);
        expect(tExpense.serviceChargePercent, 10.0);
        expect(tExpense.discountPercent, 5.0);
        expect(tExpense.splits, tSplits);
      });
    });

    group('itemsSubtotal', () {
      test('should calculate items subtotal correctly', () {
        // item-1: 10.0 * 2 = 20.0
        // item-2: 15.0 * 1 = 15.0
        // total: 35.0
        expect(tExpense.itemsSubtotal, 35.0);
      });

      test('should return 0 when no items', () {
        final expense = Expense(
          id: 'expense-1',
          ownerId: 'owner-1',
          title: 'Empty',
          totalAmount: 0,
          date: tDate,
          items: const [],
        );
        expect(expense.itemsSubtotal, 0);
      });
    });

    group('taxAmount', () {
      test('should calculate tax amount correctly', () {
        // subtotal: 35.0
        // tax: 35.0 * 6% = 2.10
        expect(tExpense.taxAmount, 2.1);
      });

      test('should return 0 when taxPercent is null', () {
        final expense = Expense(
          id: 'expense-1',
          ownerId: 'owner-1',
          title: 'No Tax',
          totalAmount: 100.0,
          date: tDate,
          items: tItems,
          taxPercent: null,
        );
        expect(expense.taxAmount, 0);
      });
    });

    group('serviceChargeAmount', () {
      test('should calculate service charge amount correctly', () {
        // subtotal: 35.0
        // service: 35.0 * 10% = 3.50
        expect(tExpense.serviceChargeAmount, 3.5);
      });

      test('should return 0 when serviceChargePercent is null', () {
        final expense = Expense(
          id: 'expense-1',
          ownerId: 'owner-1',
          title: 'No Service',
          totalAmount: 100.0,
          date: tDate,
          items: tItems,
          serviceChargePercent: null,
        );
        expect(expense.serviceChargeAmount, 0);
      });
    });

    group('discountAmount', () {
      test('should calculate discount amount correctly', () {
        // subtotal: 35.0
        // discount: 35.0 * 5% = 1.75
        expect(tExpense.discountAmount, 1.75);
      });

      test('should return 0 when discountPercent is null', () {
        final expense = Expense(
          id: 'expense-1',
          ownerId: 'owner-1',
          title: 'No Discount',
          totalAmount: 100.0,
          date: tDate,
          items: tItems,
          discountPercent: null,
        );
        expect(expense.discountAmount, 0);
      });
    });

    group('calculatedTotal', () {
      test('should calculate total with all adjustments', () {
        // subtotal: 35.0
        // + tax: 2.10
        // + service: 3.50
        // - discount: 1.75
        // = 38.85
        expect(tExpense.calculatedTotal, closeTo(38.85, 0.01));
      });

      test('should equal subtotal when no adjustments', () {
        final expense = Expense(
          id: 'expense-1',
          ownerId: 'owner-1',
          title: 'No Adjustments',
          totalAmount: 35.0,
          date: tDate,
          items: tItems,
        );
        expect(expense.calculatedTotal, 35.0);
      });
    });

    group('isAdHocMaster', () {
      test('should return true for ad-hoc expense without master ID', () {
        final expense = Expense(
          id: 'expense-1',
          ownerId: 'owner-1',
          title: 'Ad-hoc Master',
          totalAmount: 100.0,
          date: tDate,
          type: ExpenseType.adHoc,
          masterExpenseId: null,
        );
        expect(expense.isAdHocMaster, true);
      });

      test('should return false for ad-hoc expense with master ID', () {
        final expense = Expense(
          id: 'expense-1',
          ownerId: 'owner-1',
          title: 'Ad-hoc Linked',
          totalAmount: 100.0,
          date: tDate,
          type: ExpenseType.adHoc,
          masterExpenseId: 'master-1',
        );
        expect(expense.isAdHocMaster, false);
      });

      test('should return false for non-adhoc expense', () {
        expect(tExpense.isAdHocMaster, false);
      });
    });

    group('isAdHocLinked', () {
      test('should return true for ad-hoc expense with master ID', () {
        final expense = Expense(
          id: 'expense-1',
          ownerId: 'owner-1',
          title: 'Ad-hoc Linked',
          totalAmount: 100.0,
          date: tDate,
          type: ExpenseType.adHoc,
          masterExpenseId: 'master-1',
        );
        expect(expense.isAdHocLinked, true);
      });

      test('should return false for ad-hoc expense without master ID', () {
        final expense = Expense(
          id: 'expense-1',
          ownerId: 'owner-1',
          title: 'Ad-hoc Master',
          totalAmount: 100.0,
          date: tDate,
          type: ExpenseType.adHoc,
          masterExpenseId: null,
        );
        expect(expense.isAdHocLinked, false);
      });

      test('should return false for non-adhoc expense', () {
        expect(tExpense.isAdHocLinked, false);
      });
    });

    group('allItemsAssigned', () {
      test('should return true when all items have assigned users', () {
        final expense = Expense(
          id: 'expense-1',
          ownerId: 'owner-1',
          title: 'All Assigned',
          totalAmount: 100.0,
          date: tDate,
          items: const [
            ExpenseItem(
              id: 'item-1',
              name: 'Item 1',
              price: 10.0,
              assignedUserIds: ['user-1'],
            ),
            ExpenseItem(
              id: 'item-2',
              name: 'Item 2',
              price: 20.0,
              assignedUserIds: ['user-2'],
            ),
          ],
        );
        expect(expense.allItemsAssigned, true);
      });

      test('should return false when some items are not assigned', () {
        final expense = Expense(
          id: 'expense-1',
          ownerId: 'owner-1',
          title: 'Partial Assigned',
          totalAmount: 100.0,
          date: tDate,
          items: const [
            ExpenseItem(
              id: 'item-1',
              name: 'Item 1',
              price: 10.0,
              assignedUserIds: ['user-1'],
            ),
            ExpenseItem(
              id: 'item-2',
              name: 'Item 2',
              price: 20.0,
              assignedUserIds: [],
            ),
          ],
        );
        expect(expense.allItemsAssigned, false);
      });

      test('should return true when no items', () {
        final expense = Expense(
          id: 'expense-1',
          ownerId: 'owner-1',
          title: 'No Items',
          totalAmount: 100.0,
          date: tDate,
          items: const [],
        );
        expect(expense.allItemsAssigned, true);
      });
    });

    group('allSplitsPaid', () {
      test('should return true when all splits are paid', () {
        final expense = Expense(
          id: 'expense-1',
          ownerId: 'owner-1',
          title: 'All Paid',
          totalAmount: 100.0,
          date: tDate,
          splits: const [
            ExpenseSplit(
              userId: 'user-1',
              userName: 'User 1',
              amount: 50.0,
              isPaid: true,
            ),
            ExpenseSplit(
              userId: 'user-2',
              userName: 'User 2',
              amount: 50.0,
              isPaid: true,
            ),
          ],
        );
        expect(expense.allSplitsPaid, true);
      });

      test('should return false when some splits are not paid', () {
        expect(tExpense.allSplitsPaid, false);
      });

      test('should return true when no splits', () {
        final expense = Expense(
          id: 'expense-1',
          ownerId: 'owner-1',
          title: 'No Splits',
          totalAmount: 100.0,
          date: tDate,
          splits: const [],
        );
        expect(expense.allSplitsPaid, true);
      });
    });

    group('paidSplitsCount', () {
      test('should return count of paid splits', () {
        expect(tExpense.paidSplitsCount, 1);
      });

      test('should return 0 when no splits are paid', () {
        final expense = Expense(
          id: 'expense-1',
          ownerId: 'owner-1',
          title: 'None Paid',
          totalAmount: 100.0,
          date: tDate,
          splits: const [
            ExpenseSplit(
              userId: 'user-1',
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
        expect(expense.paidSplitsCount, 0);
      });

      test('should return total count when all splits are paid', () {
        final expense = Expense(
          id: 'expense-1',
          ownerId: 'owner-1',
          title: 'All Paid',
          totalAmount: 100.0,
          date: tDate,
          splits: const [
            ExpenseSplit(
              userId: 'user-1',
              userName: 'User 1',
              amount: 50.0,
              isPaid: true,
            ),
            ExpenseSplit(
              userId: 'user-2',
              userName: 'User 2',
              amount: 50.0,
              isPaid: true,
            ),
          ],
        );
        expect(expense.paidSplitsCount, 2);
      });
    });

    group('paymentProgress', () {
      test('should return correct progress string', () {
        expect(tExpense.paymentProgress, '1/2 paid');
      });

      test('should show 0/0 when no splits', () {
        final expense = Expense(
          id: 'expense-1',
          ownerId: 'owner-1',
          title: 'No Splits',
          totalAmount: 100.0,
          date: tDate,
          splits: const [],
        );
        expect(expense.paymentProgress, '0/0 paid');
      });

      test('should show all paid', () {
        final expense = Expense(
          id: 'expense-1',
          ownerId: 'owner-1',
          title: 'All Paid',
          totalAmount: 100.0,
          date: tDate,
          splits: const [
            ExpenseSplit(
              userId: 'user-1',
              userName: 'User 1',
              amount: 25.0,
              isPaid: true,
            ),
            ExpenseSplit(
              userId: 'user-2',
              userName: 'User 2',
              amount: 25.0,
              isPaid: true,
            ),
            ExpenseSplit(
              userId: 'user-3',
              userName: 'User 3',
              amount: 25.0,
              isPaid: true,
            ),
            ExpenseSplit(
              userId: 'user-4',
              userName: 'User 4',
              amount: 25.0,
              isPaid: true,
            ),
          ],
        );
        expect(expense.paymentProgress, '4/4 paid');
      });
    });

    group('copyWith', () {
      test('should return same expense when no parameters are provided', () {
        final copy = tExpense.copyWith();
        expect(copy, tExpense);
      });

      test('should update id when provided', () {
        final copy = tExpense.copyWith(id: 'new-id');
        expect(copy.id, 'new-id');
        expect(copy.title, tExpense.title);
      });

      test('should update ownerId when provided', () {
        final copy = tExpense.copyWith(ownerId: 'new-owner');
        expect(copy.ownerId, 'new-owner');
      });

      test('should update title when provided', () {
        final copy = tExpense.copyWith(title: 'New Title');
        expect(copy.title, 'New Title');
      });

      test('should update status when provided', () {
        final copy = tExpense.copyWith(status: ExpenseStatus.settled);
        expect(copy.status, ExpenseStatus.settled);
      });

      test('should update type when provided', () {
        final copy = tExpense.copyWith(type: ExpenseType.oneOnOne);
        expect(copy.type, ExpenseType.oneOnOne);
      });

      test('should update items when provided', () {
        const newItems = [
          ExpenseItem(id: 'new-item', name: 'New Item', price: 99.0),
        ];
        final copy = tExpense.copyWith(items: newItems);
        expect(copy.items, newItems);
      });

      test('should update splits when provided', () {
        const newSplits = [
          ExpenseSplit(userId: 'new-user', userName: 'New User', amount: 99.0),
        ];
        final copy = tExpense.copyWith(splits: newSplits);
        expect(copy.splits, newSplits);
      });

      test('should update ad-hoc fields when provided', () {
        final copy = tExpense.copyWith(
          masterExpenseId: 'master-1',
          linkedExpenseIds: ['linked-1', 'linked-2'],
          adHocParticipantIds: ['participant-1'],
        );
        expect(copy.masterExpenseId, 'master-1');
        expect(copy.linkedExpenseIds, ['linked-1', 'linked-2']);
        expect(copy.adHocParticipantIds, ['participant-1']);
      });

      test('should update multiple fields', () {
        final newDate = DateTime(2024, 6, 1);
        final copy = tExpense.copyWith(
          title: 'Updated',
          totalAmount: 200.0,
          date: newDate,
          status: ExpenseStatus.settled,
        );
        expect(copy.title, 'Updated');
        expect(copy.totalAmount, 200.0);
        expect(copy.date, newDate);
        expect(copy.status, ExpenseStatus.settled);
        expect(copy.id, tExpense.id); // unchanged
      });

      test('should clear chatRoomId when clearChatRoomId is true', () {
        final copy = tExpense.copyWith(clearChatRoomId: true);
        expect(copy.chatRoomId, isNull);
      });

      test('should clear description when clearDescription is true', () {
        final copy = tExpense.copyWith(clearDescription: true);
        expect(copy.description, isNull);
      });

      test('should clear taxPercent when clearTaxPercent is true', () {
        final copy = tExpense.copyWith(clearTaxPercent: true);
        expect(copy.taxPercent, isNull);
      });

      test(
        'should clear serviceChargePercent when clearServiceChargePercent is true',
        () {
          final copy = tExpense.copyWith(clearServiceChargePercent: true);
          expect(copy.serviceChargePercent, isNull);
        },
      );

      test(
        'should clear discountPercent when clearDiscountPercent is true',
        () {
          final copy = tExpense.copyWith(clearDiscountPercent: true);
          expect(copy.discountPercent, isNull);
        },
      );

      test(
        'should clear masterExpenseId when clearMasterExpenseId is true',
        () {
          final expense = tExpense.copyWith(masterExpenseId: 'master-1');
          final copy = expense.copyWith(clearMasterExpenseId: true);
          expect(copy.masterExpenseId, isNull);
        },
      );

      test(
        'should clear linkedExpenseIds when clearLinkedExpenseIds is true',
        () {
          final expense = tExpense.copyWith(linkedExpenseIds: ['linked-1']);
          final copy = expense.copyWith(clearLinkedExpenseIds: true);
          expect(copy.linkedExpenseIds, isNull);
        },
      );

      test(
        'should clear adHocParticipantIds when clearAdHocParticipantIds is true',
        () {
          final expense = tExpense.copyWith(adHocParticipantIds: ['p-1']);
          final copy = expense.copyWith(clearAdHocParticipantIds: true);
          expect(copy.adHocParticipantIds, isNull);
        },
      );

      test('should clear imageUrl when clearImageUrl is true', () {
        final expense = tExpense.copyWith(
          imageUrl: 'http://example.com/img.png',
        );
        final copy = expense.copyWith(clearImageUrl: true);
        expect(copy.imageUrl, isNull);
      });

      test('clear flag should take precedence over provided value', () {
        final copy = tExpense.copyWith(
          description: 'New description',
          clearDescription: true,
        );
        expect(copy.description, isNull);
      });
    });

    group('equality', () {
      test('should be equal when all properties are the same', () {
        final expense1 = Expense(
          id: 'expense-1',
          ownerId: 'owner-1',
          title: 'Test',
          totalAmount: 100.0,
          date: tDate,
        );
        final expense2 = Expense(
          id: 'expense-1',
          ownerId: 'owner-1',
          title: 'Test',
          totalAmount: 100.0,
          date: tDate,
        );
        expect(expense1, expense2);
      });

      test('should not be equal when id is different', () {
        final expense1 = Expense(
          id: 'expense-1',
          ownerId: 'owner-1',
          title: 'Test',
          totalAmount: 100.0,
          date: tDate,
        );
        final expense2 = Expense(
          id: 'expense-2',
          ownerId: 'owner-1',
          title: 'Test',
          totalAmount: 100.0,
          date: tDate,
        );
        expect(expense1, isNot(expense2));
      });

      test('should not be equal when title is different', () {
        final expense1 = Expense(
          id: 'expense-1',
          ownerId: 'owner-1',
          title: 'Test1',
          totalAmount: 100.0,
          date: tDate,
        );
        final expense2 = Expense(
          id: 'expense-1',
          ownerId: 'owner-1',
          title: 'Test2',
          totalAmount: 100.0,
          date: tDate,
        );
        expect(expense1, isNot(expense2));
      });

      test('should not be equal when status is different', () {
        final expense1 = Expense(
          id: 'expense-1',
          ownerId: 'owner-1',
          title: 'Test',
          totalAmount: 100.0,
          date: tDate,
          status: ExpenseStatus.pending,
        );
        final expense2 = Expense(
          id: 'expense-1',
          ownerId: 'owner-1',
          title: 'Test',
          totalAmount: 100.0,
          date: tDate,
          status: ExpenseStatus.settled,
        );
        expect(expense1, isNot(expense2));
      });
    });

    group('props', () {
      test('should include all properties in props', () {
        expect(tExpense.props.length, 19);
        expect(tExpense.props, contains('expense-1'));
        expect(tExpense.props, contains('owner-1'));
        expect(tExpense.props, contains('Test Expense'));
      });
    });
  });
}
