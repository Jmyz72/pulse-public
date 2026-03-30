import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/home/data/utils/activity_feed_mapper.dart';
import 'package:pulse/features/home/domain/entities/dashboard_data.dart';

void main() {
  group('ActivityFeedMapper', () {
    test('maps shared collection docs into recent activity models', () {
      final expense = ActivityFeedMapper.fromExpenseDoc('expense-1', {
        'chatRoomId': 'room-1',
        'title': 'Dinner',
        'totalAmount': 48.5,
        'date': '2026-03-14T10:00:00.000',
        'ownerId': 'user-1',
        'userName': 'Alex',
      });
      final task = ActivityFeedMapper.fromTaskDoc('task-1', {
        'chatRoomId': 'room-1',
        'title': 'Take out trash',
        'createdAt': '2026-03-13T09:00:00.000',
        'assignedToName': 'Jamie',
        'createdBy': 'user-2',
      });
      final grocery = ActivityFeedMapper.fromGroceryDoc('grocery-1', {
        'chatRoomId': 'room-1',
        'name': 'Milk',
        'createdAt': Timestamp.fromDate(DateTime(2026, 3, 12, 8)),
        'addedBy': 'user-3',
        'addedByName': 'Taylor',
        'quantity': 2,
      });

      expect(expense, isNotNull);
      expect(expense!.type, DashboardActivityType.expense);
      expect(expense.sourceId, 'expense-1');
      expect(expense.chatRoomId, 'room-1');
      expect(expense.description, contains('RM 48.50'));

      expect(task, isNotNull);
      expect(task!.type, DashboardActivityType.task);
      expect(task.description, 'Assigned to Jamie');

      expect(grocery, isNotNull);
      expect(grocery!.type, DashboardActivityType.grocery);
      expect(grocery.description, contains('Qty 2'));
    });

    test('maps chat room activity using the latest message metadata', () {
      final activity = ActivityFeedMapper.fromChatRoomDoc(
        currentUserId: 'me',
        roomId: 'room-2',
        data: {
          'name': 'Housemates',
          'isGroup': true,
          'lastMessageAt': '2026-03-14T11:30:00.000',
          'lastMessage': {
            'senderId': 'user-2',
            'senderName': 'Jamie',
            'content': 'Can someone buy eggs?',
            'type': 'text',
          },
        },
      );

      expect(activity, isNotNull);
      expect(activity!.type, DashboardActivityType.chat);
      expect(activity.chatRoomId, 'room-2');
      expect(activity.title, 'Housemates');
      expect(activity.description, 'Jamie: Can someone buy eggs?');
    });

    test('merges and sorts multiple activity lists by newest first', () {
      final merged = ActivityFeedMapper.mergeAndLimit([
        [
          RecentActivity(
            id: 'task:1',
            sourceId: 'task-1',
            type: DashboardActivityType.task,
            title: 'Older task',
            description: 'Assigned to Alex',
            timestamp: DateTime(2026, 3, 10, 9),
            chatRoomId: 'room-1',
          ),
        ],
        [
          RecentActivity(
            id: 'chat:1',
            sourceId: 'room-2',
            type: DashboardActivityType.chat,
            title: 'Housemates',
            description: 'Jamie: Hello',
            timestamp: DateTime(2026, 3, 14, 11),
            chatRoomId: 'room-2',
          ),
          RecentActivity(
            id: 'expense:1',
            sourceId: 'expense-1',
            type: DashboardActivityType.expense,
            title: 'Dinner',
            description: 'Alex added an expense',
            timestamp: DateTime(2026, 3, 13, 18),
            chatRoomId: 'room-1',
          ),
        ],
      ], limit: 2);

      expect(merged, hasLength(2));
      expect(merged.first.id, 'chat:1');
      expect(merged.last.id, 'expense:1');
    });

    test('returns null for unsupported shared docs without room context', () {
      final activity = ActivityFeedMapper.fromTaskDoc('task-1', {
        'title': 'No room task',
        'createdAt': '2026-03-13T09:00:00.000',
      });

      expect(activity, isNull);
    });
  });
}
