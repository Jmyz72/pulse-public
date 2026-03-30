import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/chat/domain/entities/message.dart';

void main() {
  group('ChatRoom', () {
    group('isAdmin', () {
      test('should return true when user is in admins list', () {
        // arrange
        final chatRoom = ChatRoom(
          id: '1',
          name: 'Test Group',
          members: ['user-1', 'user-2', 'user-3'],
          createdAt: DateTime(2024, 1, 1),
          isGroup: true,
          admins: ['user-1', 'user-2'],
        );

        // act & assert
        expect(chatRoom.isAdmin('user-1'), true);
        expect(chatRoom.isAdmin('user-2'), true);
        expect(chatRoom.isAdmin('user-3'), false);
      });

      test('should return false when user is not in admins list', () {
        // arrange
        final chatRoom = ChatRoom(
          id: '1',
          name: 'Test Group',
          members: ['user-1', 'user-2', 'user-3'],
          createdAt: DateTime(2024, 1, 1),
          isGroup: true,
          admins: ['user-1'],
        );

        // act & assert
        expect(chatRoom.isAdmin('user-2'), false);
        expect(chatRoom.isAdmin('user-3'), false);
        expect(chatRoom.isAdmin('unknown-user'), false);
      });

      test('should treat first member as admin when admins list is empty (backward compatibility)', () {
        // arrange
        final chatRoom = ChatRoom(
          id: '1',
          name: 'Test Group',
          members: ['user-1', 'user-2', 'user-3'],
          createdAt: DateTime(2024, 1, 1),
          isGroup: true,
          admins: [], // Empty admins list (legacy group)
        );

        // act & assert
        expect(chatRoom.isAdmin('user-1'), true); // First member is admin
        expect(chatRoom.isAdmin('user-2'), false);
        expect(chatRoom.isAdmin('user-3'), false);
      });

      test('should return false when both members and admins are empty', () {
        // arrange
        final chatRoom = ChatRoom(
          id: '1',
          name: 'Empty Group',
          members: [],
          createdAt: DateTime(2024, 1, 1),
          isGroup: true,
          admins: [],
        );

        // act & assert
        expect(chatRoom.isAdmin('any-user'), false);
      });

      test('should handle single admin correctly', () {
        // arrange
        final chatRoom = ChatRoom(
          id: '1',
          name: 'Test Group',
          members: ['user-1', 'user-2'],
          createdAt: DateTime(2024, 1, 1),
          isGroup: true,
          admins: ['user-2'], // Only user-2 is admin, not first member
        );

        // act & assert
        expect(chatRoom.isAdmin('user-1'), false);
        expect(chatRoom.isAdmin('user-2'), true);
      });
    });

    group('props', () {
      test('should include createdBy and admins in props', () {
        // arrange
        final chatRoom1 = ChatRoom(
          id: '1',
          name: 'Test Group',
          members: ['user-1'],
          createdAt: DateTime(2024, 1, 1),
          isGroup: true,
          createdBy: 'user-1',
          admins: ['user-1'],
        );

        final chatRoom2 = ChatRoom(
          id: '1',
          name: 'Test Group',
          members: ['user-1'],
          createdAt: DateTime(2024, 1, 1),
          isGroup: true,
          createdBy: 'user-1',
          admins: ['user-1'],
        );

        final chatRoom3 = ChatRoom(
          id: '1',
          name: 'Test Group',
          members: ['user-1'],
          createdAt: DateTime(2024, 1, 1),
          isGroup: true,
          createdBy: 'user-2', // Different creator
          admins: ['user-1'],
        );

        // act & assert
        expect(chatRoom1, equals(chatRoom2));
        expect(chatRoom1, isNot(equals(chatRoom3)));
      });
    });

    group('constructor', () {
      test('should have default empty admins list', () {
        // arrange
        final chatRoom = ChatRoom(
          id: '1',
          name: 'Test',
          members: ['user-1'],
          createdAt: DateTime(2024, 1, 1),
        );

        // act & assert
        expect(chatRoom.admins, isEmpty);
        expect(chatRoom.createdBy, isNull);
      });

      test('should accept createdBy and admins parameters', () {
        // arrange
        final chatRoom = ChatRoom(
          id: '1',
          name: 'Test',
          members: ['user-1', 'user-2'],
          createdAt: DateTime(2024, 1, 1),
          isGroup: true,
          createdBy: 'user-1',
          admins: ['user-1'],
        );

        // act & assert
        expect(chatRoom.createdBy, 'user-1');
        expect(chatRoom.admins, ['user-1']);
      });
    });
  });
}
