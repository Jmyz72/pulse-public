import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/location.dart';
import '../../domain/entities/nearby_friends_summary.dart';
import '../../domain/usecases/calculate_nearby_friends.dart';
import '../../domain/usecases/get_current_location.dart';
import '../../domain/usecases/get_friends_locations.dart';
import '../../domain/usecases/toggle_location_sharing.dart';
import '../../domain/usecases/update_location.dart';
import '../../domain/usecases/update_location_privacy.dart';
import '../../domain/usecases/watch_friends_locations.dart';
import '../../../chat/domain/usecases/watch_user_presence.dart';

part 'location_event.dart';
part 'location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final GetCurrentLocation getCurrentLocation;
  final GetFriendsLocations getFriendsLocations;
  final CalculateNearbyFriends calculateNearbyFriends;
  final ToggleLocationSharing toggleLocationSharing;
  final UpdateLocation updateLocation;
  final UpdateLocationPrivacy updateLocationPrivacy;
  final WatchFriendsLocations watchFriendsLocations;
  final WatchUserPresence watchUserPresence;

  StreamSubscription<List<UserLocation>>? _friendsLocationSubscription;
  StreamSubscription<Map<String, bool>>? _presenceSubscription;

  LocationBloc({
    required this.getCurrentLocation,
    required this.getFriendsLocations,
    required this.calculateNearbyFriends,
    required this.toggleLocationSharing,
    required this.updateLocation,
    required this.updateLocationPrivacy,
    required this.watchFriendsLocations,
    required this.watchUserPresence,
  }) : super(const LocationState()) {
    on<LocationLoadRequested>(_onLoadRequested);
    on<LocationSharingToggled>(_onSharingToggled);
    on<LocationPrivacyUpdated>(_onPrivacyUpdated);
    on<LocationUpdated>(_onLocationUpdated);
    on<LocationStreamSubscriptionRequested>(_onStreamSubscriptionRequested);
    on<LocationFriendsUpdated>(_onFriendsUpdated);
    on<LocationPresenceUpdated>(_onPresenceUpdated);
  }

  Future<void> _onLoadRequested(
    LocationLoadRequested event,
    Emitter<LocationState> emit,
  ) async {
    emit(state.copyWith(status: LocationStatus.loading));

    // Try to get current location (may fail if permissions denied)
    final currentResult = await getCurrentLocation(const NoParams());

    currentResult.fold(
      (failure) {
        // Emit loaded (not error) so friends still display
        _emitWithNearbySummary(
          emit,
          state.copyWith(
            status: LocationStatus.loaded,
            errorMessage: failure.message,
          ),
        );
      },
      (location) {
        _emitWithNearbySummary(
          emit,
          state.copyWith(
            status: LocationStatus.loaded,
            currentLocation: location,
            isSharing: location.isSharing,
            hiddenFrom: location.hiddenFrom,
            errorMessage: null,
          ),
        );
      },
    );

    // Always load friends using the provided userId, regardless of geolocator result
    add(LocationStreamSubscriptionRequested(userId: event.userId));

    final friendsResult = await getFriendsLocations(
      GetFriendsLocationsParams(userId: event.userId),
    );
    friendsResult.fold(
      (_) {},
      (friends) => _emitWithNearbySummary(
        emit,
        state.copyWith(friendsLocations: friends),
      ),
    );
  }

  Future<void> _onSharingToggled(
    LocationSharingToggled event,
    Emitter<LocationState> emit,
  ) async {
    final result = await toggleLocationSharing(
      ToggleLocationSharingParams(isSharing: event.isSharing),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: LocationStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (_) =>
          emit(state.copyWith(isSharing: event.isSharing, errorMessage: null)),
    );
  }

  Future<void> _onPrivacyUpdated(
    LocationPrivacyUpdated event,
    Emitter<LocationState> emit,
  ) async {
    final result = await updateLocationPrivacy(
      UpdateLocationPrivacyParams(hiddenFromUserIds: event.hiddenFromUserIds),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: LocationStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(
        state.copyWith(hiddenFrom: event.hiddenFromUserIds, errorMessage: null),
      ),
    );
  }

  Future<void> _onLocationUpdated(
    LocationUpdated event,
    Emitter<LocationState> emit,
  ) async {
    final result = await updateLocation(
      UpdateLocationParams(location: event.location),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: LocationStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (_) => _emitWithNearbySummary(
        emit,
        state.copyWith(
          currentLocation: event.location,
          status: LocationStatus.loaded,
          errorMessage: null,
        ),
      ),
    );
  }

  Future<void> _onStreamSubscriptionRequested(
    LocationStreamSubscriptionRequested event,
    Emitter<LocationState> emit,
  ) async {
    await _friendsLocationSubscription?.cancel();
    _friendsLocationSubscription = watchFriendsLocations(event.userId).listen((
      locations,
    ) {
      add(LocationFriendsUpdated(locations: locations));
    });
  }

  void _onFriendsUpdated(
    LocationFriendsUpdated event,
    Emitter<LocationState> emit,
  ) {
    _emitWithNearbySummary(
      emit,
      state.copyWith(
        status: LocationStatus.loaded,
        friendsLocations: event.locations,
      ),
    );

    // Update presence subscription for new list of friends
    _presenceSubscription?.cancel();
    if (event.locations.isNotEmpty) {
      final friendIds = event.locations.map((l) => l.userId).toList();
      _presenceSubscription = watchUserPresence(friendIds).listen((
        onlineUsers,
      ) {
        add(LocationPresenceUpdated(onlineUsers: onlineUsers));
      });
    }
  }

  void _onPresenceUpdated(
    LocationPresenceUpdated event,
    Emitter<LocationState> emit,
  ) {
    emit(state.copyWith(onlineUsers: event.onlineUsers));
  }

  void _emitWithNearbySummary(
    Emitter<LocationState> emit,
    LocationState nextState,
  ) {
    emit(
      nextState.copyWith(
        nearbyFriendsSummary: _calculateNearbySummary(
          currentLocation: nextState.currentLocation,
          friendsLocations: nextState.friendsLocations,
        ),
      ),
    );
  }

  NearbyFriendsSummary _calculateNearbySummary({
    required UserLocation? currentLocation,
    required List<UserLocation> friendsLocations,
  }) {
    return calculateNearbyFriends(
      currentLocation: currentLocation,
      friendsLocations: friendsLocations,
    );
  }

  @override
  Future<void> close() {
    _friendsLocationSubscription?.cancel();
    _presenceSubscription?.cancel();
    return super.close();
  }
}
