import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_location_model.dart';

abstract class LocationRemoteDataSource {
  Future<UserLocationModel> getCurrentLocation(String userId, String userName);
  Future<void> updateLocation(UserLocationModel location);
  Future<List<UserLocationModel>> getFriendsLocations(String userId);
  Future<void> toggleLocationSharing(String userId, bool isSharing);
  Future<void> updateLocationPrivacy(String userId, List<String> hiddenFromUserIds);
  Stream<List<UserLocationModel>> watchFriendsLocations(String userId);
}

class LocationRemoteDataSourceImpl implements LocationRemoteDataSource {
  final FirebaseFirestore firestore;

  LocationRemoteDataSourceImpl({required this.firestore});

  @override
  Future<UserLocationModel> getCurrentLocation(String userId, String userName) async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw const ServerException(message: 'Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw const ServerException(message: 'Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw const ServerException(
            message: 'Location permissions are permanently denied');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final location = UserLocationModel(
        userId: userId,
        userName: userName,
        latitude: position.latitude,
        longitude: position.longitude,
        lastUpdated: DateTime.now(),
        isSharing: true,
      );

      await updateLocation(location);
      return location;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> updateLocation(UserLocationModel location) async {
    try {
      await firestore
          .collection(FirestoreCollections.userLocations)
          .doc(location.userId)
          .set(location.toJson());
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  Future<List<String>> _getFriendIds(String userId) async {
    // Query friendships where user is either userId or friendId with accepted status
    final asRequester = await firestore
        .collection(FirestoreCollections.friendships)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'accepted')
        .get();

    final asFriend = await firestore
        .collection(FirestoreCollections.friendships)
        .where('friendId', isEqualTo: userId)
        .where('status', isEqualTo: 'accepted')
        .get();

    final friendIds = <String>{};
    for (final doc in asRequester.docs) {
      friendIds.add(doc.data()['friendId'] as String);
    }
    for (final doc in asFriend.docs) {
      friendIds.add(doc.data()['userId'] as String);
    }

    return friendIds.toList();
  }

  @override
  Future<List<UserLocationModel>> getFriendsLocations(String userId) async {
    try {
      final friendIds = await _getFriendIds(userId);
      if (friendIds.isEmpty) return [];

      final locations = <UserLocationModel>[];

      // Firestore whereIn supports max 10 items per query
      for (var i = 0; i < friendIds.length; i += 10) {
        final batch = friendIds.sublist(
          i,
          i + 10 > friendIds.length ? friendIds.length : i + 10,
        );

        final snapshot = await firestore
            .collection(FirestoreCollections.userLocations)
            .where('userId', whereIn: batch)
            .where('isSharing', isEqualTo: true)
            .get();

        locations.addAll(
          snapshot.docs
              .map((doc) => UserLocationModel.fromJson(doc.data()))
              .where((loc) => !loc.hiddenFrom.contains(userId)),
        );
      }

      return locations;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> toggleLocationSharing(String userId, bool isSharing) async {
    try {
      await firestore
          .collection(FirestoreCollections.userLocations)
          .doc(userId)
          .update({'isSharing': isSharing});
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> updateLocationPrivacy(String userId, List<String> hiddenFromUserIds) async {
    try {
      await firestore
          .collection(FirestoreCollections.userLocations)
          .doc(userId)
          .update({'hiddenFrom': hiddenFromUserIds});
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Stream<List<UserLocationModel>> watchFriendsLocations(String userId) async* {
    final friendIds = await _getFriendIds(userId);
    if (friendIds.isEmpty) {
      yield [];
      return;
    }

    // For simplicity, watch the first batch (up to 10 friends)
    // For more friends, a more complex merging strategy would be needed
    final batch = friendIds.length > 10 ? friendIds.sublist(0, 10) : friendIds;

    yield* firestore
        .collection(FirestoreCollections.userLocations)
        .where('userId', whereIn: batch)
        .where('isSharing', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserLocationModel.fromJson(doc.data()))
            .where((loc) => !loc.hiddenFrom.contains(userId))
            .toList());
  }
}
