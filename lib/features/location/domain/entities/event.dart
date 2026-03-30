import 'package:equatable/equatable.dart';

class Event extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String category;
  final int? maxCapacity;
  final double latitude;
  final double longitude;
  final DateTime eventDate;
  final String eventTime;
  final String creatorId;
  final String creatorName;
  final List<String> attendeeIds;
  final List<String> attendeeNames;
  final DateTime createdAt;

  const Event({
    required this.id,
    required this.title,
    this.description,
    this.category = 'other',
    this.maxCapacity,
    required this.latitude,
    required this.longitude,
    required this.eventDate,
    required this.eventTime,
    required this.creatorId,
    required this.creatorName,
    this.attendeeIds = const [],
    this.attendeeNames = const [],
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        maxCapacity,
        latitude,
        longitude,
        eventDate,
        eventTime,
        creatorId,
        creatorName,
        attendeeIds,
        attendeeNames,
        createdAt,
      ];
}
