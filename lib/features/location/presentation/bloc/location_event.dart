part of 'location_bloc.dart';

abstract class LocationEvent extends Equatable {
  const LocationEvent();

  @override
  List<Object?> get props => [];
}

class LocationLoadRequested extends LocationEvent {
  final String userId;

  const LocationLoadRequested({required this.userId});

  @override
  List<Object> get props => [userId];
}

class LocationSharingToggled extends LocationEvent {
  final bool isSharing;

  const LocationSharingToggled({required this.isSharing});

  @override
  List<Object> get props => [isSharing];
}

class LocationPrivacyUpdated extends LocationEvent {
  final List<String> hiddenFromUserIds;

  const LocationPrivacyUpdated({required this.hiddenFromUserIds});

  @override
  List<Object> get props => [hiddenFromUserIds];
}

class LocationUpdated extends LocationEvent {
  final UserLocation location;

  const LocationUpdated({required this.location});

  @override
  List<Object> get props => [location];
}

class LocationStreamSubscriptionRequested extends LocationEvent {
  final String userId;

  const LocationStreamSubscriptionRequested({required this.userId});

  @override
  List<Object> get props => [userId];
}

class LocationFriendsUpdated extends LocationEvent {
  final List<UserLocation> locations;

  const LocationFriendsUpdated({required this.locations});

  @override
  List<Object> get props => [locations];
}

class LocationPresenceUpdated extends LocationEvent {
  final Map<String, bool> onlineUsers;

  const LocationPresenceUpdated({required this.onlineUsers});

  @override
  List<Object> get props => [onlineUsers];
}
