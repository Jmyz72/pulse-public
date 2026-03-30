import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/error/exceptions.dart';
import '../../core/chat_constants.dart';
import '../models/message_model.dart';

abstract class ChatRemoteDataSource {
  Future<List<ChatRoomModel>> getChatRooms();
  Stream<List<ChatRoomModel>> watchChatRooms();
  Future<ChatRoomModel> getChatRoomById(String id);
  Stream<ChatRoomModel> watchChatRoom(String id);
  Future<ChatRoomModel> createChatRoom(ChatRoomModel chatRoom);
  Future<void> deleteChatRoom(String chatRoomId);
  Future<List<MessageModel>> getMessages(String chatRoomId, {int limit, String? startAfterMessageId});
  Future<MessageModel> sendMessage(MessageModel message);
  Future<void> markAsRead(String chatRoomId, String userId);
  Stream<List<MessageModel>> watchMessages(String chatRoomId, {int limit});
  Future<void> editMessage(String chatRoomId, String messageId, String newContent);
  Future<void> deleteMessage(String chatRoomId, String messageId);
  Future<void> setTypingStatus(String chatRoomId, String userId, bool isTyping);
  Stream<List<String>> watchTypingUsers(String chatRoomId, String currentUserId);
  Future<String> uploadChatMedia(String chatRoomId, String filePath, String fileName);
  Future<void> addChatMember(String chatRoomId, String userId);
  Future<void> removeChatMember(String chatRoomId, String userId);
  Future<void> leaveGroup(String chatRoomId, String userId);
  Future<void> makeAdmin(String chatRoomId, String userId);
  Future<void> removeAdmin(String chatRoomId, String userId);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;
  final FirebaseStorage? firebaseStorage;

  ChatRemoteDataSourceImpl({
    required this.firestore,
    required this.firebaseAuth,
    this.firebaseStorage,
  });

  @override
  Future<List<ChatRoomModel>> getChatRooms() async {
    try {
      final currentUser = firebaseAuth.currentUser;
      if (currentUser == null) {
        throw const ServerException(message: 'User not authenticated');
      }

      final snapshot = await firestore
          .collection(FirestoreCollections.chatRooms)
          .where('members', arrayContains: currentUser.uid)
          .orderBy('lastMessageAt', descending: true)
          .get();

      final rooms = snapshot.docs.map((doc) {
        final docData = doc.data();
        // CRITICAL FIX: Set ID from doc.id AFTER spreading data to ensure it's not overridden
        final data = <String, dynamic>{
          ...docData,
          'id': doc.id, // Override any 'id' field in docData with the real document ID
        };

        return ChatRoomModel.fromJson(data);
      }).toList();

      return _enrichLegacyRooms(rooms);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Stream<List<ChatRoomModel>> watchChatRooms() {
    final currentUser = firebaseAuth.currentUser;
    if (currentUser == null) {
      return Stream.error(const ServerException(message: 'User not authenticated'));
    }

    return firestore
        .collection(FirestoreCollections.chatRooms)
        .where('members', arrayContains: currentUser.uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) {
      final rooms = snapshot.docs.map((doc) {
        final docData = doc.data();
        // Set ID from doc.id AFTER spreading data
        final data = <String, dynamic>{
          ...docData,
          'id': doc.id,
        };
        return ChatRoomModel.fromJson(data);
      }).toList();
      return _enrichLegacyRooms(rooms);
    });
  }

  @override
  Future<ChatRoomModel> getChatRoomById(String id) async {
    try {
      final doc = await firestore.collection(FirestoreCollections.chatRooms).doc(id).get();
      if (!doc.exists) {
        throw const ServerException(message: 'Chat room not found');
      }
      final room = ChatRoomModel.fromJson({...doc.data()!, 'id': doc.id});
      final enriched = await _enrichLegacyRooms([room]);
      return enriched.first;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Stream<ChatRoomModel> watchChatRoom(String id) {
    return firestore
        .collection(FirestoreCollections.chatRooms)
        .doc(id)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        throw const ServerException(message: 'Chat room not found');
      }
      return ChatRoomModel.fromJson({...doc.data()!, 'id': doc.id});
    });
  }

  @override
  Future<ChatRoomModel> createChatRoom(ChatRoomModel chatRoom) async {
    try {
      // For 1-on-1 chats, check if a conversation already exists
      if (!chatRoom.isGroup && chatRoom.members.length == 2) {
        final existing = await firestore
            .collection(FirestoreCollections.chatRooms)
            .where('isGroup', isEqualTo: false)
            .where('members', isEqualTo: chatRoom.members)
            .limit(1)
            .get();

        if (existing.docs.isNotEmpty) {
          final doc = existing.docs.first;
          return ChatRoomModel.fromJson({...doc.data(), 'id': doc.id});
        }

        // Also check reversed member order
        final reversedMembers = chatRoom.members.reversed.toList();
        final existingReversed = await firestore
            .collection(FirestoreCollections.chatRooms)
            .where('isGroup', isEqualTo: false)
            .where('members', isEqualTo: reversedMembers)
            .limit(1)
            .get();

        if (existingReversed.docs.isNotEmpty) {
          final doc = existingReversed.docs.first;
          return ChatRoomModel.fromJson({...doc.data(), 'id': doc.id});
        }
      }

      // For group chats, set the creator as the first admin
      final dataToSave = chatRoom.toJson();
      if (chatRoom.isGroup && chatRoom.members.isNotEmpty) {
        final creatorId = chatRoom.createdBy ?? chatRoom.members.first;
        dataToSave['createdBy'] = creatorId;
        dataToSave['admins'] = chatRoom.admins.isNotEmpty ? chatRoom.admins : [creatorId];
      }

      final docRef = await firestore.collection(FirestoreCollections.chatRooms).add(dataToSave);
      return ChatRoomModel.fromJson({...dataToSave, 'id': docRef.id});
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deleteChatRoom(String chatRoomId) async {
    try {
      // Delete all messages in batches (Firestore limit: 500 per batch)
      final messagesRef = firestore
          .collection(FirestoreCollections.chatRooms)
          .doc(chatRoomId)
          .collection(FirestoreCollections.messages);

      QuerySnapshot snapshot;
      do {
        snapshot = await messagesRef.limit(ChatConstants.batchDeleteLimit).get();
        if (snapshot.docs.isEmpty) break;
        final batch = firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      } while (snapshot.docs.length == ChatConstants.batchDeleteLimit);

      // Delete the chat room document
      await firestore.collection(FirestoreCollections.chatRooms).doc(chatRoomId).delete();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<MessageModel>> getMessages(String chatRoomId, {int limit = ChatConstants.messagePaginationLimit, String? startAfterMessageId}) async {
    try {
      Query query = firestore
          .collection(FirestoreCollections.chatRooms)
          .doc(chatRoomId)
          .collection(FirestoreCollections.messages)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (startAfterMessageId != null) {
        final startAfterDoc = await firestore
            .collection(FirestoreCollections.chatRooms)
            .doc(chatRoomId)
            .collection(FirestoreCollections.messages)
            .doc(startAfterMessageId)
            .get();
        if (startAfterDoc.exists) {
          query = query.startAfterDocument(startAfterDoc);
        }
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => MessageModel.fromJson({'id': doc.id, ...doc.data() as Map<String, dynamic>}))
          .toList()
          .reversed
          .toList();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<MessageModel> sendMessage(MessageModel message) async {
    try {
      final docRef = await firestore
          .collection(FirestoreCollections.chatRooms)
          .doc(message.chatRoomId)
          .collection(FirestoreCollections.messages)
          .add(message.toJson());

      // Update last message and timestamp in chat room
      await firestore.collection(FirestoreCollections.chatRooms).doc(message.chatRoomId).update({
        'lastMessage': message.toJson(),
        'lastMessageAt': FieldValue.serverTimestamp(), // For sorting by recent activity
      });

      return MessageModel.fromJson({'id': docRef.id, ...message.toJson()});
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> markAsRead(String chatRoomId, String userId) async {
    try {
      await firestore
          .collection(FirestoreCollections.chatRooms)
          .doc(chatRoomId)
          .update({'lastReadAt.$userId': FieldValue.serverTimestamp()});
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Stream<List<MessageModel>> watchMessages(String chatRoomId, {int limit = ChatConstants.messagePaginationLimit}) {
    return firestore
        .collection(FirestoreCollections.chatRooms)
        .doc(chatRoomId)
        .collection(FirestoreCollections.messages)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromJson({'id': doc.id, ...doc.data()}))
            .toList()
            .reversed
            .toList());
  }

  @override
  Future<void> editMessage(String chatRoomId, String messageId, String newContent) async {
    try {
      await firestore
          .collection(FirestoreCollections.chatRooms)
          .doc(chatRoomId)
          .collection(FirestoreCollections.messages)
          .doc(messageId)
          .update({
        'content': newContent,
        'editedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deleteMessage(String chatRoomId, String messageId) async {
    try {
      await firestore
          .collection(FirestoreCollections.chatRooms)
          .doc(chatRoomId)
          .collection(FirestoreCollections.messages)
          .doc(messageId)
          .update({
        'isDeleted': true,
        'content': '',
      });
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> setTypingStatus(String chatRoomId, String userId, bool isTyping) async {
    try {
      final ref = firestore
          .collection(FirestoreCollections.chatRooms)
          .doc(chatRoomId)
          .collection(FirestoreCollections.typing)
          .doc(userId);

      if (isTyping) {
        await ref.set({
          'isTyping': true,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        await ref.delete();
      }
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Stream<List<String>> watchTypingUsers(String chatRoomId, String currentUserId) {
    return firestore
        .collection(FirestoreCollections.chatRooms)
        .doc(chatRoomId)
        .collection(FirestoreCollections.typing)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      return snapshot.docs
          .where((doc) {
            if (doc.id == currentUserId) return false;
            final data = doc.data();
            if (data['isTyping'] != true) return false;
            final timestamp = data['timestamp'];
            if (timestamp is Timestamp) {
              return now.difference(timestamp.toDate()).inSeconds < ChatConstants.typingTimeoutSeconds;
            }
            return false;
          })
          .map((doc) => doc.id)
          .toList();
    });
  }

  @override
  Future<String> uploadChatMedia(String chatRoomId, String filePath, String fileName) async {
    try {
      final storage = firebaseStorage ?? FirebaseStorage.instance;
      final uuid = const Uuid().v4();
      final ref = storage.ref().child('chat_media/$chatRoomId/${uuid}_$fileName');
      final uploadTask = await ref.putFile(File(filePath));
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> addChatMember(String chatRoomId, String userId) async {
    try {
      await firestore.collection(FirestoreCollections.chatRooms).doc(chatRoomId).update({
        'members': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> removeChatMember(String chatRoomId, String userId) async {
    try {
      await firestore.collection(FirestoreCollections.chatRooms).doc(chatRoomId).update({
        'members': FieldValue.arrayRemove([userId]),
        'admins': FieldValue.arrayRemove([userId]),
        'memberNames.$userId': FieldValue.delete(),
      });
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> leaveGroup(String chatRoomId, String userId) async {
    try {
      final docRef = firestore.collection(FirestoreCollections.chatRooms).doc(chatRoomId);

      final shouldDelete = await firestore.runTransaction<bool>((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) {
          throw const ServerException(message: 'Chat room not found');
        }

        final data = doc.data()!;
        final members = List<String>.from(data['members'] ?? []);
        final admins = List<String>.from(data['admins'] ?? []);
        final memberNames = Map<String, dynamic>.from(data['memberNames'] ?? {});

        // Remove user from members and memberNames
        members.remove(userId);
        memberNames.remove(userId);

        // If leaving user is an admin, handle admin transfer
        if (admins.contains(userId)) {
          admins.remove(userId);
          // If no admins left and there are still members, promote the first member
          if (admins.isEmpty && members.isNotEmpty) {
            admins.add(members.first);
          }
        }

        // Delete the chat room if no members left
        if (members.isEmpty) {
          return true;
        }

        transaction.update(docRef, {
          'members': members,
          'admins': admins,
          'memberNames': memberNames,
        });
        return false;
      });

      if (shouldDelete) {
        await deleteChatRoom(chatRoomId);
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> makeAdmin(String chatRoomId, String userId) async {
    try {
      await firestore.runTransaction((transaction) async {
        final docRef = firestore.collection(FirestoreCollections.chatRooms).doc(chatRoomId);
        final doc = await transaction.get(docRef);
        if (!doc.exists) {
          throw const ServerException(message: 'Chat room not found');
        }

        final members = List<String>.from(doc.data()!['members'] ?? []);
        if (!members.contains(userId)) {
          throw const ServerException(message: 'User is not a member of this group');
        }

        transaction.update(docRef, {'admins': FieldValue.arrayUnion([userId])});
      });
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> removeAdmin(String chatRoomId, String userId) async {
    try {
      await firestore.runTransaction((transaction) async {
        final docRef = firestore.collection(FirestoreCollections.chatRooms).doc(chatRoomId);
        final doc = await transaction.get(docRef);
        if (!doc.exists) {
          throw const ServerException(message: 'Chat room not found');
        }

        final admins = List<String>.from(doc.data()!['admins'] ?? []);

        // Prevent removing the last admin
        if (admins.length <= 1 && admins.contains(userId)) {
          throw const ServerException(message: 'Cannot remove the last admin');
        }

        transaction.update(docRef, {'admins': FieldValue.arrayRemove([userId])});
      });
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  /// Enriches legacy 1:1 chat rooms that have empty [memberNames] by fetching
  /// display names from the users collection. Persists the fix to Firestore
  /// (fire-and-forget) so enrichment only runs once per legacy room.
  Future<List<ChatRoomModel>> _enrichLegacyRooms(List<ChatRoomModel> rooms) async {
    final currentUid = firebaseAuth.currentUser?.uid;
    if (currentUid == null) return rooms;

    final legacyRooms = rooms.where((r) => r.memberNames.isEmpty).toList();
    if (legacyRooms.isEmpty) return rooms;

    // Collect unique user IDs needing name lookup
    final userIds = <String>{};
    for (final room in legacyRooms) {
      userIds.addAll(room.members);
    }

    // Batch-fetch user profiles
    final nameMap = <String, String>{};
    final futures = userIds.map((uid) =>
        firestore.collection(FirestoreCollections.users).doc(uid).get());
    final docs = await Future.wait(futures);
    for (final doc in docs) {
      if (doc.exists) {
        nameMap[doc.id] = (doc.data()?['displayName'] as String?) ?? doc.id;
      }
    }

    // Enrich rooms + fire-and-forget Firestore writes
    final legacyIds = legacyRooms.map((r) => r.id).toSet();
    return rooms.map((room) {
      if (!legacyIds.contains(room.id)) return room;

      final enriched = <String, String>{};
      for (final mid in room.members) {
        enriched[mid] = nameMap[mid] ?? mid;
      }

      // Persist (fire-and-forget, errors silently caught)
      firestore.collection(FirestoreCollections.chatRooms).doc(room.id)
          .update({'memberNames': enriched}).catchError((_) {});

      return ChatRoomModel(
        id: room.id,
        name: room.name,
        members: room.members,
        lastMessage: room.lastMessage,
        lastMessageAt: room.lastMessageAt,
        createdAt: room.createdAt,
        isGroup: room.isGroup,
        imageUrl: room.imageUrl,
        lastReadAt: room.lastReadAt,
        createdBy: room.createdBy,
        admins: room.admins,
        memberNames: enriched,
      );
    }).toList();
  }
}
