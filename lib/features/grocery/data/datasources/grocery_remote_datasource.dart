import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/error/exceptions.dart';
import '../models/grocery_item_model.dart';

abstract class GroceryRemoteDataSource {
  Future<List<GroceryItemModel>> getGroceryItems(List<String> chatRoomIds);
  Future<GroceryItemModel> addGroceryItem(
    GroceryItemModel item, {
    String? imagePath,
  });
  Future<GroceryItemModel> updateGroceryItem(
    GroceryItemModel item, {
    String? imagePath,
    bool clearImage = false,
  });
  Future<void> deleteGroceryItem(String id);
  Future<void> togglePurchased(
    String id, {
    required String userId,
    String? userName,
  });
  Future<List<GroceryItemModel>> getGroceryItemsByChatRoom(String chatRoomId);
  Stream<List<GroceryItemModel>> watchGroceryItems(List<String> chatRoomIds);
}

class GroceryRemoteDataSourceImpl implements GroceryRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage firebaseStorage;

  GroceryRemoteDataSourceImpl({
    required this.firestore,
    required this.firebaseStorage,
  });

  @override
  Future<List<GroceryItemModel>> getGroceryItems(
    List<String> chatRoomIds,
  ) async {
    try {
      if (chatRoomIds.isEmpty) {
        return [];
      }

      final List<GroceryItemModel> allItems = [];

      // Firestore whereIn limit is 30, batch if needed
      for (var i = 0; i < chatRoomIds.length; i += 30) {
        final batch = chatRoomIds.skip(i).take(30).toList();
        final snapshot = await firestore
            .collection(FirestoreCollections.groceryItems)
            .where('chatRoomId', whereIn: batch)
            .orderBy('createdAt', descending: true)
            .get();

        allItems.addAll(
          snapshot.docs.map(
            (doc) => GroceryItemModel.fromJson({'id': doc.id, ...doc.data()}),
          ),
        );
      }

      // Sort by createdAt descending after combining batches
      allItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return allItems;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Stream<List<GroceryItemModel>> watchGroceryItems(List<String> chatRoomIds) {
    if (chatRoomIds.isEmpty) return Stream.value([]);
    final batch = chatRoomIds.take(30).toList();
    return firestore
        .collection(FirestoreCollections.groceryItems)
        .where('chatRoomId', whereIn: batch)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) =>
                    GroceryItemModel.fromJson({'id': doc.id, ...doc.data()}),
              )
              .toList(),
        );
  }

  @override
  Future<GroceryItemModel> addGroceryItem(
    GroceryItemModel item, {
    String? imagePath,
  }) async {
    try {
      final data = item.toJson();
      data.remove('id');
      if (imagePath != null && imagePath.isNotEmpty) {
        data['imageUrl'] = await _uploadGroceryImage(
          chatRoomId: item.chatRoomId,
          itemId: item.id,
          imagePath: imagePath,
        );
      }
      await firestore
          .collection(FirestoreCollections.groceryItems)
          .doc(item.id)
          .set(data);
      return GroceryItemModel.fromJson({'id': item.id, ...data});
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<GroceryItemModel> updateGroceryItem(
    GroceryItemModel item, {
    String? imagePath,
    bool clearImage = false,
  }) async {
    try {
      final data = item.toJson();
      data.remove('id');
      data.remove('purchasedBy');
      data.remove('purchasedByName');
      if (imagePath != null && imagePath.isNotEmpty) {
        data['imageUrl'] = await _uploadGroceryImage(
          chatRoomId: item.chatRoomId,
          itemId: item.id,
          imagePath: imagePath,
        );
      } else if (clearImage) {
        data['imageUrl'] = null;
      }
      await firestore
          .collection(FirestoreCollections.groceryItems)
          .doc(item.id)
          .update(data);
      return GroceryItemModel.fromEntity(
        item.copyWith(
          imageUrl: data['imageUrl'] as String?,
          clearImageUrl: clearImage && (imagePath == null || imagePath.isEmpty),
        ),
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deleteGroceryItem(String id) async {
    try {
      await firestore
          .collection(FirestoreCollections.groceryItems)
          .doc(id)
          .delete();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> togglePurchased(
    String id, {
    required String userId,
    String? userName,
  }) async {
    try {
      final docRef = firestore
          .collection(FirestoreCollections.groceryItems)
          .doc(id);
      await firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) {
          throw const ServerException(message: 'Grocery item not found');
        }
        final currentValue = doc.data()?['isPurchased'] ?? false;
        if (!currentValue) {
          // Toggling on: set purchasedBy info
          transaction.update(docRef, {
            'isPurchased': true,
            'purchasedBy': userId,
            'purchasedByName': userName,
          });
        } else {
          // Toggling off: clear purchasedBy info
          transaction.update(docRef, {
            'isPurchased': false,
            'purchasedBy': null,
            'purchasedByName': null,
          });
        }
      });
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<GroceryItemModel>> getGroceryItemsByChatRoom(
    String chatRoomId,
  ) async {
    try {
      final snapshot = await firestore
          .collection(FirestoreCollections.groceryItems)
          .where('chatRoomId', isEqualTo: chatRoomId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map(
            (doc) => GroceryItemModel.fromJson({'id': doc.id, ...doc.data()}),
          )
          .toList();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  Future<String> _uploadGroceryImage({
    required String chatRoomId,
    required String itemId,
    required String imagePath,
  }) async {
    try {
      final fileName = imagePath.split('/').last;
      final uploadId = const Uuid().v4();
      final ref = firebaseStorage.ref().child(
        'grocery_items/$chatRoomId/$itemId/${uploadId}_$fileName',
      );
      final uploadTask = await ref.putFile(
        File(imagePath),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw ServerException(message: 'Failed to upload grocery image: $e');
    }
  }
}
