import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../core/chat_constants.dart';
import '../../domain/repositories/presence_repository.dart';

abstract class PresenceDataSource implements PresenceRepository {}

class PresenceDataSourceImpl implements PresenceDataSource {
  final FirebaseFirestore firestore;

  PresenceDataSourceImpl({required this.firestore});

  @override
  Future<void> updatePresence(
    String userId,
    bool online, {
    bool updateLastSeen = true,
  }) async {
    try {
      final payload = <String, dynamic>{'online': online};
      if (updateLastSeen) {
        payload['lastSeen'] = FieldValue.serverTimestamp();
      }
      await firestore
          .collection(FirestoreCollections.presence)
          .doc(userId)
          .set(payload, SetOptions(merge: true));
    } catch (e) {
      // Silently ignore permission errors (expected during sign-out)
    }
  }

  @override
  Stream<Map<String, bool>> watchPresence(List<String> userIds) {
    if (userIds.isEmpty) return Stream.value({});

    final chunks = <List<String>>[];
    for (
      var i = 0;
      i < userIds.length;
      i += ChatConstants.presenceWhereInLimit
    ) {
      chunks.add(
        userIds.sublist(
          i,
          i + ChatConstants.presenceWhereInLimit > userIds.length
              ? userIds.length
              : i + ChatConstants.presenceWhereInLimit,
        ),
      );
    }

    if (chunks.length == 1) {
      return _watchChunk(chunks.first);
    }

    final controller = StreamController<Map<String, bool>>();
    final latestPerChunk = <int, Map<String, bool>>{};
    final subscriptions = <StreamSubscription<Map<String, bool>>>[];
    Timer? debounceTimer;
    Map<String, bool>? lastEmitted;

    void emitMerged() {
      final merged = <String, bool>{};
      for (final map in latestPerChunk.values) {
        merged.addAll(map);
      }
      // Only emit if the merged result actually changed
      if (lastEmitted == null || !_mapsEqual(lastEmitted!, merged)) {
        lastEmitted = Map.from(merged);
        controller.add(merged);
      }
    }

    for (var i = 0; i < chunks.length; i++) {
      final index = i;
      final sub = _watchChunk(chunks[index]).listen((chunkResult) {
        latestPerChunk[index] = chunkResult;
        // Debounce emissions to avoid excessive updates when multiple chunks change
        debounceTimer?.cancel();
        debounceTimer = Timer(const Duration(milliseconds: 50), emitMerged);
      }, onError: controller.addError);
      subscriptions.add(sub);
    }

    controller.onCancel = () {
      debounceTimer?.cancel();
      for (final sub in subscriptions) {
        sub.cancel();
      }
      if (!controller.isClosed) {
        controller.close();
      }
    };

    return controller.stream;
  }

  Stream<Map<String, bool>> _watchChunk(List<String> chunk) {
    return firestore
        .collection(FirestoreCollections.presence)
        .where(FieldPath.documentId, whereIn: chunk)
        .snapshots()
        .map((snapshot) {
          final result = <String, bool>{};
          for (final doc in snapshot.docs) {
            result[doc.id] = doc.data()['online'] == true;
          }
          return result;
        });
  }

  bool _mapsEqual(Map<String, bool> a, Map<String, bool> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}
