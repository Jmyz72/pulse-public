import 'package:equatable/equatable.dart';

enum FriendshipStatus { pending, accepted, declined, blocked }

class Friendship extends Equatable {
  final String id;
  final String userId;
  final String friendId;
  final String friendUsername;
  final String friendDisplayName;
  final String friendEmail;
  final String friendPhone;
  final String? friendPhotoUrl;
  final String requesterUsername;
  final String requesterDisplayName;
  final String requesterEmail;
  final String requesterPhone;
  final String? requesterPhotoUrl;
  final FriendshipStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Friendship({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.friendUsername,
    required this.friendDisplayName,
    required this.friendEmail,
    required this.friendPhone,
    this.friendPhotoUrl,
    required this.requesterUsername,
    required this.requesterDisplayName,
    required this.requesterEmail,
    required this.requesterPhone,
    this.requesterPhotoUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    friendId,
    friendUsername,
    friendDisplayName,
    friendEmail,
    friendPhone,
    friendPhotoUrl,
    requesterUsername,
    requesterDisplayName,
    requesterEmail,
    requesterPhone,
    requesterPhotoUrl,
    status,
    createdAt,
    updatedAt,
  ];
}
