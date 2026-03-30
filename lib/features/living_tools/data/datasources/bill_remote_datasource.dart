import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/bill.dart';
import '../../domain/entities/bill_summary.dart';
import '../models/bill_model.dart';
import '../models/bill_member_model.dart';

abstract class BillRemoteDataSource {
  Future<List<BillModel>> getBills(List<String> chatRoomIds);
  Stream<List<BillModel>> watchBills(List<String> chatRoomIds);
  Future<BillModel> getBillById(String id);
  Future<BillModel> createBill(BillModel bill);
  Future<BillModel> updateBill(BillModel bill);
  Future<void> deleteBill(String id);
  Future<void> markBillAsPaid(String billId, String memberId);
  Future<void> nudgeMember(String billId, String memberId);
  Future<BillSummary> getBillsSummary(String userId, List<String> chatRoomIds);
  Future<List<BillModel>> getBillsByChatRoom(String chatRoomId);
}

class BillRemoteDataSourceImpl implements BillRemoteDataSource {
  final FirebaseFirestore firestore;

  BillRemoteDataSourceImpl({required this.firestore});

  @override
  Stream<List<BillModel>> watchBills(List<String> chatRoomIds) {
    if (chatRoomIds.isEmpty) {
      return Stream.value([]);
    }

    // Since whereIn is limited to 30, we assume the user isn't in >30 active billing rooms.
    // For a real production app, we would merge multiple streams if needed.
    return firestore
        .collection(FirestoreCollections.bills)
        .where('chatRoomId', whereIn: chatRoomIds.take(30).toList())
        .snapshots()
        .map((snapshot) {
          final bills = snapshot.docs
              .map((doc) => BillModel.fromJson({'id': doc.id, ...doc.data()}))
              .toList();
          // Sort by createdAt descending (newest first)
          bills.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return bills;
        });
  }

  @override
  Future<List<BillModel>> getBills(List<String> chatRoomIds) async {
    try {
      if (chatRoomIds.isEmpty) {
        return [];
      }

      final List<BillModel> allBills = [];

      // Firestore whereIn limit is 30, batch if needed
      for (var i = 0; i < chatRoomIds.length; i += 30) {
        final batch = chatRoomIds.skip(i).take(30).toList();
        final snapshot = await firestore
            .collection(FirestoreCollections.bills)
            .where('chatRoomId', whereIn: batch)
            .orderBy('dueDate', descending: false)
            .get();

        allBills.addAll(
          snapshot.docs.map(
            (doc) => BillModel.fromJson({'id': doc.id, ...doc.data()}),
          ),
        );
      }

      // Sort by createdAt descending after combining batches
      allBills.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return allBills;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<BillModel> getBillById(String id) async {
    try {
      final doc = await firestore
          .collection(FirestoreCollections.bills)
          .doc(id)
          .get();

      if (!doc.exists) {
        throw const ServerException(message: 'Bill not found');
      }

      return BillModel.fromJson({'id': doc.id, ...doc.data()!});
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<BillModel> createBill(BillModel bill) async {
    try {
      final data = bill.toJson();
      data.remove('id');
      final docRef = await firestore
          .collection(FirestoreCollections.bills)
          .add(data);
      return BillModel.fromJson({'id': docRef.id, ...data});
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<BillModel> updateBill(BillModel bill) async {
    try {
      final data = bill.toJson();
      data.remove('id');
      await firestore
          .collection(FirestoreCollections.bills)
          .doc(bill.id)
          .update(data);
      return bill;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deleteBill(String id) async {
    try {
      await firestore.collection(FirestoreCollections.bills).doc(id).delete();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> markBillAsPaid(String billId, String memberId) async {
    try {
      final doc = await firestore
          .collection(FirestoreCollections.bills)
          .doc(billId)
          .get();
      if (!doc.exists) {
        throw const ServerException(message: 'Bill not found');
      }

      final bill = BillModel.fromJson({'id': doc.id, ...doc.data()!});
      final updatedMembers = bill.members.map((m) {
        if (m.id == memberId || m.userId == memberId) {
          return BillMember(
            id: m.id,
            userId: m.userId,
            userName: m.userName,
            share: m.share,
            hasPaid: true,
            paidAt: DateTime.now(),
            lastNudgedAt: m.lastNudgedAt,
          );
        }
        return m;
      }).toList();

      final allPaid = updatedMembers.every((m) => m.hasPaid);

      await firestore
          .collection(FirestoreCollections.bills)
          .doc(billId)
          .update({
            'members': updatedMembers
                .map((m) => BillMemberModel.fromEntity(m).toJson())
                .toList(),
            'status': allPaid ? 'paid' : bill.status.name,
          });
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> nudgeMember(String billId, String memberId) async {
    try {
      final doc = await firestore
          .collection(FirestoreCollections.bills)
          .doc(billId)
          .get();
      if (!doc.exists) throw const ServerException(message: 'Bill not found');

      final bill = BillModel.fromJson({'id': doc.id, ...doc.data()!});
      final now = DateTime.now();

      String nudgedUserId = '';

      final updatedMembers = bill.members.map((m) {
        if (m.id == memberId || m.userId == memberId) {
          nudgedUserId = m.userId;
          return BillMember(
            id: m.id,
            userId: m.userId,
            userName: m.userName,
            share: m.share,
            hasPaid: m.hasPaid,
            paidAt: m.paidAt,
            lastNudgedAt: now,
          );
        }
        return m;
      }).toList();

      await firestore
          .collection(FirestoreCollections.bills)
          .doc(billId)
          .update({
            'members': updatedMembers
                .map((m) => BillMemberModel.fromEntity(m).toJson())
                .toList(),
          });

      // Create Notification
      if (nudgedUserId.isNotEmpty) {
        await firestore.collection(FirestoreCollections.notifications).add({
          'userId': nudgedUserId,
          'title': 'Payment Reminder 🔔',
          'body': 'Friendly nudge to pay your share for "${bill.title}"',
          'type': 'bill_nudge',
          'data': {'billId': billId, 'chatRoomId': bill.chatRoomId},
          'isRead': false,
          'createdAt': Timestamp.fromDate(now),
        });
      }
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<BillSummary> getBillsSummary(
    String userId,
    List<String> chatRoomIds,
  ) async {
    try {
      final bills = await getBills(chatRoomIds);

      double totalOwed = 0;
      double totalPaid = 0;
      double yourOwed = 0;
      double yourPaid = 0;
      int pendingCount = 0;
      int overdueCount = 0;
      int paidCount = 0;

      for (final bill in bills) {
        for (final member in bill.members) {
          if (member.hasPaid) {
            totalPaid += member.share;
            if (member.userId == userId) {
              yourPaid += member.share;
            }
          } else {
            totalOwed += member.share;
            if (member.userId == userId) {
              yourOwed += member.share;
            }
          }
        }

        switch (bill.status) {
          case BillStatus.pending:
            pendingCount++;
            break;
          case BillStatus.overdue:
            overdueCount++;
            break;
          case BillStatus.paid:
            paidCount++;
            break;
        }
      }

      return BillSummary(
        totalOwed: totalOwed,
        totalPaid: totalPaid,
        yourOwed: yourOwed,
        yourPaid: yourPaid,
        pendingCount: pendingCount,
        overdueCount: overdueCount,
        paidCount: paidCount,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<BillModel>> getBillsByChatRoom(String chatRoomId) async {
    try {
      final snapshot = await firestore
          .collection(FirestoreCollections.bills)
          .where('chatRoomId', isEqualTo: chatRoomId)
          .orderBy('dueDate', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => BillModel.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
