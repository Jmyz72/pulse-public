import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/constants/firestore_collections.dart';
import 'package:pulse/features/friends/data/datasources/friend_remote_datasource.dart';
import 'package:pulse/features/friends/domain/entities/friendship.dart';

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseFunctions mockFunctions;
  late FriendRemoteDataSourceImpl dataSource;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    mockFunctions = MockFirebaseFunctions();
    dataSource = FriendRemoteDataSourceImpl(
      firestore: firestore,
      functions: mockFunctions,
    );
  });

  Future<void> seedUser({
    required String userId,
    required String username,
    required String email,
    required String phone,
    required String phoneSearchDigits,
    bool searchableByPhone = true,
  }) async {
    await firestore.collection(FirestoreCollections.users).doc(userId).set({
      'userId': userId,
      'username': username,
      'displayName': username,
      'email': email,
      'phone': phone,
      'phoneSearchDigits': phoneSearchDigits,
    });
    await firestore
        .collection(FirestoreCollections.userSearchSettings)
        .doc(userId)
        .set({
          'searchableByPhone': searchableByPhone,
          'searchableByUsername': true,
          'searchableByEmail': true,
        });
  }

  group('searchUsers', () {
    test('matches phone queries against phoneSearchDigits', () async {
      await seedUser(
        userId: 'user-1',
        username: 'jimmy',
        email: 'jimmy@test.com',
        phone: '+14155552671',
        phoneSearchDigits: '14155552671',
      );

      final digitsOnly = await dataSource.searchUsers('141555');
      final formatted = await dataSource.searchUsers('+1 (415) 555');

      expect(digitsOnly.map((user) => user.id), contains('user-1'));
      expect(formatted.map((user) => user.id), contains('user-1'));
    });

    test(
      'keeps username search unchanged and respects phone privacy',
      () async {
        await seedUser(
          userId: 'user-1',
          username: 'johnny',
          email: 'johnny@test.com',
          phone: '+60123456789',
          phoneSearchDigits: '60123456789',
          searchableByPhone: false,
        );

        final usernameResults = await dataSource.searchUsers('john');
        final phoneResults = await dataSource.searchUsers('601234');

        expect(usernameResults.map((user) => user.id), contains('user-1'));
        expect(phoneResults, isEmpty);
      },
    );
  });

  group('getSentRequests', () {
    test('returns only outgoing pending friendships for the user', () async {
      await firestore
          .collection(FirestoreCollections.friendships)
          .doc('sent-1')
          .set({
            'userId': 'user-1',
            'friendId': 'friend-1',
            'friendUsername': 'friend1',
            'friendDisplayName': 'Friend One',
            'friendEmail': 'friend1@test.com',
            'friendPhone': '+1234567890',
            'requesterUsername': 'user1',
            'requesterDisplayName': 'User One',
            'requesterEmail': 'user1@test.com',
            'requesterPhone': '+0987654321',
            'status': 'pending',
          });
      await firestore
          .collection(FirestoreCollections.friendships)
          .doc('accepted-1')
          .set({
            'userId': 'user-1',
            'friendId': 'friend-2',
            'friendUsername': 'friend2',
            'friendDisplayName': 'Friend Two',
            'friendEmail': 'friend2@test.com',
            'friendPhone': '+1234567891',
            'requesterUsername': 'user1',
            'requesterDisplayName': 'User One',
            'requesterEmail': 'user1@test.com',
            'requesterPhone': '+0987654321',
            'status': 'accepted',
          });
      await firestore
          .collection(FirestoreCollections.friendships)
          .doc('incoming-1')
          .set({
            'userId': 'friend-3',
            'friendId': 'user-1',
            'friendUsername': 'user1',
            'friendDisplayName': 'User One',
            'friendEmail': 'user1@test.com',
            'friendPhone': '+0987654321',
            'requesterUsername': 'friend3',
            'requesterDisplayName': 'Friend Three',
            'requesterEmail': 'friend3@test.com',
            'requesterPhone': '+1234567892',
            'status': 'pending',
          });

      final results = await dataSource.getSentRequests('user-1');

      expect(results.map((request) => request.id), ['sent-1']);
      expect(results.first.friendId, 'friend-1');
      expect(results.first.status, FriendshipStatus.pending);
    });
  });
}
