import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/location/domain/entities/location.dart';
import 'package:pulse/features/location/domain/usecases/calculate_nearby_friends.dart';

void main() {
  final fixedNow = DateTime(2024, 1, 15, 12, 0);
  late CalculateNearbyFriends usecase;

  final currentLocation = UserLocation(
    userId: 'user-1',
    userName: 'Jimmy',
    latitude: 3.1390,
    longitude: 101.6869,
    lastUpdated: fixedNow.subtract(const Duration(minutes: 15)),
  );

  final nearbyFriend = UserLocation(
    userId: 'friend-1',
    userName: 'Alice',
    latitude: 3.1450,
    longitude: 101.6900,
    lastUpdated: fixedNow.subtract(const Duration(minutes: 20)),
  );

  final farFriend = UserLocation(
    userId: 'friend-2',
    userName: 'Bob',
    latitude: 3.3000,
    longitude: 101.9000,
    lastUpdated: fixedNow.subtract(const Duration(minutes: 25)),
  );

  final staleFriend = UserLocation(
    userId: 'friend-3',
    userName: 'Carol',
    latitude: 3.1400,
    longitude: 101.6880,
    lastUpdated: fixedNow.subtract(const Duration(hours: 3)),
  );

  setUp(() {
    usecase = CalculateNearbyFriends(now: () => fixedNow);
  });

  test('counts a nearby friend updated within two hours', () {
    final result = usecase(
      currentLocation: currentLocation,
      friendsLocations: [nearbyFriend],
    );

    expect(result.isReliable, isTrue);
    expect(result.count, 1);
  });

  test('excludes a friend farther than five kilometers', () {
    final result = usecase(
      currentLocation: currentLocation,
      friendsLocations: [farFriend],
    );

    expect(result.isReliable, isTrue);
    expect(result.count, 0);
  });

  test('excludes a friend with stale location older than two hours', () {
    final result = usecase(
      currentLocation: currentLocation,
      friendsLocations: [staleFriend],
    );

    expect(result.isReliable, isFalse);
    expect(result.count, 0);
  });

  test('returns unreliable when current user location is missing', () {
    final result = usecase(
      currentLocation: null,
      friendsLocations: [nearbyFriend],
    );

    expect(result.isReliable, isFalse);
    expect(result.count, 0);
  });

  test('returns unreliable when current user location is stale', () {
    final staleCurrentLocation = UserLocation(
      userId: 'user-1',
      userName: 'Jimmy',
      latitude: 3.1390,
      longitude: 101.6869,
      lastUpdated: fixedNow.subtract(const Duration(hours: 3)),
    );

    final result = usecase(
      currentLocation: staleCurrentLocation,
      friendsLocations: [nearbyFriend],
    );

    expect(result.isReliable, isFalse);
    expect(result.count, 0);
  });

  test(
    'returns reliable zero when fresh friend locations exist but none are nearby',
    () {
      final result = usecase(
        currentLocation: currentLocation,
        friendsLocations: [farFriend],
      );

      expect(result.isReliable, isTrue);
      expect(result.count, 0);
    },
  );

  test('returns unreliable when all friend locations are stale', () {
    final result = usecase(
      currentLocation: currentLocation,
      friendsLocations: [staleFriend],
    );

    expect(result.isReliable, isFalse);
    expect(result.count, 0);
  });
}
