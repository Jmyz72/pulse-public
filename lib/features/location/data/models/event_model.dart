import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/event.dart';

class EventModel extends Event {
  const EventModel({
    required super.id,
    required super.title,
    super.description,
    super.category,
    super.maxCapacity,
    required super.latitude,
    required super.longitude,
    required super.eventDate,
    required super.eventTime,
    required super.creatorId,
    required super.creatorName,
    super.attendeeIds,
    super.attendeeNames,
    required super.createdAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      category: json['category'] ?? 'other',
      maxCapacity: json['maxCapacity'],
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      eventDate: json['eventDate'] != null
          ? (json['eventDate'] is Timestamp
              ? (json['eventDate'] as Timestamp).toDate()
              : DateTime.parse(json['eventDate']))
          : DateTime.now(),
      eventTime: json['eventTime'] ?? '',
      creatorId: json['creatorId'] ?? '',
      creatorName: json['creatorName'] ?? '',
      attendeeIds: List<String>.from(json['attendeeIds'] ?? []),
      attendeeNames: List<String>.from(json['attendeeNames'] ?? []),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is Timestamp
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.parse(json['createdAt']))
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'maxCapacity': maxCapacity,
      'latitude': latitude,
      'longitude': longitude,
      'eventDate': Timestamp.fromDate(eventDate),
      'eventTime': eventTime,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'attendeeIds': attendeeIds,
      'attendeeNames': attendeeNames,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory EventModel.fromEntity(Event event) {
    return EventModel(
      id: event.id,
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
      attendeeIds: event.attendeeIds,
      attendeeNames: event.attendeeNames,
      createdAt: event.createdAt,
    );
  }
}
