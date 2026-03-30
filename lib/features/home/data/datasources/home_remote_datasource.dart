import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/error/exceptions.dart';
import '../utils/activity_feed_mapper.dart';
import '../../domain/entities/dashboard_data.dart';

abstract class HomeRemoteDataSource {
  Future<DashboardData> getDashboardData();
  Future<List<RecentActivity>> getRecentActivities({
    String? userId,
    int limit = 10,
  });
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  static const _whereInLimit = 30;

  final FirebaseFirestore firestore;
  final fb.FirebaseAuth firebaseAuth;

  HomeRemoteDataSourceImpl({
    required this.firestore,
    required this.firebaseAuth,
  });

  @override
  Future<DashboardData> getDashboardData() async {
    try {
      final currentUser = firebaseAuth.currentUser;
      if (currentUser == null) {
        throw const AuthException(message: 'User not authenticated');
      }

      // Phase 1: Fetch user data and accepted friendships in parallel
      final phase1Results = await Future.wait([
        firestore
            .collection(FirestoreCollections.users)
            .doc(currentUser.uid)
            .get(),
        firestore
            .collection(FirestoreCollections.friendships)
            .where('userId', isEqualTo: currentUser.uid)
            .where('status', isEqualTo: 'accepted')
            .get(),
        firestore
            .collection(FirestoreCollections.friendships)
            .where('friendId', isEqualTo: currentUser.uid)
            .where('status', isEqualTo: 'accepted')
            .get(),
      ]);

      final userDoc =
          phase1Results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final asRequester =
          phase1Results[1] as QuerySnapshot<Map<String, dynamic>>;
      final asFriend = phase1Results[2] as QuerySnapshot<Map<String, dynamic>>;
      final userData = userDoc.data() ?? {};

      final userSummary = UserSummary(
        id: currentUser.uid,
        name:
            userData['displayName'] ??
            userData['name'] ??
            currentUser.displayName ??
            'User',
        username: (userData['username'] as String?) ?? '',
        email: userData['email'] ?? currentUser.email ?? '',
        photoUrl: userData['photoUrl'] as String?,
        avatarInitial:
            (userData['displayName'] ??
                    userData['name'] ??
                    currentUser.displayName ??
                    'U')[0]
                .toUpperCase(),
      );

      // Collect friend user IDs from both directions
      final friendIds = <String>{};
      for (final doc in asRequester.docs) {
        final fid = doc.data()['friendId'] as String?;
        if (fid != null) friendIds.add(fid);
      }
      for (final doc in asFriend.docs) {
        final uid = doc.data()['userId'] as String?;
        if (uid != null) friendIds.add(uid);
      }

      final List<MemberSummary> friends = [];
      final friendIdList = friendIds.take(10).toList();

      if (friendIdList.isNotEmpty) {
        // Batch fetch friend user docs, locations, and presence in parallel.
        final friendDataResults = await Future.wait([
          Future.wait(
            friendIdList.map(
              (id) => firestore
                  .collection(FirestoreCollections.users)
                  .doc(id)
                  .get(),
            ),
          ),
          Future.wait(
            friendIdList.map(
              (id) => firestore
                  .collection(FirestoreCollections.userLocations)
                  .doc(id)
                  .get(),
            ),
          ),
          Future.wait(
            friendIdList.map(
              (id) => firestore
                  .collection(FirestoreCollections.presence)
                  .doc(id)
                  .get(),
            ),
          ),
        ]);

        final friendDocs = friendDataResults[0];
        final locationDocs = friendDataResults[1];
        final presenceDocs = friendDataResults[2];

        for (int i = 0; i < friendIdList.length; i++) {
          final friendData = friendDocs[i].data();
          final locationData = locationDocs[i].data();
          final presenceData = presenceDocs[i].data();
          if (friendData != null) {
            friends.add(
              MemberSummary(
                id: friendIdList[i],
                name:
                    friendData['displayName'] ??
                    friendData['name'] ??
                    'Unknown',
                avatarInitial:
                    (friendData['displayName'] ?? friendData['name'] ?? 'U')[0]
                        .toUpperCase(),
                photoUrl: friendData['photoUrl'] as String?,
                isOnline: presenceData?['online'] == true,
                latitude: locationData?['latitude']?.toDouble(),
                longitude: locationData?['longitude']?.toDouble(),
              ),
            );
          }
        }
      }

      final friendsSummary = FriendsSummary(
        friendCount: friendIds.length,
        friends: friends,
      );

      // Phase 1.5: Fetch user's chat rooms for grocery count
      final chatRoomsSnapshot = await firestore
          .collection(FirestoreCollections.chatRooms)
          .where('members', arrayContains: currentUser.uid)
          .get();
      final chatRoomIds = chatRoomsSnapshot.docs.map((d) => d.id).toList();

      // Phase 2: Fetch all counts and data in parallel
      final now = DateTime.now();
      final phase2Futures = <Future>[
        // 0: Expenses relevant to user (owner/chat member/ad-hoc participant)
        _getRelevantExpenseDocs(
          userId: currentUser.uid,
          chatRoomIds: chatRoomIds,
        ),
        // 1: Pending bills (user is member)
        _getPendingBillsSnapshot(chatRoomIds: chatRoomIds),
        // 2: Pending tasks (assigned to user)
        firestore
            .collection(FirestoreCollections.tasks)
            .where('assignedTo', isEqualTo: currentUser.uid)
            .where('status', isNotEqualTo: 'completed')
            .get(),
        // 3: Upcoming events (user is attendee)
        firestore
            .collection(FirestoreCollections.events)
            .where('attendeeIds', arrayContains: currentUser.uid)
            .where(
              'eventDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(
                DateTime(now.year, now.month, now.day),
              ),
            )
            .get(),
        // 4: Unread notifications
        firestore
            .collection(FirestoreCollections.notifications)
            .where('userId', isEqualTo: currentUser.uid)
            .where('isRead', isEqualTo: false)
            .get(),
        // 5: Recent shared activities
        getRecentActivities(userId: currentUser.uid, limit: 30),
      ];

      // 6: Grocery items (unpurchased across user's chat rooms)
      if (chatRoomIds.isNotEmpty) {
        phase2Futures.add(
          firestore
              .collection(FirestoreCollections.groceryItems)
              .where('chatRoomId', whereIn: chatRoomIds.take(30).toList())
              .where('isPurchased', isEqualTo: false)
              .get(),
        );
      }

      final phase2Results = await Future.wait(phase2Futures);

      final expenseDocs =
          phase2Results[0] as List<QueryDocumentSnapshot<Map<String, dynamic>>>;
      final billsSnapshot =
          phase2Results[1] as QuerySnapshot<Map<String, dynamic>>?;
      final tasksSnapshot =
          phase2Results[2] as QuerySnapshot<Map<String, dynamic>>;
      final eventsSnapshot =
          phase2Results[3] as QuerySnapshot<Map<String, dynamic>>;
      final notificationsSnapshot =
          phase2Results[4] as QuerySnapshot<Map<String, dynamic>>;
      final activities = phase2Results[5] as List<RecentActivity>;
      final groceryItemsCount = chatRoomIds.isNotEmpty
          ? (phase2Results[6] as QuerySnapshot<Map<String, dynamic>>)
                .docs
                .length
          : 0;

      // Filter bills: count bills where user is a member AND hasPaid is false
      int pendingBillsCount = 0;
      for (final doc in billsSnapshot?.docs ?? const []) {
        final data = doc.data();
        final members = data['members'] as List<dynamic>? ?? [];
        for (final m in members) {
          if (m['userId'] == currentUser.uid && m['hasPaid'] == false) {
            pendingBillsCount++;
            break;
          }
        }
      }

      final upcomingEventsCount = eventsSnapshot.docs.length;

      // Calculate expense summary
      double totalExpenses = 0;
      double userShare = 0;
      for (final doc in expenseDocs) {
        final data = doc.data();
        final totalAmount =
            (data['totalAmount'] as num?)?.toDouble() ??
            (data['amount'] as num?)?.toDouble() ??
            0.0;
        totalExpenses += totalAmount;

        // Current schema: derive user share from their split amount.
        final splits = data['splits'] as List<dynamic>? ?? [];
        bool shareFound = false;
        for (final rawSplit in splits) {
          if (rawSplit is! Map<String, dynamic>) continue;
          if (rawSplit['userId'] == currentUser.uid) {
            userShare += (rawSplit['amount'] as num?)?.toDouble() ?? 0.0;
            shareFound = true;
            break;
          }
        }

        // Backward compatibility for older expense docs.
        if (!shareFound) {
          final participants = List<String>.from(data['participants'] ?? []);
          if (participants.contains(currentUser.uid) &&
              participants.isNotEmpty) {
            userShare += totalAmount / participants.length;
          }
        }
      }

      final expenseSummary = ExpenseSummary(
        totalGroupExpenses: totalExpenses,
        userShare: userShare,
        pendingBillsCount: pendingBillsCount,
      );

      return DashboardData(
        user: userSummary,
        friends: friendsSummary,
        expenses: expenseSummary,
        pendingTasksCount: tasksSnapshot.docs.length,
        upcomingEventsCount: upcomingEventsCount,
        unreadNotificationsCount: notificationsSnapshot.docs.length,
        groceryItemsCount: groceryItemsCount,
        recentActivities: activities,
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<RecentActivity>> getRecentActivities({
    String? userId,
    int limit = 10,
  }) async {
    try {
      final currentUser = firebaseAuth.currentUser;
      if (currentUser == null) {
        throw const AuthException(message: 'User not authenticated');
      }

      final uid = userId ?? currentUser.uid;
      final chatRoomsSnapshot = await firestore
          .collection(FirestoreCollections.chatRooms)
          .where('members', arrayContains: uid)
          .get();

      final chatRoomIds = chatRoomsSnapshot.docs.map((doc) => doc.id).toList();
      if (chatRoomIds.isEmpty) {
        return const [];
      }

      final results = await Future.wait([
        _getExpenseActivities(chatRoomIds: chatRoomIds, limit: limit),
        _getTaskActivities(chatRoomIds: chatRoomIds, limit: limit),
        _getBillActivities(chatRoomIds: chatRoomIds, limit: limit),
        _getGroceryActivities(chatRoomIds: chatRoomIds, limit: limit),
      ]);

      final chatActivities = chatRoomsSnapshot.docs
          .map(
            (doc) => ActivityFeedMapper.fromChatRoomDoc(
              currentUserId: uid,
              roomId: doc.id,
              data: doc.data(),
            ),
          )
          .whereType<RecentActivity>()
          .toList(growable: false);

      return ActivityFeedMapper.mergeAndLimit([
        ...results,
        chatActivities,
      ], limit: limit);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  Future<List<RecentActivity>> _getExpenseActivities({
    required List<String> chatRoomIds,
    required int limit,
  }) async {
    final docs = await _getRecentDocsByChatRooms(
      collection: FirestoreCollections.expenses,
      chatRoomIds: chatRoomIds,
      orderByField: 'date',
      limit: limit,
    );

    return docs
        .map((doc) => ActivityFeedMapper.fromExpenseDoc(doc.id, doc.data()))
        .whereType<RecentActivity>()
        .toList(growable: false);
  }

  Future<List<RecentActivity>> _getTaskActivities({
    required List<String> chatRoomIds,
    required int limit,
  }) async {
    final docs = await _getRecentDocsByChatRooms(
      collection: FirestoreCollections.tasks,
      chatRoomIds: chatRoomIds,
      orderByField: 'createdAt',
      limit: limit,
    );

    return docs
        .map((doc) => ActivityFeedMapper.fromTaskDoc(doc.id, doc.data()))
        .whereType<RecentActivity>()
        .toList(growable: false);
  }

  Future<List<RecentActivity>> _getBillActivities({
    required List<String> chatRoomIds,
    required int limit,
  }) async {
    final docs = await _getRecentDocsByChatRooms(
      collection: FirestoreCollections.bills,
      chatRoomIds: chatRoomIds,
      orderByField: 'createdAt',
      limit: limit,
    );

    return docs
        .map((doc) => ActivityFeedMapper.fromBillDoc(doc.id, doc.data()))
        .whereType<RecentActivity>()
        .toList(growable: false);
  }

  Future<List<RecentActivity>> _getGroceryActivities({
    required List<String> chatRoomIds,
    required int limit,
  }) async {
    final docs = await _getRecentDocsByChatRooms(
      collection: FirestoreCollections.groceryItems,
      chatRoomIds: chatRoomIds,
      orderByField: 'createdAt',
      limit: limit,
    );

    return docs
        .map((doc) => ActivityFeedMapper.fromGroceryDoc(doc.id, doc.data()))
        .whereType<RecentActivity>()
        .toList(growable: false);
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _getRecentDocsByChatRooms({
    required String collection,
    required List<String> chatRoomIds,
    required String orderByField,
    required int limit,
  }) async {
    if (chatRoomIds.isEmpty) {
      return const [];
    }

    final futures = <Future<QuerySnapshot<Map<String, dynamic>>>>[];
    for (var i = 0; i < chatRoomIds.length; i += _whereInLimit) {
      final batch = chatRoomIds.skip(i).take(_whereInLimit).toList();
      futures.add(
        firestore
            .collection(collection)
            .where('chatRoomId', whereIn: batch)
            .orderBy(orderByField, descending: true)
            .limit(limit)
            .get(),
      );
    }

    final snapshots = await Future.wait(futures);
    final deduped = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final snapshot in snapshots) {
      for (final doc in snapshot.docs) {
        deduped[doc.id] = doc;
      }
    }

    final docs = deduped.values.toList()
      ..sort((a, b) {
        final left = ActivityFeedMapper.parseDateTime(a.data()[orderByField]);
        final right = ActivityFeedMapper.parseDateTime(b.data()[orderByField]);
        if (left == null && right == null) return 0;
        if (left == null) return 1;
        if (right == null) return -1;
        return right.compareTo(left);
      });
    return docs.take(limit).toList(growable: false);
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _getRelevantExpenseDocs({
    required String userId,
    required List<String> chatRoomIds,
  }) async {
    final futures = <Future<QuerySnapshot<Map<String, dynamic>>>>[
      firestore
          .collection(FirestoreCollections.expenses)
          .where('ownerId', isEqualTo: userId)
          .get(),
      firestore
          .collection(FirestoreCollections.expenses)
          .where('adHocParticipantIds', arrayContains: userId)
          .get(),
    ];

    // Firestore whereIn limit is 30, so fetch by chat room in batches.
    for (var i = 0; i < chatRoomIds.length; i += _whereInLimit) {
      final batch = chatRoomIds.skip(i).take(_whereInLimit).toList();
      futures.add(
        firestore
            .collection(FirestoreCollections.expenses)
            .where('chatRoomId', whereIn: batch)
            .get(),
      );
    }

    final snapshots = await Future.wait(futures);
    final deduped = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final snapshot in snapshots) {
      for (final doc in snapshot.docs) {
        deduped[doc.id] = doc;
      }
    }
    return deduped.values.toList();
  }

  Future<QuerySnapshot<Map<String, dynamic>>?> _getPendingBillsSnapshot({
    required List<String> chatRoomIds,
  }) {
    if (chatRoomIds.isEmpty) {
      return Future.value(null);
    }

    return firestore
        .collection(FirestoreCollections.bills)
        .where('chatRoomId', whereIn: chatRoomIds.take(_whereInLimit).toList())
        .get();
  }
}
