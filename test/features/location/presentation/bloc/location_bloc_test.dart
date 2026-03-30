import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/core/usecases/usecase.dart';
import 'package:pulse/features/location/domain/entities/location.dart';
import 'package:pulse/features/location/domain/entities/nearby_friends_summary.dart';
import 'package:pulse/features/location/domain/usecases/calculate_nearby_friends.dart';
import 'package:pulse/features/location/domain/usecases/get_current_location.dart';
import 'package:pulse/features/location/domain/usecases/get_friends_locations.dart';
import 'package:pulse/features/location/domain/usecases/toggle_location_sharing.dart';
import 'package:pulse/features/location/domain/usecases/update_location.dart';
import 'package:pulse/features/location/domain/usecases/update_location_privacy.dart';
import 'package:pulse/features/location/domain/usecases/watch_friends_locations.dart';
import 'package:pulse/features/chat/domain/usecases/watch_user_presence.dart';
import 'package:pulse/features/location/presentation/bloc/location_bloc.dart';

class MockGetCurrentLocation extends Mock implements GetCurrentLocation {}

class MockGetFriendsLocations extends Mock implements GetFriendsLocations {}

class MockToggleLocationSharing extends Mock implements ToggleLocationSharing {}

class MockUpdateLocation extends Mock implements UpdateLocation {}

class MockWatchFriendsLocations extends Mock implements WatchFriendsLocations {}

class MockUpdateLocationPrivacy extends Mock implements UpdateLocationPrivacy {}

class MockWatchUserPresence extends Mock implements WatchUserPresence {}

void main() {
  late LocationBloc bloc;
  late MockGetCurrentLocation mockGetCurrentLocation;
  late MockGetFriendsLocations mockGetFriendsLocations;
  late MockToggleLocationSharing mockToggleLocationSharing;
  late MockUpdateLocation mockUpdateLocation;
  late MockWatchFriendsLocations mockWatchFriendsLocations;
  late MockUpdateLocationPrivacy mockUpdateLocationPrivacy;
  late MockWatchUserPresence mockWatchUserPresence;
  late CalculateNearbyFriends calculateNearbyFriends;

  setUp(() {
    mockGetCurrentLocation = MockGetCurrentLocation();
    mockGetFriendsLocations = MockGetFriendsLocations();
    mockToggleLocationSharing = MockToggleLocationSharing();
    mockUpdateLocation = MockUpdateLocation();
    mockWatchFriendsLocations = MockWatchFriendsLocations();
    mockUpdateLocationPrivacy = MockUpdateLocationPrivacy();
    mockWatchUserPresence = MockWatchUserPresence();
    calculateNearbyFriends = CalculateNearbyFriends(
      now: () => DateTime(2024, 1, 15, 11, 0),
    );

    when(
      () => mockWatchFriendsLocations(any()),
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => mockWatchUserPresence(any()),
    ).thenAnswer((_) => const Stream.empty());

    bloc = LocationBloc(
      getCurrentLocation: mockGetCurrentLocation,
      getFriendsLocations: mockGetFriendsLocations,
      calculateNearbyFriends: calculateNearbyFriends,
      toggleLocationSharing: mockToggleLocationSharing,
      updateLocation: mockUpdateLocation,
      updateLocationPrivacy: mockUpdateLocationPrivacy,
      watchFriendsLocations: mockWatchFriendsLocations,
      watchUserPresence: mockWatchUserPresence,
    );
  });

  tearDown(() {
    bloc.close();
  });

  final tCurrentLocation = UserLocation(
    userId: 'user-1',
    userName: 'Test User',
    latitude: 3.1390,
    longitude: 101.6869,
    lastUpdated: DateTime(2024, 1, 15, 10, 30),
    isSharing: true,
  );

  final tFriendLocation1 = UserLocation(
    userId: 'friend-1',
    userName: 'Alice',
    latitude: 3.1400,
    longitude: 101.6900,
    lastUpdated: DateTime(2024, 1, 15, 10, 30),
    isSharing: true,
  );

  final tFriendLocation2 = UserLocation(
    userId: 'friend-2',
    userName: 'Bob',
    latitude: 3.1350,
    longitude: 101.6800,
    lastUpdated: DateTime(2024, 1, 15, 10, 25),
    isSharing: true,
  );

  final tFriendsLocations = [tFriendLocation1, tFriendLocation2];

  final tUpdatedLocation = UserLocation(
    userId: 'user-1',
    userName: 'Test User',
    latitude: 3.1500,
    longitude: 101.7000,
    lastUpdated: DateTime(2024, 1, 15, 11, 00),
    isSharing: true,
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const ToggleLocationSharingParams(isSharing: true));
    registerFallbackValue(UpdateLocationParams(location: tCurrentLocation));
    registerFallbackValue(const GetFriendsLocationsParams(userId: 'user-1'));
  });

  group('LocationLoadRequested', () {
    blocTest<LocationBloc, LocationState>(
      'emits [loading, loaded] when GetCurrentLocation succeeds',
      build: () {
        when(
          () => mockGetCurrentLocation(any()),
        ).thenAnswer((_) async => Right(tCurrentLocation));
        when(
          () => mockGetFriendsLocations(any()),
        ).thenAnswer((_) async => Right(tFriendsLocations));
        return bloc;
      },
      act: (bloc) => bloc.add(const LocationLoadRequested(userId: 'user-1')),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        const LocationState(status: LocationStatus.loading),
        LocationState(
          status: LocationStatus.loaded,
          currentLocation: tCurrentLocation,
          nearbyFriendsSummary: const NearbyFriendsSummary.unreliable(),
        ),
        LocationState(
          status: LocationStatus.loaded,
          currentLocation: tCurrentLocation,
          friendsLocations: tFriendsLocations,
          nearbyFriendsSummary: const NearbyFriendsSummary(
            count: 2,
            isReliable: true,
          ),
        ),
      ],
      verify: (_) {
        verify(() => mockGetCurrentLocation(any())).called(1);
        verify(() => mockGetFriendsLocations(any())).called(1);
      },
    );

    blocTest<LocationBloc, LocationState>(
      'emits [loading, loaded with error] and still loads friends when GetCurrentLocation fails',
      build: () {
        when(() => mockGetCurrentLocation(any())).thenAnswer(
          (_) async => const Left(
            ServerFailure(message: 'Location service unavailable'),
          ),
        );
        when(
          () => mockGetFriendsLocations(any()),
        ).thenAnswer((_) async => Right(tFriendsLocations));
        return bloc;
      },
      act: (bloc) => bloc.add(const LocationLoadRequested(userId: 'user-1')),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        const LocationState(status: LocationStatus.loading),
        const LocationState(
          status: LocationStatus.loaded,
          errorMessage: 'Location service unavailable',
        ),
        LocationState(
          status: LocationStatus.loaded,
          friendsLocations: tFriendsLocations,
          errorMessage: 'Location service unavailable',
        ),
      ],
      verify: (_) {
        verify(() => mockGetCurrentLocation(any())).called(1);
        verify(() => mockGetFriendsLocations(any())).called(1);
      },
    );
  });

  group('LocationSharingToggled', () {
    blocTest<LocationBloc, LocationState>(
      'emits state with isSharing: true when enabling location sharing succeeds',
      build: () {
        when(
          () => mockToggleLocationSharing(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      seed: () =>
          const LocationState(status: LocationStatus.loaded, isSharing: false),
      act: (bloc) => bloc.add(const LocationSharingToggled(isSharing: true)),
      expect: () => [
        const LocationState(status: LocationStatus.loaded, isSharing: true),
      ],
      verify: (_) {
        verify(() => mockToggleLocationSharing(any())).called(1);
      },
    );

    blocTest<LocationBloc, LocationState>(
      'emits error state when ToggleLocationSharing fails',
      build: () {
        when(() => mockToggleLocationSharing(any())).thenAnswer(
          (_) async =>
              const Left(ServerFailure(message: 'Failed to toggle sharing')),
        );
        return bloc;
      },
      seed: () =>
          const LocationState(status: LocationStatus.loaded, isSharing: true),
      act: (bloc) => bloc.add(const LocationSharingToggled(isSharing: false)),
      expect: () => [
        const LocationState(
          status: LocationStatus.error,
          isSharing: true,
          errorMessage: 'Failed to toggle sharing',
        ),
      ],
    );
  });

  group('LocationUpdated', () {
    blocTest<LocationBloc, LocationState>(
      'emits state with updated location when UpdateLocation succeeds',
      build: () {
        when(
          () => mockUpdateLocation(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      seed: () => LocationState(
        status: LocationStatus.loaded,
        currentLocation: tCurrentLocation,
        friendsLocations: tFriendsLocations,
        nearbyFriendsSummary: const NearbyFriendsSummary(
          count: 2,
          isReliable: true,
        ),
      ),
      act: (bloc) => bloc.add(LocationUpdated(location: tUpdatedLocation)),
      expect: () => [
        LocationState(
          status: LocationStatus.loaded,
          currentLocation: tUpdatedLocation,
          friendsLocations: tFriendsLocations,
          nearbyFriendsSummary: const NearbyFriendsSummary(
            count: 2,
            isReliable: true,
          ),
        ),
      ],
      verify: (_) {
        verify(() => mockUpdateLocation(any())).called(1);
      },
    );

    blocTest<LocationBloc, LocationState>(
      'emits error state when UpdateLocation fails',
      build: () {
        when(() => mockUpdateLocation(any())).thenAnswer(
          (_) async =>
              const Left(ServerFailure(message: 'Failed to update location')),
        );
        return bloc;
      },
      seed: () => LocationState(
        status: LocationStatus.loaded,
        currentLocation: tCurrentLocation,
      ),
      act: (bloc) => bloc.add(LocationUpdated(location: tUpdatedLocation)),
      expect: () => [
        LocationState(
          status: LocationStatus.error,
          currentLocation: tCurrentLocation,
          errorMessage: 'Failed to update location',
        ),
      ],
    );
  });

  group('LocationFriendsUpdated', () {
    blocTest<LocationBloc, LocationState>(
      'recomputes nearby summary when friends locations stream updates',
      build: () => bloc,
      seed: () => LocationState(
        status: LocationStatus.loaded,
        currentLocation: tCurrentLocation,
      ),
      act: (bloc) =>
          bloc.add(LocationFriendsUpdated(locations: tFriendsLocations)),
      expect: () => [
        LocationState(
          status: LocationStatus.loaded,
          currentLocation: tCurrentLocation,
          friendsLocations: tFriendsLocations,
          nearbyFriendsSummary: const NearbyFriendsSummary(
            count: 2,
            isReliable: true,
          ),
        ),
      ],
    );
  });

  group('Initial state', () {
    test('should have initial state', () {
      expect(bloc.state, const LocationState());
      expect(bloc.state.status, LocationStatus.initial);
      expect(bloc.state.currentLocation, null);
      expect(bloc.state.friendsLocations, const []);
      expect(
        bloc.state.nearbyFriendsSummary,
        const NearbyFriendsSummary.unreliable(),
      );
      expect(bloc.state.isSharing, true);
      expect(bloc.state.errorMessage, null);
    });
  });

  group('Event props', () {
    test('LocationLoadRequested should have correct props', () {
      const event = LocationLoadRequested(userId: 'user-1');
      expect(event.props, ['user-1']);
    });

    test('LocationSharingToggled should have correct props', () {
      const event = LocationSharingToggled(isSharing: true);
      expect(event.props, [true]);
    });

    test('LocationUpdated should have correct props', () {
      final event = LocationUpdated(location: tCurrentLocation);
      expect(event.props, [tCurrentLocation]);
    });

    test('LocationStreamSubscriptionRequested should have correct props', () {
      const event = LocationStreamSubscriptionRequested(userId: 'user-1');
      expect(event.props, ['user-1']);
    });
  });
}
