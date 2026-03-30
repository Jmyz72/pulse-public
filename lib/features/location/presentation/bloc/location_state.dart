part of 'location_bloc.dart';

enum LocationStatus { initial, loading, loaded, error }

class LocationState extends Equatable {
  static const _unset = Object();

  final LocationStatus status;
  final UserLocation? currentLocation;
  final List<UserLocation> friendsLocations;
  final NearbyFriendsSummary nearbyFriendsSummary;
  final bool isSharing;
  final List<String> hiddenFrom;
  final Map<String, bool> onlineUsers;
  final String? errorMessage;

  const LocationState({
    this.status = LocationStatus.initial,
    this.currentLocation,
    this.friendsLocations = const [],
    this.nearbyFriendsSummary = const NearbyFriendsSummary.unreliable(),
    this.isSharing = true,
    this.hiddenFrom = const [],
    this.onlineUsers = const {},
    this.errorMessage,
  });

  LocationState copyWith({
    LocationStatus? status,
    UserLocation? currentLocation,
    List<UserLocation>? friendsLocations,
    NearbyFriendsSummary? nearbyFriendsSummary,
    bool? isSharing,
    List<String>? hiddenFrom,
    Map<String, bool>? onlineUsers,
    Object? errorMessage = _unset,
  }) {
    return LocationState(
      status: status ?? this.status,
      currentLocation: currentLocation ?? this.currentLocation,
      friendsLocations: friendsLocations ?? this.friendsLocations,
      nearbyFriendsSummary: nearbyFriendsSummary ?? this.nearbyFriendsSummary,
      isSharing: isSharing ?? this.isSharing,
      hiddenFrom: hiddenFrom ?? this.hiddenFrom,
      onlineUsers: onlineUsers ?? this.onlineUsers,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    currentLocation,
    friendsLocations,
    nearbyFriendsSummary,
    isSharing,
    hiddenFrom,
    onlineUsers,
    errorMessage,
  ];
}
