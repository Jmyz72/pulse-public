import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/services/ocr_service.dart';
import '../../../../core/services/payment_proof_parser_service.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_item.dart';
import '../../domain/entities/expense_split.dart';
import '../../domain/entities/payment_proof_analysis.dart';
import '../../domain/entities/payment_proof_evaluation.dart';
import '../models/expense_item_model.dart';
import '../models/expense_model.dart';
import '../models/expense_split_model.dart';
import '../validators/expense_validator.dart';

abstract class ExpenseRemoteDataSource {
  Future<List<ExpenseModel>> getExpenses(List<String> chatRoomIds);
  Future<ExpenseModel> getExpenseById(String id);
  Future<ExpenseModel> createExpense(ExpenseModel expense);
  Future<ExpenseModel> updateExpense(ExpenseModel expense);
  Future<void> deleteExpense(String id);
  Future<List<ExpenseModel>> getExpensesByChatRoom(String chatRoomId);

  /// Create ad-hoc expense with linked records
  Future<ExpenseModel> createAdHocExpense({
    required ExpenseModel masterExpense,
    required List<String> participantIds,
    required Map<String, String> chatRoomIdsByParticipant,
  });

  /// Update expense items
  Future<ExpenseModel> updateExpenseItems({
    required String expenseId,
    required List<ExpenseItem> items,
    double? taxPercent,
    double? serviceChargePercent,
    double? discountPercent,
  });

  /// Member selects their items
  Future<ExpenseModel> selectItems({
    required String expenseId,
    required String userId,
    required List<String> itemIds,
  });

  /// Mark split as paid
  Future<ExpenseModel> markSplitAsPaid({
    required String expenseId,
    required String userId,
    required bool isPaid,
  });

  Future<PaymentProofAnalysis> analyzePaymentProof(String imagePath);

  Future<String> uploadPaymentProof({
    required String expenseId,
    required String userId,
    required String imagePath,
  });

  Future<ExpenseModel> submitPaymentProof({
    required String expenseId,
    required String userId,
    required String proofImageUrl,
    required PaymentProofEvaluation evaluation,
  });

  Future<ExpenseModel> approvePaymentProof({
    required String expenseId,
    required String userId,
    required String reviewerId,
  });

  Future<ExpenseModel> rejectPaymentProof({
    required String expenseId,
    required String userId,
    required String reviewerId,
    required String reason,
  });

  Future<void> syncOwnerPaymentIdentityToPendingExpenses({
    required String ownerId,
    required String paymentIdentity,
  });

  Future<ExpenseModel> refreshExpenseOwnerPaymentIdentity({
    required String expenseId,
    required String ownerId,
    required String paymentIdentity,
  });

  /// Sync linked expenses
  Future<void> syncLinkedExpenses(String masterExpenseId);

  /// Get expenses for user (including ad-hoc)
  Future<List<ExpenseModel>> getExpensesForUser(String userId);
}

class ExpenseRemoteDataSourceImpl implements ExpenseRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage firebaseStorage;
  final OcrService ocrService;
  final PaymentProofParserService paymentProofParserService;

  ExpenseRemoteDataSourceImpl({
    required this.firestore,
    required this.firebaseStorage,
    required this.ocrService,
    required this.paymentProofParserService,
  });

  @override
  Future<List<ExpenseModel>> getExpenses(List<String> chatRoomIds) async {
    try {
      if (chatRoomIds.isEmpty) {
        return [];
      }

      final List<ExpenseModel> allExpenses = [];

      // Firestore whereIn limit is 30, batch if needed
      for (var i = 0; i < chatRoomIds.length; i += 30) {
        final batch = chatRoomIds.skip(i).take(30).toList();
        final snapshot = await firestore
            .collection(FirestoreCollections.expenses)
            .where('chatRoomId', whereIn: batch)
            .orderBy('date', descending: true)
            .get();

        allExpenses.addAll(
          snapshot.docs.map(
            (doc) => ExpenseModel.fromJson({'id': doc.id, ...doc.data()}),
          ),
        );
      }

      // Sort by date descending after combining batches
      allExpenses.sort((a, b) => b.date.compareTo(a.date));
      return allExpenses;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ExpenseModel> getExpenseById(String id) async {
    try {
      final doc = await firestore
          .collection(FirestoreCollections.expenses)
          .doc(id)
          .get();

      if (!doc.exists) {
        throw const ServerException(message: 'Expense not found');
      }

      return ExpenseModel.fromJson({'id': doc.id, ...doc.data()!});
    } on ServerException {
      rethrow;
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to load expense');
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ExpenseModel> createExpense(ExpenseModel expense) async {
    try {
      final data = expense.toJson();
      data.remove('id');
      final docRef = await firestore
          .collection(FirestoreCollections.expenses)
          .add(data);
      return ExpenseModel.fromJson({'id': docRef.id, ...data});
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ExpenseModel> updateExpense(ExpenseModel expense) async {
    try {
      final data = expense.toJson();
      data.remove('id');
      await firestore
          .collection(FirestoreCollections.expenses)
          .doc(expense.id)
          .update(data);
      return expense;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    try {
      await firestore
          .collection(FirestoreCollections.expenses)
          .doc(id)
          .delete();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<ExpenseModel>> getExpensesByChatRoom(String chatRoomId) async {
    try {
      final snapshot = await firestore
          .collection(FirestoreCollections.expenses)
          .where('chatRoomId', isEqualTo: chatRoomId)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ExpenseModel.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ExpenseModel> createAdHocExpense({
    required ExpenseModel masterExpense,
    required List<String> participantIds,
    required Map<String, String> chatRoomIdsByParticipant,
  }) async {
    try {
      final batch = firestore.batch();
      final masterRef = firestore
          .collection(FirestoreCollections.expenses)
          .doc();

      // Create master expense data
      final masterData = masterExpense.toJson();
      masterData.remove('id');
      masterData['adHocParticipantIds'] = participantIds;

      final linkedExpenseIds = <String>[];

      // Create linked expenses for each participant's 1:1 chat
      for (final participantId in participantIds) {
        if (participantId == masterExpense.ownerId) continue;

        final chatRoomId = chatRoomIdsByParticipant[participantId];
        if (chatRoomId == null) continue;

        final linkedRef = firestore
            .collection(FirestoreCollections.expenses)
            .doc();
        linkedExpenseIds.add(linkedRef.id);

        final linkedData = Map<String, dynamic>.from(masterData);
        linkedData['chatRoomId'] = chatRoomId;
        linkedData['masterExpenseId'] = masterRef.id;
        linkedData.remove('linkedExpenseIds');

        batch.set(linkedRef, linkedData);
      }

      // Add linked expense IDs to master
      masterData['linkedExpenseIds'] = linkedExpenseIds;
      batch.set(masterRef, masterData);

      await batch.commit();

      return ExpenseModel.fromJson({'id': masterRef.id, ...masterData});
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ExpenseModel> updateExpenseItems({
    required String expenseId,
    required List<ExpenseItem> items,
    double? taxPercent,
    double? serviceChargePercent,
    double? discountPercent,
  }) async {
    try {
      ExpenseValidator.validateItems(
        items,
        taxPercent: taxPercent,
        serviceChargePercent: serviceChargePercent,
        discountPercent: discountPercent,
      );

      final itemsJson = items
          .map((item) => ExpenseItemModel.fromEntity(item).toJson())
          .toList();

      // Calculate new total
      final itemsSubtotal = items.fold<double>(
        0,
        (total, item) => total + item.subtotal,
      );
      final tax = taxPercent != null ? itemsSubtotal * (taxPercent / 100) : 0.0;
      final service = serviceChargePercent != null
          ? itemsSubtotal * (serviceChargePercent / 100)
          : 0.0;
      final discount = discountPercent != null
          ? itemsSubtotal * (discountPercent / 100)
          : 0.0;
      final newTotal = itemsSubtotal + tax + service - discount;

      final updates = <String, dynamic>{
        'items': itemsJson,
        'totalAmount': newTotal,
      };

      if (taxPercent != null) updates['taxPercent'] = taxPercent;
      if (serviceChargePercent != null) {
        updates['serviceChargePercent'] = serviceChargePercent;
      }
      if (discountPercent != null) updates['discountPercent'] = discountPercent;

      await firestore
          .collection(FirestoreCollections.expenses)
          .doc(expenseId)
          .update(updates);

      return getExpenseById(expenseId);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ExpenseModel> selectItems({
    required String expenseId,
    required String userId,
    required List<String> itemIds,
  }) async {
    try {
      ExpenseValidator.validateRequiredIds(
        expenseId: expenseId,
        userId: userId,
      );

      final expense = await getExpenseById(expenseId);
      if (expense.status == ExpenseStatus.settled) {
        throw const ServerException(message: 'This expense is already settled');
      }

      final splitIndex = expense.splits.indexWhere(
        (split) => split.userId == userId,
      );
      if (splitIndex == -1) {
        throw const ServerException(message: 'Split not found for this user');
      }
      final currentUserSplit = expense.splits[splitIndex];
      if (currentUserSplit.locksItemSelection) {
        throw ServerException(
          message: currentUserSplit.needsReview
              ? 'Your payment proof is waiting for owner review; item selection is locked'
              : 'Your payment is already recorded; item selection is locked',
        );
      }

      final touchesLockedItem = expense.items.any((item) {
        final isAssigned = item.assignedUserIds.contains(userId);
        final shouldBeAssigned = itemIds.contains(item.id);
        if (isAssigned == shouldBeAssigned) {
          return false;
        }

        for (final assignedUserId in item.assignedUserIds) {
          final assignedSplitIndex = expense.splits.indexWhere(
            (split) => split.userId == assignedUserId,
          );
          if (assignedSplitIndex != -1 &&
              expense.splits[assignedSplitIndex].locksItemSelection) {
            return true;
          }
        }

        return false;
      });

      if (touchesLockedItem) {
        throw const ServerException(
          message:
              'This item is locked because payment is under review or already recorded',
        );
      }

      // Update items with user assignment
      final updatedItems = expense.items.map((item) {
        final assignedUsers = List<String>.from(item.assignedUserIds);

        if (itemIds.contains(item.id)) {
          // Add user if not already assigned
          if (!assignedUsers.contains(userId)) {
            assignedUsers.add(userId);
          }
        } else {
          // Remove user from this item
          assignedUsers.remove(userId);
        }

        return ExpenseItemModel(
          id: item.id,
          name: item.name,
          price: item.price,
          quantity: item.quantity,
          assignedUserIds: assignedUsers,
        );
      }).toList();

      // Recalculate splits based on item assignments
      final splitsByUser = <String, double>{};
      for (final item in updatedItems) {
        if (item.assignedUserIds.isEmpty) continue;
        final costPerPerson = item.costPerPerson;
        for (final assignedUserId in item.assignedUserIds) {
          splitsByUser[assignedUserId] =
              (splitsByUser[assignedUserId] ?? 0) + costPerPerson;
        }
      }

      // Apply tax/service/discount proportionally
      final itemsSubtotal = updatedItems.fold<double>(
        0,
        (total, item) => total + item.subtotal,
      );
      final multiplier = itemsSubtotal > 0
          ? expense.calculatedTotal / itemsSubtotal
          : 1.0;

      // Update splits
      final updatedSplits = expense.splits.map((split) {
        final userAmount = (splitsByUser[split.userId] ?? 0) * multiplier;
        final userItemIds = updatedItems
            .where((item) => item.assignedUserIds.contains(split.userId))
            .map((item) => item.id)
            .toList();
        final ownerJustConfirmedSelection =
            expense.ownerId == userId && split.userId == expense.ownerId;

        return ExpenseSplitModel.fromEntity(
          split.copyWith(
            amount: userAmount,
            itemIds: userItemIds,
            hasSelectedItems: userItemIds.isNotEmpty,
            paymentStatus: ownerJustConfirmedSelection
                ? ExpensePaymentStatus.paid
                : split.paymentStatus,
            paidAt: ownerJustConfirmedSelection
                ? (split.paidAt ?? DateTime.now())
                : split.paidAt,
            clearPaidAt: false,
            clearProofImageUrl: ownerJustConfirmedSelection,
            clearProofSubmittedAt: ownerJustConfirmedSelection,
            clearProofReviewedAt: ownerJustConfirmedSelection,
            clearProofReviewedBy: ownerJustConfirmedSelection,
            clearProofRejectionReason: ownerJustConfirmedSelection,
            clearMatchedAmount: ownerJustConfirmedSelection,
            clearMatchedRecipient: ownerJustConfirmedSelection,
            clearMatchConfidence: ownerJustConfirmedSelection,
          ),
        );
      }).toList();

      final allPaid = updatedSplits.every((split) => split.isPaid);
      final newStatus = allPaid ? ExpenseStatus.settled : ExpenseStatus.pending;

      // Update Firestore
      await firestore
          .collection(FirestoreCollections.expenses)
          .doc(expenseId)
          .update({
            'items': updatedItems
                .map((item) => ExpenseItemModel.fromEntity(item).toJson())
                .toList(),
            'splits': updatedSplits.map((split) => split.toJson()).toList(),
            'status': newStatus.name,
          });

      return getExpenseById(expenseId);
    } on ServerException {
      rethrow;
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to save selected items',
      );
    } catch (e) {
      throw ServerException(message: 'Failed to save selected items: $e');
    }
  }

  @override
  Future<ExpenseModel> markSplitAsPaid({
    required String expenseId,
    required String userId,
    required bool isPaid,
  }) async {
    try {
      ExpenseValidator.validateRequiredIds(
        expenseId: expenseId,
        userId: userId,
      );

      final expense = await getExpenseById(expenseId);

      final updatedSplits = expense.splits.map((split) {
        if (split.userId == userId) {
          return ExpenseSplitModel.fromEntity(
            split.copyWith(
              paymentStatus: isPaid
                  ? ExpensePaymentStatus.paid
                  : ExpensePaymentStatus.unpaid,
              paidAt: isPaid ? DateTime.now() : null,
              clearPaidAt: !isPaid,
              clearProofRejectionReason: isPaid,
            ),
          );
        }
        return ExpenseSplitModel.fromEntity(split);
      }).toList();

      // Check if all splits are paid to auto-settle
      final allPaid = updatedSplits.every((split) => split.isPaid);
      final newStatus = allPaid ? ExpenseStatus.settled : ExpenseStatus.pending;

      await firestore
          .collection(FirestoreCollections.expenses)
          .doc(expenseId)
          .update({
            'splits': updatedSplits.map((split) => split.toJson()).toList(),
            'status': newStatus.name,
          });

      return getExpenseById(expenseId);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<PaymentProofAnalysis> analyzePaymentProof(String imagePath) async {
    try {
      final rawText = await ocrService.extractTextFromImage(File(imagePath));
      final parsed = await paymentProofParserService.parsePaymentProofText(
        rawText,
      );
      return PaymentProofAnalysis(
        extractedAmount: parsed.amount,
        extractedRecipient: parsed.recipient,
        confidence: parsed.confidence,
        rawText: rawText,
      );
    } catch (e) {
      throw ServerException(message: 'Failed to analyze payment proof: $e');
    }
  }

  @override
  Future<String> uploadPaymentProof({
    required String expenseId,
    required String userId,
    required String imagePath,
  }) async {
    try {
      final fileName = imagePath.split('/').last;
      final proofId = const Uuid().v4();
      final ref = firebaseStorage.ref().child(
        'expense_payment_proofs/$expenseId/$userId/${proofId}_$fileName',
      );
      final uploadTask = await ref.putFile(
        File(imagePath),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw ServerException(message: 'Failed to upload payment proof: $e');
    }
  }

  @override
  Future<ExpenseModel> submitPaymentProof({
    required String expenseId,
    required String userId,
    required String proofImageUrl,
    required PaymentProofEvaluation evaluation,
  }) async {
    try {
      final expense = await getExpenseById(expenseId);
      final now = DateTime.now();
      final updatedSplits = expense.splits.map((split) {
        if (split.userId != userId) {
          return ExpenseSplitModel.fromEntity(split);
        }

        final nextStatus = evaluation.canAutoSettle
            ? ExpensePaymentStatus.paid
            : ExpensePaymentStatus.proofSubmitted;

        return ExpenseSplitModel.fromEntity(
          split.copyWith(
            paymentStatus: nextStatus,
            paidAt: evaluation.canAutoSettle ? now : null,
            clearPaidAt: !evaluation.canAutoSettle,
            proofImageUrl: proofImageUrl,
            proofSubmittedAt: now,
            proofReviewedAt: null,
            clearProofReviewedAt: true,
            proofReviewedBy: null,
            clearProofReviewedBy: true,
            proofRejectionReason: null,
            clearProofRejectionReason: true,
            matchedAmount: evaluation.extractedAmount,
            clearMatchedAmount: evaluation.extractedAmount == null,
            matchedRecipient: evaluation.extractedRecipient,
            clearMatchedRecipient: evaluation.extractedRecipient == null,
            matchConfidence: evaluation.confidence,
          ),
        );
      }).toList();

      await _persistSplitUpdate(
        expenseId: expenseId,
        updatedSplits: updatedSplits,
      );
      return getExpenseById(expenseId);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ExpenseModel> approvePaymentProof({
    required String expenseId,
    required String userId,
    required String reviewerId,
  }) async {
    try {
      final expense = await getExpenseById(expenseId);
      final now = DateTime.now();
      final updatedSplits = expense.splits.map((split) {
        if (split.userId != userId) {
          return ExpenseSplitModel.fromEntity(split);
        }

        return ExpenseSplitModel.fromEntity(
          split.copyWith(
            paymentStatus: ExpensePaymentStatus.paid,
            paidAt: now,
            proofReviewedAt: now,
            proofReviewedBy: reviewerId,
            proofRejectionReason: null,
            clearProofRejectionReason: true,
          ),
        );
      }).toList();

      await _persistSplitUpdate(
        expenseId: expenseId,
        updatedSplits: updatedSplits,
      );
      return getExpenseById(expenseId);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ExpenseModel> rejectPaymentProof({
    required String expenseId,
    required String userId,
    required String reviewerId,
    required String reason,
  }) async {
    try {
      final expense = await getExpenseById(expenseId);
      final now = DateTime.now();
      final updatedSplits = expense.splits.map((split) {
        if (split.userId != userId) {
          return ExpenseSplitModel.fromEntity(split);
        }

        return ExpenseSplitModel.fromEntity(
          split.copyWith(
            paymentStatus: ExpensePaymentStatus.proofRejected,
            paidAt: null,
            clearPaidAt: true,
            proofReviewedAt: now,
            proofReviewedBy: reviewerId,
            proofRejectionReason: reason.trim(),
          ),
        );
      }).toList();

      await _persistSplitUpdate(
        expenseId: expenseId,
        updatedSplits: updatedSplits,
      );
      return getExpenseById(expenseId);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> syncOwnerPaymentIdentityToPendingExpenses({
    required String ownerId,
    required String paymentIdentity,
  }) async {
    try {
      final normalizedPaymentIdentity = _normalizePaymentIdentity(
        paymentIdentity,
      );
      if (ownerId.trim().isEmpty || normalizedPaymentIdentity == null) {
        return;
      }

      final snapshot = await firestore
          .collection(FirestoreCollections.expenses)
          .where('ownerId', isEqualTo: ownerId)
          .get();

      final docsToUpdate = snapshot.docs.where((doc) {
        final expense = ExpenseModel.fromJson({'id': doc.id, ...doc.data()});
        return expense.status == ExpenseStatus.pending &&
            _normalizePaymentIdentity(expense.ownerPaymentIdentity) == null;
      }).toList();

      await _updateOwnerPaymentIdentityBatch(
        refs: docsToUpdate.map((doc) => doc.reference).toList(growable: false),
        paymentIdentity: normalizedPaymentIdentity,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ExpenseModel> refreshExpenseOwnerPaymentIdentity({
    required String expenseId,
    required String ownerId,
    required String paymentIdentity,
  }) async {
    try {
      final normalizedPaymentIdentity = _normalizePaymentIdentity(
        paymentIdentity,
      );
      if (normalizedPaymentIdentity == null) {
        throw const ServerException(
          message: 'Payment identity is not configured yet',
        );
      }

      final expense = await getExpenseById(expenseId);
      if (expense.ownerId != ownerId) {
        throw const ServerException(
          message: 'Only the expense owner can refresh payment identity',
        );
      }
      if (expense.status != ExpenseStatus.pending) {
        throw const ServerException(
          message: 'Only pending expenses can refresh payment identity',
        );
      }
      if (_normalizePaymentIdentity(expense.ownerPaymentIdentity) != null) {
        return expense;
      }

      final refs = <DocumentReference<Map<String, dynamic>>>[
        firestore.collection(FirestoreCollections.expenses).doc(expense.id),
      ];

      if (expense.linkedExpenseIds != null &&
          expense.linkedExpenseIds!.isNotEmpty) {
        final linkedSnapshots = await Future.wait(
          expense.linkedExpenseIds!.map(
            (linkedId) => firestore
                .collection(FirestoreCollections.expenses)
                .doc(linkedId)
                .get(),
          ),
        );
        for (final snapshot in linkedSnapshots) {
          if (!snapshot.exists) continue;
          final linkedExpense = ExpenseModel.fromJson({
            'id': snapshot.id,
            ...snapshot.data()!,
          });
          if (linkedExpense.status == ExpenseStatus.pending &&
              _normalizePaymentIdentity(linkedExpense.ownerPaymentIdentity) ==
                  null) {
            refs.add(snapshot.reference);
          }
        }
      }

      await _updateOwnerPaymentIdentityBatch(
        refs: refs,
        paymentIdentity: normalizedPaymentIdentity,
      );

      return getExpenseById(expenseId);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> syncLinkedExpenses(String masterExpenseId) async {
    try {
      final masterExpense = await getExpenseById(masterExpenseId);

      if (masterExpense.linkedExpenseIds == null ||
          masterExpense.linkedExpenseIds!.isEmpty) {
        return;
      }

      final batch = firestore.batch();

      // Sync data to all linked expenses
      for (final linkedId in masterExpense.linkedExpenseIds!) {
        final linkedRef = firestore
            .collection(FirestoreCollections.expenses)
            .doc(linkedId);

        batch.update(linkedRef, {
          'title': masterExpense.title,
          'description': masterExpense.description,
          'totalAmount': masterExpense.totalAmount,
          'items': masterExpense.items
              .map((item) => ExpenseItemModel.fromEntity(item).toJson())
              .toList(),
          'taxPercent': masterExpense.taxPercent,
          'serviceChargePercent': masterExpense.serviceChargePercent,
          'discountPercent': masterExpense.discountPercent,
          'splits': masterExpense.splits
              .map((split) => ExpenseSplitModel.fromEntity(split).toJson())
              .toList(),
          'status': masterExpense.status.name,
        });
      }

      await batch.commit();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<ExpenseModel>> getExpensesForUser(String userId) async {
    try {
      // Get expenses where user is owner
      final ownerSnapshot = await firestore
          .collection(FirestoreCollections.expenses)
          .where('ownerId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();

      // Get expenses where user is a participant in ad-hoc
      final participantSnapshot = await firestore
          .collection(FirestoreCollections.expenses)
          .where('adHocParticipantIds', arrayContains: userId)
          .orderBy('date', descending: true)
          .get();

      final expenseMap = <String, ExpenseModel>{};

      for (final doc in ownerSnapshot.docs) {
        expenseMap[doc.id] = ExpenseModel.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }

      for (final doc in participantSnapshot.docs) {
        expenseMap[doc.id] = ExpenseModel.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }

      final expenses = expenseMap.values.toList();
      expenses.sort((a, b) => b.date.compareTo(a.date));

      return expenses;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  Future<void> _persistSplitUpdate({
    required String expenseId,
    required List<ExpenseSplitModel> updatedSplits,
  }) async {
    final allPaid = updatedSplits.every((split) => split.isPaid);
    final newStatus = allPaid ? ExpenseStatus.settled : ExpenseStatus.pending;

    await firestore
        .collection(FirestoreCollections.expenses)
        .doc(expenseId)
        .update({
          'splits': updatedSplits.map((split) => split.toJson()).toList(),
          'status': newStatus.name,
        });
  }

  Future<void> _updateOwnerPaymentIdentityBatch({
    required List<DocumentReference<Map<String, dynamic>>> refs,
    required String paymentIdentity,
  }) async {
    if (refs.isEmpty) return;

    const batchSize = 400;
    for (var i = 0; i < refs.length; i += batchSize) {
      final batch = firestore.batch();
      final chunk = refs.skip(i).take(batchSize);
      for (final ref in chunk) {
        batch.update(ref, {'ownerPaymentIdentity': paymentIdentity});
      }
      await batch.commit();
    }
  }

  String? _normalizePaymentIdentity(String? paymentIdentity) {
    final trimmed = paymentIdentity?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
