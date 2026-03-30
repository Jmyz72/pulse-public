import 'package:equatable/equatable.dart';

import '../../../auth/domain/entities/user.dart';
import '../../domain/entities/friend_profile_stats.dart';
import '../../domain/entities/friendship.dart';

enum FriendLoadStatus { initial, loading, loaded, error }

enum SearchStatus { initial, loading, loaded, error }

enum ActionStatus { idle, processing, success, error }

class FriendState extends Equatable {
  final FriendLoadStatus friendsStatus;
  final FriendLoadStatus requestsStatus;
  final SearchStatus searchStatus;
  final ActionStatus actionStatus;
  final FriendLoadStatus profileStatsStatus;
  final List<Friendship> friends;
  final List<Friendship> pendingRequests;
  final List<User> searchResults;
  final List<Friendship> sentRequests;
  final FriendProfileStats? friendProfileStats;
  final String? errorMessage;
  final String? successMessage;

  const FriendState({
    this.friendsStatus = FriendLoadStatus.initial,
    this.requestsStatus = FriendLoadStatus.initial,
    this.searchStatus = SearchStatus.initial,
    this.actionStatus = ActionStatus.idle,
    this.profileStatsStatus = FriendLoadStatus.initial,
    this.friends = const [],
    this.pendingRequests = const [],
    this.searchResults = const [],
    this.sentRequests = const [],
    this.friendProfileStats,
    this.errorMessage,
    this.successMessage,
  });

  FriendState copyWith({
    FriendLoadStatus? friendsStatus,
    FriendLoadStatus? requestsStatus,
    SearchStatus? searchStatus,
    ActionStatus? actionStatus,
    FriendLoadStatus? profileStatsStatus,
    List<Friendship>? friends,
    List<Friendship>? pendingRequests,
    List<User>? searchResults,
    List<Friendship>? sentRequests,
    FriendProfileStats? friendProfileStats,
    bool clearFriendProfileStats = false,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return FriendState(
      friendsStatus: friendsStatus ?? this.friendsStatus,
      requestsStatus: requestsStatus ?? this.requestsStatus,
      searchStatus: searchStatus ?? this.searchStatus,
      actionStatus: actionStatus ?? this.actionStatus,
      profileStatsStatus: profileStatsStatus ?? this.profileStatsStatus,
      friends: friends ?? this.friends,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      searchResults: searchResults ?? this.searchResults,
      sentRequests: sentRequests ?? this.sentRequests,
      friendProfileStats: clearFriendProfileStats
          ? null
          : (friendProfileStats ?? this.friendProfileStats),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
    friendsStatus,
    requestsStatus,
    searchStatus,
    actionStatus,
    profileStatsStatus,
    friends,
    pendingRequests,
    searchResults,
    sentRequests,
    friendProfileStats,
    errorMessage,
    successMessage,
  ];
}
