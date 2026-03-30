import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/chat/data/models/message_model.dart';

void main() {
  group('ChatRoomModel', () {
    final tCreatedAt = DateTime(2024, 1, 1, 10, 0);

    group('fromJson', () {
      test('should parse createdBy and admins from JSON', () {
        // arrange
        final json = {
          'id': 'room-1',
          'name': 'Test Group',
          'members': ['user-1', 'user-2', 'user-3'],
          'createdAt': tCreatedAt.toIso8601String(),
          'isGroup': true,
          'createdBy': 'user-1',
          'admins': ['user-1', 'user-2'],
        };

        // act
        final result = ChatRoomModel.fromJson(json);

        // assert
        expect(result.id, 'room-1');
        expect(result.name, 'Test Group');
        expect(result.members, ['user-1', 'user-2', 'user-3']);
        expect(result.isGroup, true);
        expect(result.createdBy, 'user-1');
        expect(result.admins, ['user-1', 'user-2']);
      });

      test('should handle missing createdBy (null)', () {
        // arrange
        final json = {
          'id': 'room-1',
          'name': 'Test Group',
          'members': ['user-1', 'user-2'],
          'createdAt': tCreatedAt.toIso8601String(),
          'isGroup': true,
          // createdBy is missing
          'admins': ['user-1'],
        };

        // act
        final result = ChatRoomModel.fromJson(json);

        // assert
        expect(result.createdBy, isNull);
      });

      test('should handle missing admins (empty list)', () {
        // arrange
        final json = {
          'id': 'room-1',
          'name': 'Test Group',
          'members': ['user-1', 'user-2'],
          'createdAt': tCreatedAt.toIso8601String(),
          'isGroup': true,
          'createdBy': 'user-1',
          // admins is missing
        };

        // act
        final result = ChatRoomModel.fromJson(json);

        // assert
        expect(result.admins, isEmpty);
      });

      test('should handle null admins field', () {
        // arrange
        final json = {
          'id': 'room-1',
          'name': 'Test Group',
          'members': ['user-1', 'user-2'],
          'createdAt': tCreatedAt.toIso8601String(),
          'isGroup': true,
          'createdBy': 'user-1',
          'admins': null,
        };

        // act
        final result = ChatRoomModel.fromJson(json);

        // assert
        expect(result.admins, isEmpty);
      });

      test('should handle legacy chat rooms without admin fields', () {
        // arrange (simulating an old chat room without createdBy and admins)
        final json = {
          'id': 'room-1',
          'name': 'Legacy Group',
          'members': ['user-1', 'user-2'],
          'createdAt': tCreatedAt.toIso8601String(),
          'isGroup': true,
        };

        // act
        final result = ChatRoomModel.fromJson(json);

        // assert
        expect(result.createdBy, isNull);
        expect(result.admins, isEmpty);
        // Backward compatibility: first member should be treated as admin
        expect(result.isAdmin('user-1'), true);
        expect(result.isAdmin('user-2'), false);
      });

      test('should parse Timestamp for createdAt', () {
        // arrange
        final timestamp = Timestamp.fromDate(tCreatedAt);
        final json = {
          'id': 'room-1',
          'name': 'Test Group',
          'members': ['user-1'],
          'createdAt': timestamp,
          'isGroup': true,
          'admins': ['user-1'],
        };

        // act
        final result = ChatRoomModel.fromJson(json);

        // assert
        expect(result.createdAt, tCreatedAt);
      });
    });

    group('toJson', () {
      test('should serialize createdBy and admins to JSON', () {
        // arrange
        final chatRoom = ChatRoomModel(
          id: 'room-1',
          name: 'Test Group',
          members: ['user-1', 'user-2'],
          createdAt: tCreatedAt,
          isGroup: true,
          createdBy: 'user-1',
          admins: ['user-1'],
        );

        // act
        final result = chatRoom.toJson();

        // assert
        expect(result['createdBy'], 'user-1');
        expect(result['admins'], ['user-1']);
      });

      test('should serialize null createdBy', () {
        // arrange
        final chatRoom = ChatRoomModel(
          id: 'room-1',
          name: 'Test Group',
          members: ['user-1', 'user-2'],
          createdAt: tCreatedAt,
          isGroup: true,
          admins: ['user-1'],
        );

        // act
        final result = chatRoom.toJson();

        // assert
        expect(result['createdBy'], isNull);
      });

      test('should serialize empty admins list', () {
        // arrange
        final chatRoom = ChatRoomModel(
          id: 'room-1',
          name: 'Test Group',
          members: ['user-1', 'user-2'],
          createdAt: tCreatedAt,
          isGroup: true,
        );

        // act
        final result = chatRoom.toJson();

        // assert
        expect(result['admins'], isEmpty);
      });

      test('should round-trip correctly through JSON', () {
        // arrange
        final original = ChatRoomModel(
          id: 'room-1',
          name: 'Test Group',
          members: ['user-1', 'user-2', 'user-3'],
          createdAt: tCreatedAt,
          isGroup: true,
          createdBy: 'user-1',
          admins: ['user-1', 'user-2'],
        );

        // act
        final json = original.toJson();
        json['id'] = original.id; // Add id back since it's usually from doc.id
        final restored = ChatRoomModel.fromJson(json);

        // assert
        expect(restored.id, original.id);
        expect(restored.name, original.name);
        expect(restored.members, original.members);
        expect(restored.isGroup, original.isGroup);
        expect(restored.createdBy, original.createdBy);
        expect(restored.admins, original.admins);
      });
    });

    group('isAdmin (inherited)', () {
      test('should correctly identify admins from parsed JSON', () {
        // arrange
        final json = {
          'id': 'room-1',
          'name': 'Test Group',
          'members': ['user-1', 'user-2', 'user-3'],
          'createdAt': tCreatedAt.toIso8601String(),
          'isGroup': true,
          'createdBy': 'user-1',
          'admins': ['user-1', 'user-3'],
        };

        // act
        final chatRoom = ChatRoomModel.fromJson(json);

        // assert
        expect(chatRoom.isAdmin('user-1'), true);
        expect(chatRoom.isAdmin('user-2'), false);
        expect(chatRoom.isAdmin('user-3'), true);
      });
    });
  });
}
