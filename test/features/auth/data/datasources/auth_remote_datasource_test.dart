import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/constants/firestore_collections.dart';
import 'package:pulse/features/auth/data/datasources/auth_remote_datasource.dart';

class MockFirebaseAuth extends Mock implements firebase_auth.FirebaseAuth {}

class MockFirebaseUser extends Mock implements firebase_auth.User {}

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockFirebaseUser mockFirebaseUser;
  late AuthRemoteDataSourceImpl dataSource;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    mockFirebaseAuth = MockFirebaseAuth();
    mockFirebaseUser = MockFirebaseUser();

    when(() => mockFirebaseAuth.currentUser).thenReturn(mockFirebaseUser);
    when(() => mockFirebaseUser.uid).thenReturn('uid-123');

    dataSource = AuthRemoteDataSourceImpl(
      firebaseAuth: mockFirebaseAuth,
      firestore: firestore,
    );
  });

  group('updateProfile', () {
    test('writes canonical phone and phoneSearchDigits together', () async {
      await firestore
          .collection(FirestoreCollections.users)
          .doc('uid-123')
          .set({
            'userId': 'uid-123',
            'username': 'jimmy',
            'displayName': 'Jimmy Hew',
            'email': 'jimmy@test.com',
            'phone': '',
            'phoneSearchDigits': '',
          });

      final result = await dataSource.updateProfile(
        'Jimmy Hew',
        '+14155552671',
        null,
        'Venmo Jimmy',
      );

      final userDoc = await firestore
          .collection(FirestoreCollections.users)
          .doc('uid-123')
          .get();
      final phoneReservation = await firestore
          .collection(FirestoreCollections.phoneNumbers)
          .doc('+14155552671')
          .get();

      expect(result.phone, '+14155552671');
      expect(userDoc.data()?['phone'], '+14155552671');
      expect(userDoc.data()?['phoneSearchDigits'], '14155552671');
      expect(userDoc.data()?['paymentIdentity'], 'Venmo Jimmy');
      expect(phoneReservation.exists, isTrue);
      expect(phoneReservation.data()?['userId'], 'uid-123');
    });

    test(
      'clears reservation and search digits when phone is removed',
      () async {
        await firestore
            .collection(FirestoreCollections.users)
            .doc('uid-123')
            .set({
              'userId': 'uid-123',
              'username': 'jimmy',
              'displayName': 'Jimmy Hew',
              'email': 'jimmy@test.com',
              'phone': '+60123456789',
              'phoneSearchDigits': '60123456789',
            });
        await firestore
            .collection(FirestoreCollections.phoneNumbers)
            .doc('+60123456789')
            .set({
              'userId': 'uid-123',
              'createdAt': FieldValue.serverTimestamp(),
            });

        final result = await dataSource.updateProfile(
          'Jimmy Hew',
          '',
          null,
          null,
        );

        final userDoc = await firestore
            .collection(FirestoreCollections.users)
            .doc('uid-123')
            .get();
        final phoneReservation = await firestore
            .collection(FirestoreCollections.phoneNumbers)
            .doc('+60123456789')
            .get();

        expect(result.phone, '');
        expect(userDoc.data()?['phone'], '');
        expect(userDoc.data()?['phoneSearchDigits'], '');
        expect(phoneReservation.exists, isFalse);
      },
    );
  });
}
