import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../domain/usecases/accept_friend_request.dart';
import '../../domain/usecases/decline_friend_request.dart';
import '../../domain/usecases/get_friend_profile_stats.dart';
import '../../domain/usecases/get_friends.dart';
import '../../domain/usecases/get_pending_requests.dart';
import '../../domain/usecases/get_sent_requests.dart';
import '../../domain/usecases/remove_friend.dart';
import '../../domain/usecases/search_users.dart';
import '../../domain/usecases/send_friend_request.dart';
import 'friend_event.dart';
import 'friend_state.dart';

EventTransformer<E> _debounce<E>(Duration duration) {
  return (events, mapper) => events.debounce(duration).switchMap(mapper);
}

class FriendBloc extends Bloc<FriendEvent, FriendState> {
  final GetFriends getFriends;
  final GetPendingRequests getPendingRequests;
  final GetSentRequests getSentRequests;
  final SendFriendRequest sendFriendRequest;
  final AcceptFriendRequest acceptFriendRequest;
  final DeclineFriendRequest declineFriendRequest;
  final RemoveFriend removeFriend;
  final SearchUsers searchUsers;
  final GetFriendProfileStats getFriendProfileStats;

  FriendBloc({
    required this.getFriends,
    required this.getPendingRequests,
    required this.getSentRequests,
    required this.sendFriendRequest,
    required this.acceptFriendRequest,
    required this.declineFriendRequest,
    required this.removeFriend,
    required this.searchUsers,
    required this.getFriendProfileStats,
  }) : super(const FriendState()) {
    on<FriendsLoadRequested>(_onFriendsLoadRequested);
    on<PendingRequestsLoadRequested>(_onPendingRequestsLoadRequested);
    on<FriendRequestSendRequested>(
      _onFriendRequestSendRequested,
      transformer: droppable(),
    );
    on<FriendRequestAcceptRequested>(
      _onFriendRequestAcceptRequested,
      transformer: droppable(),
    );
    on<FriendRequestDeclineRequested>(
      _onFriendRequestDeclineRequested,
      transformer: droppable(),
    );
    on<FriendRemoveRequested>(
      _onFriendRemoveRequested,
      transformer: droppable(),
    );
    on<FriendProfileStatsRequested>(
      _onFriendProfileStatsRequested,
      transformer: droppable(),
    );
    on<UserSearchRequested>(
      _onUserSearchRequested,
      transformer: _debounce(const Duration(milliseconds: 400)),
    );
    on<FriendSearchCleared>(_onFriendSearchCleared);
    on<FriendClearRequested>(_onFriendClearRequested);
    on<FriendMessageCleared>(_onMessageCleared);
  }

  void _onFriendSearchCleared(
    FriendSearchCleared event,
    Emitter<FriendState> emit,
  ) {
    emit(
      state.copyWith(
        searchResults: [],
        searchStatus: SearchStatus.initial,
        actionStatus: ActionStatus.idle,
        clearError: true,
        clearSuccess: true,
      ),
    );
  }

  void _onFriendClearRequested(
    FriendClearRequested event,
    Emitter<FriendState> emit,
  ) {
    emit(const FriendState());
  }

  void _onMessageCleared(
    FriendMessageCleared event,
    Emitter<FriendState> emit,
  ) {
    emit(
      state.copyWith(
        clearError: true,
        clearSuccess: true,
        actionStatus: ActionStatus.idle,
      ),
    );
  }

  Future<void> _onFriendsLoadRequested(
    FriendsLoadRequested event,
    Emitter<FriendState> emit,
  ) async {
    emit(
      state.copyWith(
        friendsStatus: FriendLoadStatus.loading,
        clearError: true,
        clearSuccess: true,
      ),
    );
    final result = await getFriends(event.userId);
    result.fold(
      (failure) => emit(
        state.copyWith(
          friendsStatus: FriendLoadStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (friends) => emit(
        state.copyWith(
          friendsStatus: FriendLoadStatus.loaded,
          friends: friends,
        ),
      ),
    );
  }

  Future<void> _onPendingRequestsLoadRequested(
    PendingRequestsLoadRequested event,
    Emitter<FriendState> emit,
  ) async {
    emit(
      state.copyWith(
        requestsStatus: FriendLoadStatus.loading,
        clearError: true,
        clearSuccess: true,
      ),
    );
    final pendingFuture = getPendingRequests(event.userId);
    final sentFuture = getSentRequests(event.userId);

    final pendingResult = await pendingFuture;
    final sentResult = await sentFuture;

    pendingResult.fold(
      (failure) => emit(
        state.copyWith(
          requestsStatus: FriendLoadStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (requests) {
        sentResult.fold(
          (failure) => emit(
            state.copyWith(
              requestsStatus: FriendLoadStatus.error,
              errorMessage: failure.message,
            ),
          ),
          (sentRequests) => emit(
            state.copyWith(
              requestsStatus: FriendLoadStatus.loaded,
              pendingRequests: requests,
              sentRequests: sentRequests,
            ),
          ),
        );
      },
    );
  }

  Future<void> _onFriendRequestSendRequested(
    FriendRequestSendRequested event,
    Emitter<FriendState> emit,
  ) async {
    emit(
      state.copyWith(
        actionStatus: ActionStatus.processing,
        clearError: true,
        clearSuccess: true,
      ),
    );
    final result = await sendFriendRequest(
      SendFriendRequestParams(userId: event.userId, friendEmail: event.email),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          actionStatus: ActionStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (friendship) => emit(
        state.copyWith(
          actionStatus: ActionStatus.success,
          successMessage: 'Friend request sent!',
          sentRequests: [...state.sentRequests, friendship],
        ),
      ),
    );
  }

  Future<void> _onFriendRequestAcceptRequested(
    FriendRequestAcceptRequested event,
    Emitter<FriendState> emit,
  ) async {
    // Optimistic removal from pending — save for rollback
    final previousPending = state.pendingRequests;
    final updatedPending = previousPending
        .where((r) => r.id != event.friendshipId)
        .toList();
    emit(
      state.copyWith(
        pendingRequests: updatedPending,
        clearError: true,
        clearSuccess: true,
      ),
    );

    final result = await acceptFriendRequest(event.friendshipId);
    await result.fold(
      (failure) async => emit(
        state.copyWith(
          actionStatus: ActionStatus.error,
          errorMessage: failure.message,
          pendingRequests: previousPending,
        ),
      ),
      (_) async {
        // Load friends inline to avoid race condition with separate event
        final friendsResult = await getFriends(event.userId);
        friendsResult.fold(
          (failure) => emit(
            state.copyWith(
              friendsStatus: FriendLoadStatus.loaded,
              successMessage: 'Friend request accepted!',
            ),
          ),
          (friends) => emit(
            state.copyWith(
              friendsStatus: FriendLoadStatus.loaded,
              friends: friends,
              successMessage: 'Friend request accepted!',
            ),
          ),
        );
      },
    );
  }

  Future<void> _onFriendRequestDeclineRequested(
    FriendRequestDeclineRequested event,
    Emitter<FriendState> emit,
  ) async {
    final previousPending = state.pendingRequests;
    final previousSent = state.sentRequests;
    final updatedPending = previousPending
        .where((r) => r.id != event.friendshipId)
        .toList();
    final updatedSent = previousSent
        .where((r) => r.id != event.friendshipId)
        .toList();
    final wasSentRequest = previousSent.any((r) => r.id == event.friendshipId);
    emit(
      state.copyWith(
        pendingRequests: updatedPending,
        sentRequests: updatedSent,
        clearError: true,
        clearSuccess: true,
      ),
    );

    final result = await declineFriendRequest(event.friendshipId);
    result.fold(
      (failure) => emit(
        state.copyWith(
          actionStatus: ActionStatus.error,
          errorMessage: failure.message,
          pendingRequests: previousPending,
          sentRequests: previousSent,
        ),
      ),
      (_) => emit(
        state.copyWith(
          successMessage: wasSentRequest
              ? 'Friend request canceled'
              : 'Friend request declined',
        ),
      ),
    );
  }

  Future<void> _onFriendRemoveRequested(
    FriendRemoveRequested event,
    Emitter<FriendState> emit,
  ) async {
    final previousFriends = state.friends;
    final updatedFriends = previousFriends
        .where((f) => f.id != event.friendshipId)
        .toList();
    emit(
      state.copyWith(
        friends: updatedFriends,
        clearError: true,
        clearSuccess: true,
      ),
    );

    final result = await removeFriend(event.friendshipId);
    result.fold(
      (failure) => emit(
        state.copyWith(
          actionStatus: ActionStatus.error,
          errorMessage: failure.message,
          friends: previousFriends,
        ),
      ),
      (_) => emit(state.copyWith(successMessage: 'Friend removed')),
    );
  }

  Future<void> _onUserSearchRequested(
    UserSearchRequested event,
    Emitter<FriendState> emit,
  ) async {
    if (event.query.trim().isEmpty) {
      emit(
        state.copyWith(
          searchResults: [],
          searchStatus: SearchStatus.initial,
          clearError: true,
          clearSuccess: true,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        searchStatus: SearchStatus.loading,
        clearError: true,
        clearSuccess: true,
      ),
    );
    final result = await searchUsers(event.query);
    result.fold(
      (failure) => emit(
        state.copyWith(
          searchStatus: SearchStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (users) => emit(
        state.copyWith(searchStatus: SearchStatus.loaded, searchResults: users),
      ),
    );
  }

  Future<void> _onFriendProfileStatsRequested(
    FriendProfileStatsRequested event,
    Emitter<FriendState> emit,
  ) async {
    emit(
      state.copyWith(
        profileStatsStatus: FriendLoadStatus.loading,
        clearFriendProfileStats: true,
      ),
    );

    final result = await getFriendProfileStats(
      GetFriendProfileStatsParams(
        currentUserId: event.currentUserId,
        friendUserId: event.friendUserId,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          profileStatsStatus: FriendLoadStatus.error,
          clearFriendProfileStats: true,
          errorMessage: failure.message,
        ),
      ),
      (stats) => emit(
        state.copyWith(
          profileStatsStatus: FriendLoadStatus.loaded,
          friendProfileStats: stats,
          clearError: true,
        ),
      ),
    );
  }
}
