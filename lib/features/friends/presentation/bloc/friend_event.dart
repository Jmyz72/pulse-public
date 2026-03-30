import 'package:equatable/equatable.dart';

abstract class FriendEvent extends Equatable {
  const FriendEvent();

  @override
  List<Object?> get props => [];
}

class FriendsLoadRequested extends FriendEvent {
  final String userId;
  const FriendsLoadRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

class PendingRequestsLoadRequested extends FriendEvent {
  final String userId;
  const PendingRequestsLoadRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

class FriendRequestSendRequested extends FriendEvent {
  final String userId;
  final String email;
  const FriendRequestSendRequested({required this.userId, required this.email});

  @override
  List<Object?> get props => [userId, email];
}

class FriendRequestAcceptRequested extends FriendEvent {
  final String friendshipId;
  final String userId;
  const FriendRequestAcceptRequested(this.friendshipId, {required this.userId});

  @override
  List<Object?> get props => [friendshipId, userId];
}

class FriendRequestDeclineRequested extends FriendEvent {
  final String friendshipId;
  const FriendRequestDeclineRequested(this.friendshipId);

  @override
  List<Object?> get props => [friendshipId];
}

class FriendRemoveRequested extends FriendEvent {
  final String friendshipId;
  const FriendRemoveRequested(this.friendshipId);

  @override
  List<Object?> get props => [friendshipId];
}

class FriendProfileStatsRequested extends FriendEvent {
  final String currentUserId;
  final String friendUserId;

  const FriendProfileStatsRequested({
    required this.currentUserId,
    required this.friendUserId,
  });

  @override
  List<Object?> get props => [currentUserId, friendUserId];
}

class UserSearchRequested extends FriendEvent {
  final String query;
  const UserSearchRequested(this.query);

  @override
  List<Object?> get props => [query];
}

class FriendSearchCleared extends FriendEvent {
  const FriendSearchCleared();
}

class FriendClearRequested extends FriendEvent {
  const FriendClearRequested();
}

class FriendMessageCleared extends FriendEvent {
  const FriendMessageCleared();
}
