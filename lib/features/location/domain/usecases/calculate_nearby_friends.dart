import 'dart:math' as math;

import '../entities/location.dart';
import '../entities/nearby_friends_summary.dart';

class CalculateNearbyFriends {
  static const _radiusInMeters = 5000.0;
  static const _freshnessThreshold = Duration(hours: 2);
  static const _earthRadiusInMeters = 6371000.0;

  final DateTime Function() _now;

  CalculateNearbyFriends({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  NearbyFriendsSummary call({
    required UserLocation? currentLocation,
    required List<UserLocation> friendsLocations,
  }) {
    if (currentLocation == null || !_isFresh(currentLocation.lastUpdated)) {
      return const NearbyFriendsSummary.unreliable();
    }

    final freshFriends = friendsLocations
        .where((friend) => _isFresh(friend.lastUpdated))
        .toList(growable: false);

    if (freshFriends.isEmpty) {
      return const NearbyFriendsSummary.unreliable();
    }

    final nearbyCount = freshFriends.where((friend) {
      final distanceInMeters = _distanceInMeters(
        startLatitude: currentLocation.latitude,
        startLongitude: currentLocation.longitude,
        endLatitude: friend.latitude,
        endLongitude: friend.longitude,
      );
      return distanceInMeters <= _radiusInMeters;
    }).length;

    return NearbyFriendsSummary(count: nearbyCount, isReliable: true);
  }

  bool _isFresh(DateTime lastUpdated) {
    return _now().difference(lastUpdated) <= _freshnessThreshold;
  }

  double _distanceInMeters({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    final latitudeDelta = _toRadians(endLatitude - startLatitude);
    final longitudeDelta = _toRadians(endLongitude - startLongitude);
    final startLatitudeRadians = _toRadians(startLatitude);
    final endLatitudeRadians = _toRadians(endLatitude);

    final a =
        math.pow(math.sin(latitudeDelta / 2), 2) +
        math.cos(startLatitudeRadians) *
            math.cos(endLatitudeRadians) *
            math.pow(math.sin(longitudeDelta / 2), 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return _earthRadiusInMeters * c;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180);
}
