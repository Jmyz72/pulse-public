import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/timetable_entry.dart';
import '../models/timetable_entry_model.dart';

abstract class TimetableRemoteDataSource {
  Future<List<TimetableEntryModel>> getEntriesByUser(
    String userId,
    DateTime rangeStart,
    DateTime rangeEnd,
  );
  Future<TimetableEntryModel> addEntry(TimetableEntryModel entry);
  Future<TimetableEntryModel> updateEntry(TimetableEntryModel entry);
  Future<void> deleteEntry(String entryId);
  Future<List<TimetableEntryModel>> getSharedEntries(
    String targetUserId,
    String viewerId,
    DateTime rangeStart,
    DateTime rangeEnd,
  );
  Future<void> updateVisibility(
    String entryId,
    String visibility,
    List<String> visibleTo,
  );
}

class TimetableRemoteDataSourceImpl implements TimetableRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseFunctions? functions;

  TimetableRemoteDataSourceImpl({required this.firestore, this.functions});

  @override
  Future<List<TimetableEntryModel>> getEntriesByUser(
    String userId,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) async {
    try {
      final snapshot = await firestore
          .collection(FirestoreCollections.timetableEntries)
          .where('userId', isEqualTo: userId)
          .orderBy('startAt')
          .get();

      return snapshot.docs
          .map(
            (doc) =>
                TimetableEntryModel.fromJson({'id': doc.id, ...doc.data()}),
          )
          .where((entry) => _shouldIncludeForRange(entry, rangeStart, rangeEnd))
          .toList();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<TimetableEntryModel> addEntry(TimetableEntryModel entry) async {
    try {
      final data = entry.toJson();
      data.remove('id');
      final docRef = await firestore
          .collection(FirestoreCollections.timetableEntries)
          .add(data);
      return TimetableEntryModel.fromJson({'id': docRef.id, ...data});
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<TimetableEntryModel> updateEntry(TimetableEntryModel entry) async {
    try {
      final data = entry.toJson();
      data.remove('id');
      data['updatedAt'] = FieldValue.serverTimestamp();
      await firestore
          .collection(FirestoreCollections.timetableEntries)
          .doc(entry.id)
          .update(data);

      final updatedDoc = await firestore
          .collection(FirestoreCollections.timetableEntries)
          .doc(entry.id)
          .get();

      if (!updatedDoc.exists || updatedDoc.data() == null) {
        throw const ServerException(message: 'Entry not found after update');
      }

      return TimetableEntryModel.fromJson({
        'id': updatedDoc.id,
        ...updatedDoc.data()!,
      });
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deleteEntry(String entryId) async {
    try {
      await firestore
          .collection(FirestoreCollections.timetableEntries)
          .doc(entryId)
          .delete();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<TimetableEntryModel>> getSharedEntries(
    String targetUserId,
    String viewerId,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) async {
    try {
      if (functions != null) {
        final callable = functions!.httpsCallable('getSharedTimetable');
        final result = await callable.call(<String, dynamic>{
          'targetUserId': targetUserId,
          'rangeStart': rangeStart.toIso8601String(),
          'rangeEnd': rangeEnd.toIso8601String(),
        });
        final data = Map<String, dynamic>.from(result.data as Map);
        final rawEntries = (data['entries'] as List<dynamic>? ?? const []);

        return rawEntries
            .map(
              (entry) => TimetableEntryModel.fromJson(
                Map<String, dynamic>.from(entry as Map),
              ),
            )
            .toList();
      }

      final snapshot = await firestore
          .collection(FirestoreCollections.timetableEntries)
          .where('userId', isEqualTo: targetUserId)
          .orderBy('startAt')
          .get();

      final friendshipQueries = await Future.wait([
        firestore
            .collection(FirestoreCollections.friendships)
            .where('userId', isEqualTo: viewerId)
            .where('friendId', isEqualTo: targetUserId)
            .where('status', isEqualTo: 'accepted')
            .limit(1)
            .get(),
        firestore
            .collection(FirestoreCollections.friendships)
            .where('userId', isEqualTo: targetUserId)
            .where('friendId', isEqualTo: viewerId)
            .where('status', isEqualTo: 'accepted')
            .limit(1)
            .get(),
      ]);

      final isFriend =
          friendshipQueries[0].docs.isNotEmpty ||
          friendshipQueries[1].docs.isNotEmpty;

      return snapshot.docs
          .map(
            (doc) =>
                TimetableEntryModel.fromJson({'id': doc.id, ...doc.data()}),
          )
          .where((entry) {
            if (!_shouldIncludeForRange(entry, rangeStart, rangeEnd)) {
              return false;
            }
            if (entry.visibility == 'public') return true;
            if (entry.visibility == 'friends') return isFriend;
            if (entry.visibleTo.contains(viewerId)) return true;
            return false;
          })
          .toList();
    } on FirebaseFunctionsException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to load shared timetable',
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> updateVisibility(
    String entryId,
    String visibility,
    List<String> visibleTo,
  ) async {
    try {
      await firestore
          .collection(FirestoreCollections.timetableEntries)
          .doc(entryId)
          .update({
            'visibility': visibility,
            'visibleTo': visibleTo,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  bool _shouldIncludeForRange(
    TimetableEntryModel entry,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    switch (entry.entryType) {
      case TimetableEntryType.single:
        return _overlaps(entry.startAt, entry.endAt, rangeStart, rangeEnd);
      case TimetableEntryType.overrideEntry:
        final occursInRange = _overlaps(
          entry.startAt,
          entry.endAt,
          rangeStart,
          rangeEnd,
        );
        final originalDateInRange =
            entry.occurrenceDate != null &&
            _dateInRange(entry.occurrenceDate!, rangeStart, rangeEnd);
        return occursInRange || originalDateInRange;
      case TimetableEntryType.series:
        if (entry.startAt.isAfter(rangeEnd)) {
          return false;
        }
        if (entry.recurrenceUntil != null) {
          final until = DateTime(
            entry.recurrenceUntil!.year,
            entry.recurrenceUntil!.month,
            entry.recurrenceUntil!.day,
            23,
            59,
            59,
            999,
          );
          if (until.isBefore(rangeStart)) {
            return false;
          }
        }
        return true;
    }
  }

  bool _overlaps(
    DateTime startAt,
    DateTime endAt,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    return startAt.isBefore(rangeEnd) && endAt.isAfter(rangeStart);
  }

  bool _dateInRange(DateTime value, DateTime rangeStart, DateTime rangeEnd) {
    final normalized = DateTime(value.year, value.month, value.day);
    final normalizedStart = DateTime(
      rangeStart.year,
      rangeStart.month,
      rangeStart.day,
    );
    final normalizedEnd = DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day);
    return !normalized.isBefore(normalizedStart) &&
        normalized.isBefore(normalizedEnd);
  }
}
