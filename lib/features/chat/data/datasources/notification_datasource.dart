import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/services/fcm_token_datasource.dart';

abstract class ChatNotificationDataSource implements FcmTokenDataSource {}

class ChatNotificationDataSourceImpl implements ChatNotificationDataSource {
  final FirebaseFirestore firestore;

  ChatNotificationDataSourceImpl({required this.firestore});

  @override
  Future<void> saveToken(String userId, String token) async {
    await firestore.collection(FirestoreCollections.users).doc(userId).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> deleteToken(String userId) async {
    await firestore.collection(FirestoreCollections.users).doc(userId).update({
      'fcmToken': FieldValue.delete(),
    });
  }
}
