import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/error/exceptions.dart';
import '../models/event_model.dart';

abstract class EventRemoteDataSource {
  Future<EventModel> createEvent(EventModel event);
  Stream<List<EventModel>> watchEvents(String userId);
  Future<void> joinEvent(String eventId, String userId, String userName);
  Future<void> leaveEvent(String eventId, String userId);
  Future<void> deleteEvent(String eventId);
}

class EventRemoteDataSourceImpl implements EventRemoteDataSource {
  final FirebaseFirestore firestore;

  EventRemoteDataSourceImpl({required this.firestore});

  @override
  Future<EventModel> createEvent(EventModel event) async {
    try {
      final docRef = firestore.collection(FirestoreCollections.events).doc();
      final eventWithId = EventModel(
        id: docRef.id,
        title: event.title,
        description: event.description,
        category: event.category,
        maxCapacity: event.maxCapacity,
        latitude: event.latitude,
        longitude: event.longitude,
        eventDate: event.eventDate,
        eventTime: event.eventTime,
        creatorId: event.creatorId,
        creatorName: event.creatorName,
        attendeeIds: [event.creatorId],
        attendeeNames: [event.creatorName],
        createdAt: DateTime.now(),
      );

      await docRef.set(eventWithId.toJson());
      return eventWithId;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Stream<List<EventModel>> watchEvents(String userId) {
    return firestore
        .collection(FirestoreCollections.events)
        .where('attendeeIds', arrayContains: userId)
        .orderBy('eventDate', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => EventModel.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  @override
  Future<void> joinEvent(String eventId, String userId, String userName) async {
    try {
      await firestore
          .collection(FirestoreCollections.events)
          .doc(eventId)
          .update({
            'attendeeIds': FieldValue.arrayUnion([userId]),
            'attendeeNames': FieldValue.arrayUnion([userName]),
          });
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> leaveEvent(String eventId, String userId) async {
    try {
      // Get current event to find the user's name
      final doc = await firestore
          .collection(FirestoreCollections.events)
          .doc(eventId)
          .get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final attendeeIds = List<String>.from(data['attendeeIds'] ?? []);
      final attendeeNames = List<String>.from(data['attendeeNames'] ?? []);

      final index = attendeeIds.indexOf(userId);
      if (index != -1) {
        attendeeIds.removeAt(index);
        if (index < attendeeNames.length) {
          attendeeNames.removeAt(index);
        }

        await firestore
            .collection(FirestoreCollections.events)
            .doc(eventId)
            .update({
              'attendeeIds': attendeeIds,
              'attendeeNames': attendeeNames,
            });
      }
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    try {
      await firestore
          .collection(FirestoreCollections.events)
          .doc(eventId)
          .delete();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
