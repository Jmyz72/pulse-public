import '../../domain/entities/friend_profile_stats.dart';

class FriendProfileStatsModel extends FriendProfileStats {
  const FriendProfileStatsModel({
    required super.mutualRoomsCount,
    required super.mutualFriendsCount,
    required super.isOnline,
  });

  factory FriendProfileStatsModel.fromJson(Map<String, dynamic> json) {
    return FriendProfileStatsModel(
      mutualRoomsCount: json['mutualRoomsCount'] as int? ?? 0,
      mutualFriendsCount: json['mutualFriendsCount'] as int? ?? 0,
      isOnline: json['isOnline'] as bool? ?? false,
    );
  }
}
