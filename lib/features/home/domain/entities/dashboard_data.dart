import 'package:equatable/equatable.dart';

class DashboardData extends Equatable {
  final UserSummary user;
  final FriendsSummary friends;
  final ExpenseSummary expenses;
  final int pendingTasksCount;
  final int upcomingEventsCount;
  final int unreadNotificationsCount;
  final int groceryItemsCount;
  final List<RecentActivity> recentActivities;

  const DashboardData({
    required this.user,
    required this.friends,
    required this.expenses,
    required this.pendingTasksCount,
    required this.upcomingEventsCount,
    required this.unreadNotificationsCount,
    this.groceryItemsCount = 0,
    required this.recentActivities,
  });

  @override
  List<Object?> get props => [
    user,
    friends,
    expenses,
    pendingTasksCount,
    upcomingEventsCount,
    unreadNotificationsCount,
    groceryItemsCount,
    recentActivities,
  ];
}

class UserSummary extends Equatable {
  final String id;
  final String name;
  final String username;
  final String email;
  final String? photoUrl;
  final String avatarInitial;

  const UserSummary({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.photoUrl,
    required this.avatarInitial,
  });

  String get firstName => name.split(' ').first;

  @override
  List<Object?> get props => [
    id,
    name,
    username,
    email,
    photoUrl,
    avatarInitial,
  ];
}

class FriendsSummary extends Equatable {
  final int friendCount;
  final List<MemberSummary> friends;

  const FriendsSummary({required this.friendCount, required this.friends});

  @override
  List<Object?> get props => [friendCount, friends];
}

class MemberSummary extends Equatable {
  final String id;
  final String name;
  final String avatarInitial;
  final String? photoUrl;
  final bool isOnline;
  final double? latitude;
  final double? longitude;

  const MemberSummary({
    required this.id,
    required this.name,
    required this.avatarInitial,
    this.photoUrl,
    required this.isOnline,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    avatarInitial,
    photoUrl,
    isOnline,
    latitude,
    longitude,
  ];
}

class ExpenseSummary extends Equatable {
  final double totalGroupExpenses;
  final double userShare;
  final int pendingBillsCount;

  const ExpenseSummary({
    required this.totalGroupExpenses,
    required this.userShare,
    required this.pendingBillsCount,
  });

  @override
  List<Object?> get props => [totalGroupExpenses, userShare, pendingBillsCount];
}

class RecentActivity extends Equatable {
  final String id;
  final String sourceId;
  final DashboardActivityType type;
  final String title;
  final String description;
  final DateTime timestamp;
  final String? chatRoomId;
  final String? userId;
  final String? userName;

  const RecentActivity({
    required this.id,
    required this.sourceId,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    this.chatRoomId,
    this.userId,
    this.userName,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  @override
  List<Object?> get props => [
    id,
    sourceId,
    type,
    title,
    description,
    timestamp,
    chatRoomId,
    userId,
    userName,
  ];
}

enum DashboardActivityType {
  expense,
  task,
  event,
  location,
  grocery,
  bill,
  chat,
  timetable,
}
