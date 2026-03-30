import 'package:equatable/equatable.dart';

class FriendProfileStats extends Equatable {
  final int mutualRoomsCount;
  final int mutualFriendsCount;
  final bool isOnline;

  const FriendProfileStats({
    required this.mutualRoomsCount,
    required this.mutualFriendsCount,
    required this.isOnline,
  });

  @override
  List<Object?> get props => [mutualRoomsCount, mutualFriendsCount, isOnline];
}
