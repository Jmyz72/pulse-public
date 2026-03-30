// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/exceptions.dart';
import 'package:pulse/features/timetable/data/datasources/timetable_remote_datasource.dart';
import 'package:pulse/features/timetable/data/models/timetable_entry_model.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late TimetableRemoteDataSourceImpl dataSource;
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockCollection;
  late MockQuery mockQuery;
  late MockDocumentReference mockDocRef;
  late MockQuerySnapshot mockQuerySnapshot;
  late MockDocumentSnapshot mockDocumentSnapshot;

  final tRangeStart = DateTime(2026, 3, 17);
  final tRangeEnd = DateTime(2026, 3, 24);

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockCollection = MockCollectionReference();
    mockQuery = MockQuery();
    mockDocRef = MockDocumentReference();
    mockQuerySnapshot = MockQuerySnapshot();
    mockDocumentSnapshot = MockDocumentSnapshot();
    dataSource = TimetableRemoteDataSourceImpl(firestore: mockFirestore);

    when(() => mockFirestore.collection(any())).thenReturn(mockCollection);
    when(
      () => mockCollection.where('userId', isEqualTo: 'user-123'),
    ).thenReturn(mockQuery);
    when(() => mockQuery.orderBy('startAt')).thenReturn(mockQuery);
  });

  test('getEntriesByUser returns range-relevant docs', () async {
    final inRangeDoc = MockQueryDocumentSnapshot();
    final outOfRangeDoc = MockQueryDocumentSnapshot();
    when(() => inRangeDoc.id).thenReturn('entry-1');
    when(() => outOfRangeDoc.id).thenReturn('entry-2');
    when(inRangeDoc.data).thenReturn({
      'userId': 'user-123',
      'startAt': Timestamp.fromDate(DateTime(2026, 3, 20, 9)),
      'endAt': Timestamp.fromDate(DateTime(2026, 3, 20, 10)),
      'title': 'Math',
      'createdAt': Timestamp.fromDate(DateTime(2026, 3, 1)),
      'entryType': 'single',
    });
    when(outOfRangeDoc.data).thenReturn({
      'userId': 'user-123',
      'startAt': Timestamp.fromDate(DateTime(2026, 4, 20, 9)),
      'endAt': Timestamp.fromDate(DateTime(2026, 4, 20, 10)),
      'title': 'History',
      'createdAt': Timestamp.fromDate(DateTime(2026, 3, 1)),
      'entryType': 'single',
    });
    when(() => mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
    when(() => mockQuerySnapshot.docs).thenReturn([inRangeDoc, outOfRangeDoc]);

    final result = await dataSource.getEntriesByUser(
      'user-123',
      tRangeStart,
      tRangeEnd,
    );

    expect(result.map((entry) => entry.id), ['entry-1']);
  });

  test('updateEntry returns refreshed server document', () async {
    when(() => mockCollection.doc('entry-1')).thenReturn(mockDocRef);
    when(() => mockDocRef.update(any())).thenAnswer((_) async {});
    when(() => mockDocRef.get()).thenAnswer((_) async => mockDocumentSnapshot);
    when(() => mockDocumentSnapshot.exists).thenReturn(true);
    when(() => mockDocumentSnapshot.id).thenReturn('entry-1');
    when(() => mockDocumentSnapshot.data()).thenReturn({
      'userId': 'user-123',
      'startAt': Timestamp.fromDate(DateTime(2026, 3, 20, 11)),
      'endAt': Timestamp.fromDate(DateTime(2026, 3, 20, 12)),
      'title': 'Updated',
      'createdAt': Timestamp.fromDate(DateTime(2026, 3, 1)),
      'entryType': 'single',
    });

    final result = await dataSource.updateEntry(
      TimetableEntryModel(
        id: 'entry-1',
        userId: 'user-123',
        startAt: DateTime(2026, 3, 20, 9),
        endAt: DateTime(2026, 3, 20, 10),
        title: 'Math',
        createdAt: DateTime(2026, 3, 1),
      ),
    );

    expect(result.title, 'Updated');
    verify(() => mockDocRef.update(any())).called(1);
  });

  test('getEntriesByUser wraps firestore errors', () {
    when(() => mockQuery.get()).thenThrow(Exception('boom'));

    expect(
      () => dataSource.getEntriesByUser('user-123', tRangeStart, tRangeEnd),
      throwsA(isA<ServerException>()),
    );
  });
}
