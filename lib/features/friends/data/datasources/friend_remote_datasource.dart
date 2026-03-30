import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/services/profile_sync_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/user.dart';
import '../models/friend_profile_stats_model.dart';
import '../models/friendship_model.dart';

abstract class FriendRemoteDataSource {
  Future<List<FriendshipModel>> getFriends(String userId);
  Future<List<FriendshipModel>> getPendingRequests(String userId);
  Future<List<FriendshipModel>> getSentRequests(String userId);
  Future<FriendshipModel> sendFriendRequest(String userId, String friendEmail);
  Future<void> acceptFriendRequest(String friendshipId);
  Future<void> declineFriendRequest(String friendshipId);
  Future<void> removeFriend(String friendshipId);
  Future<List<User>> searchUsers(String query);
  Future<FriendProfileStatsModel> getFriendProfileStats({
    required String currentUserId,
    required String friendUserId,
  });
  Future<void> syncDenormalizedData(
    String uid,
    String displayName,
    String username,
    String phone,
    String? photoUrl,
  );
}

class FriendRemoteDataSourceImpl
    implements FriendRemoteDataSource, ProfileSyncService {
  final FirebaseFirestore firestore;
  final FirebaseFunctions functions;

  FriendRemoteDataSourceImpl({
    required this.firestore,
    required this.functions,
  });

  @override
  Future<List<FriendshipModel>> getFriends(String userId) async {
    try {
      // Query where user is the requester
      final asRequester = await firestore
          .collection(FirestoreCollections.friendships)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'accepted')
          .get();

      // Query where user is the friend
      final asFriend = await firestore
          .collection(FirestoreCollections.friendships)
          .where('friendId', isEqualTo: userId)
          .where('status', isEqualTo: 'accepted')
          .get();

      final results = <FriendshipModel>[];

      for (final doc in asRequester.docs) {
        results.add(FriendshipModel.fromJson({'id': doc.id, ...doc.data()}));
      }

      // For the reverse direction, swap denorm fields so the caller always
      // sees the *other* user's info in the friend* fields.
      for (final doc in asFriend.docs) {
        final data = doc.data();
        results.add(
          FriendshipModel.fromJson({
            'id': doc.id,
            'userId': userId,
            'friendId': data['userId'],
            'friendUsername': data['requesterUsername'] ?? '',
            'friendDisplayName': data['requesterDisplayName'] ?? '',
            'friendEmail': data['requesterEmail'] ?? '',
            'friendPhone': data['requesterPhone'] ?? '',
            'friendPhotoUrl': data['requesterPhotoUrl'],
            'requesterUsername': data['friendUsername'] ?? '',
            'requesterDisplayName': data['friendDisplayName'] ?? '',
            'requesterEmail': data['friendEmail'] ?? '',
            'requesterPhone': data['friendPhone'] ?? '',
            'requesterPhotoUrl': data['friendPhotoUrl'],
            'status': data['status'],
            'createdAt': data['createdAt'],
            'updatedAt': data['updatedAt'],
          }),
        );
      }

      return results;
    } catch (e) {
      if (e is ServerException) rethrow;
      if (e is FirebaseException) {
        throw ServerException(message: e.message ?? 'Firebase error');
      }
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<FriendshipModel>> getPendingRequests(String userId) async {
    try {
      final snapshot = await firestore
          .collection(FirestoreCollections.friendships)
          .where('friendId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      return snapshot.docs
          .map((doc) => FriendshipModel.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      if (e is ServerException) rethrow;
      if (e is FirebaseException) {
        throw ServerException(message: e.message ?? 'Firebase error');
      }
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<FriendshipModel>> getSentRequests(String userId) async {
    try {
      final snapshot = await firestore
          .collection(FirestoreCollections.friendships)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      return snapshot.docs
          .map((doc) => FriendshipModel.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      if (e is ServerException) rethrow;
      if (e is FirebaseException) {
        throw ServerException(message: e.message ?? 'Firebase error');
      }
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<FriendshipModel> sendFriendRequest(
    String userId,
    String friendEmail,
  ) async {
    try {
      // Look up friend by email
      final userQuery = await firestore
          .collection(FirestoreCollections.users)
          .where('email', isEqualTo: friendEmail.toLowerCase())
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw const ServerException(message: 'No user found with that email');
      }

      final friendDoc = userQuery.docs.first;
      final friendId = friendDoc.id;
      final friendData = friendDoc.data();
      final friendUsername = friendData['username'] ?? '';
      final friendDisplayName = friendData['displayName'] ?? '';
      final friendPhone = friendData['phone'] ?? '';

      if (friendId == userId) {
        throw const ServerException(
          message: 'You cannot add yourself as a friend',
        );
      }

      // Check existing friendship in both directions
      final existing1 = await firestore
          .collection(FirestoreCollections.friendships)
          .where('userId', isEqualTo: userId)
          .where('friendId', isEqualTo: friendId)
          .limit(1)
          .get();

      final existing2 = await firestore
          .collection(FirestoreCollections.friendships)
          .where('userId', isEqualTo: friendId)
          .where('friendId', isEqualTo: userId)
          .limit(1)
          .get();

      if (existing1.docs.isNotEmpty || existing2.docs.isNotEmpty) {
        throw const ServerException(
          message: 'A friendship or request already exists with this user',
        );
      }

      // Get current user's data
      final currentUserDoc = await firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .get();
      final requesterUsername = currentUserDoc.data()?['username'] ?? '';
      final requesterDisplayName = currentUserDoc.data()?['displayName'] ?? '';
      final requesterEmail = currentUserDoc.data()?['email'] ?? '';
      final requesterPhone = currentUserDoc.data()?['phone'] ?? '';
      final requesterPhotoUrl = currentUserDoc.data()?['photoUrl'];
      final friendPhotoUrl = friendData['photoUrl'];

      final data = {
        'userId': userId,
        'friendId': friendId,
        'friendUsername': friendUsername,
        'friendDisplayName': friendDisplayName,
        'friendEmail': friendEmail.toLowerCase(),
        'friendPhone': friendPhone,
        'friendPhotoUrl': friendPhotoUrl,
        'requesterUsername': requesterUsername,
        'requesterDisplayName': requesterDisplayName,
        'requesterEmail': requesterEmail,
        'requesterPhone': requesterPhone,
        'requesterPhotoUrl': requesterPhotoUrl,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await firestore
          .collection(FirestoreCollections.friendships)
          .add(data);

      // Read back to get server-resolved timestamps
      final savedDoc = await docRef.get();
      return FriendshipModel.fromJson({'id': docRef.id, ...savedDoc.data()!});
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> acceptFriendRequest(String friendshipId) async {
    try {
      await firestore.runTransaction((transaction) async {
        final freshDoc = await transaction.get(
          firestore
              .collection(FirestoreCollections.friendships)
              .doc(friendshipId),
        );
        if (!freshDoc.exists || freshDoc.data()?['status'] != 'pending') {
          throw const ServerException(
            message: 'Friend request no longer pending',
          );
        }

        transaction.update(
          firestore
              .collection(FirestoreCollections.friendships)
              .doc(friendshipId),
          {'status': 'accepted', 'updatedAt': FieldValue.serverTimestamp()},
        );
      });
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> declineFriendRequest(String friendshipId) async {
    try {
      await firestore.runTransaction((transaction) async {
        final doc = await transaction.get(
          firestore
              .collection(FirestoreCollections.friendships)
              .doc(friendshipId),
        );
        if (!doc.exists || doc.data()?['status'] != 'pending') {
          throw const ServerException(
            message: 'Friend request is no longer pending',
          );
        }
        transaction.delete(
          firestore
              .collection(FirestoreCollections.friendships)
              .doc(friendshipId),
        );
      });
    } catch (e) {
      if (e is ServerException) rethrow;
      if (e is FirebaseException) {
        throw ServerException(message: e.message ?? 'Firebase error');
      }
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> removeFriend(String friendshipId) async {
    try {
      await firestore
          .collection(FirestoreCollections.friendships)
          .doc(friendshipId)
          .delete();
    } catch (e) {
      if (e is ServerException) rethrow;
      if (e is FirebaseException) {
        throw ServerException(message: e.message ?? 'Firebase error');
      }
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<User>> searchUsers(String query) async {
    try {
      final lowerQuery = query.toLowerCase();
      final phoneDigitsQuery = Validators.phoneSearchDigits(query);

      // Run all search queries in parallel for better performance
      final usernameFuture = firestore
          .collection(FirestoreCollections.users)
          .where('username', isGreaterThanOrEqualTo: lowerQuery)
          .where('username', isLessThanOrEqualTo: '$lowerQuery\uf8ff')
          .limit(20)
          .get();
      final emailFuture = firestore
          .collection(FirestoreCollections.users)
          .where('email', isGreaterThanOrEqualTo: lowerQuery)
          .where('email', isLessThanOrEqualTo: '$lowerQuery\uf8ff')
          .limit(20)
          .get();

      final searchFutures = <Future<QuerySnapshot<Map<String, dynamic>>>>[
        usernameFuture,
        emailFuture,
      ];

      if (phoneDigitsQuery.isNotEmpty) {
        searchFutures.add(
          firestore
              .collection(FirestoreCollections.users)
              .where(
                'phoneSearchDigits',
                isGreaterThanOrEqualTo: phoneDigitsQuery,
              )
              .where(
                'phoneSearchDigits',
                isLessThanOrEqualTo: '$phoneDigitsQuery\uf8ff',
              )
              .limit(20)
              .get(),
        );
      }

      final searchResults = await Future.wait(searchFutures);

      final usernameSnapshot = searchResults[0];
      final emailSnapshot = searchResults[1];
      final phoneSnapshot = searchResults.length > 2 ? searchResults[2] : null;

      // Track which search method found each user
      final Map<String, User> results = {};
      final Map<String, String> searchMethod = {};

      for (final doc in usernameSnapshot.docs) {
        if (!results.containsKey(doc.id)) {
          results[doc.id] = UserModel.fromJson({'id': doc.id, ...doc.data()});
          searchMethod[doc.id] = 'username';
        }
      }
      for (final doc in emailSnapshot.docs) {
        if (!results.containsKey(doc.id)) {
          results[doc.id] = UserModel.fromJson({'id': doc.id, ...doc.data()});
          searchMethod[doc.id] = 'email';
        }
      }
      if (phoneSnapshot != null) {
        for (final doc in phoneSnapshot.docs) {
          if (!results.containsKey(doc.id)) {
            results[doc.id] = UserModel.fromJson({'id': doc.id, ...doc.data()});
            searchMethod[doc.id] = 'phone';
          }
        }
      }

      if (results.isEmpty) return [];

      // Batch fetch all search settings in parallel (instead of sequential reads)
      final settingsFutures = results.keys.map(
        (uid) => firestore
            .collection(FirestoreCollections.userSearchSettings)
            .doc(uid)
            .get(),
      );
      final settingsSnapshots = await Future.wait(settingsFutures);

      // Build a map of uid -> settings data
      final Map<String, Map<String, dynamic>?> settingsMap = {};
      final uidList = results.keys.toList();
      for (var i = 0; i < uidList.length; i++) {
        final snapshot = settingsSnapshots[i];
        settingsMap[uidList[i]] = snapshot.exists ? snapshot.data() : null;
      }

      // Filter out users who disabled the matching search method
      final filteredResults = <User>[];
      for (final entry in results.entries) {
        final uid = entry.key;
        final user = entry.value;
        final method = searchMethod[uid]!;
        final settings = settingsMap[uid];

        // If no settings exist, user is searchable by default
        if (settings != null) {
          if (method == 'username' &&
              settings['searchableByUsername'] == false) {
            continue;
          }
          if (method == 'email' && settings['searchableByEmail'] == false) {
            continue;
          }
          if (method == 'phone' && settings['searchableByPhone'] == false) {
            continue;
          }
        }

        filteredResults.add(user);
      }

      return filteredResults;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<FriendProfileStatsModel> getFriendProfileStats({
    required String currentUserId,
    required String friendUserId,
  }) async {
    try {
      final callable = functions.httpsCallable('getFriendProfileStats');
      final result = await callable.call(<String, dynamic>{
        'friendUserId': friendUserId,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      return FriendProfileStatsModel.fromJson(data);
    } on FirebaseFunctionsException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to load friend profile stats',
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      if (e is FirebaseException) {
        throw ServerException(message: e.message ?? 'Firebase error');
      }
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> syncDenormalizedData(
    String uid,
    String displayName,
    String username,
    String phone,
    String? photoUrl,
  ) async {
    try {
      final asRequester = await firestore
          .collection(FirestoreCollections.friendships)
          .where('userId', isEqualTo: uid)
          .get();

      final asFriend = await firestore
          .collection(FirestoreCollections.friendships)
          .where('friendId', isEqualTo: uid)
          .get();

      final updates = <(DocumentReference, Map<String, dynamic>)>[];

      for (final doc in asRequester.docs) {
        final updateData = <String, dynamic>{
          'requesterDisplayName': displayName,
          'requesterUsername': username,
          'requesterPhone': phone,
          'requesterPhotoUrl': photoUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        updates.add((doc.reference, updateData));
      }

      for (final doc in asFriend.docs) {
        final updateData = <String, dynamic>{
          'friendDisplayName': displayName,
          'friendUsername': username,
          'friendPhone': phone,
          'friendPhotoUrl': photoUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        updates.add((doc.reference, updateData));
      }

      // Sync memberNames in chat rooms the user belongs to
      final chatRoomsSnapshot = await firestore
          .collection(FirestoreCollections.chatRooms)
          .where('members', arrayContains: uid)
          .get();
      for (final doc in chatRoomsSnapshot.docs) {
        updates.add((doc.reference, {'memberNames.$uid': displayName}));
      }

      const batchLimit = 500;
      for (var i = 0; i < updates.length; i += batchLimit) {
        final batch = firestore.batch();
        final chunk = updates.sublist(
          i,
          i + batchLimit > updates.length ? updates.length : i + batchLimit,
        );
        for (final (ref, data) in chunk) {
          batch.update(ref, data);
        }
        await batch.commit();
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      if (e is FirebaseException) {
        throw ServerException(message: e.message ?? 'Firebase error');
      }
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> syncProfile(
    String userId,
    String displayName,
    String username,
    String phone,
    String? photoUrl,
  ) {
    return syncDenormalizedData(userId, displayName, username, phone, photoUrl);
  }
}
