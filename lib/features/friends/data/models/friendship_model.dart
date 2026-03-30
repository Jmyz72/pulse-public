import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/friendship.dart';

class FriendshipModel extends Friendship {
  const FriendshipModel({
    required super.id,
    required super.userId,
    required super.friendId,
    required super.friendUsername,
    required super.friendDisplayName,
    required super.friendEmail,
    required super.friendPhone,
    super.friendPhotoUrl,
    required super.requesterUsername,
    required super.requesterDisplayName,
    required super.requesterEmail,
    required super.requesterPhone,
    super.requesterPhotoUrl,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
  });

  factory FriendshipModel.fromJson(Map<String, dynamic> json) {
    return FriendshipModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      friendId: json['friendId'] ?? '',
      friendUsername: json['friendUsername'] ?? '',
      friendDisplayName: json['friendDisplayName'] ?? '',
      friendEmail: json['friendEmail'] ?? '',
      friendPhone: json['friendPhone'] ?? '',
      friendPhotoUrl: json['friendPhotoUrl'] as String?,
      requesterUsername: json['requesterUsername'] ?? '',
      requesterDisplayName: json['requesterDisplayName'] ?? '',
      requesterEmail: json['requesterEmail'] ?? '',
      requesterPhone: json['requesterPhone'] ?? '',
      requesterPhotoUrl: json['requesterPhotoUrl'] as String?,
      status: FriendshipStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => FriendshipStatus.pending,
      ),
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'friendId': friendId,
      'friendUsername': friendUsername,
      'friendDisplayName': friendDisplayName,
      'friendEmail': friendEmail,
      'friendPhone': friendPhone,
      'friendPhotoUrl': friendPhotoUrl,
      'requesterUsername': requesterUsername,
      'requesterDisplayName': requesterDisplayName,
      'requesterEmail': requesterEmail,
      'requesterPhone': requesterPhone,
      'requesterPhotoUrl': requesterPhotoUrl,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory FriendshipModel.fromEntity(Friendship friendship) {
    return FriendshipModel(
      id: friendship.id,
      userId: friendship.userId,
      friendId: friendship.friendId,
      friendUsername: friendship.friendUsername,
      friendDisplayName: friendship.friendDisplayName,
      friendEmail: friendship.friendEmail,
      friendPhone: friendship.friendPhone,
      friendPhotoUrl: friendship.friendPhotoUrl,
      requesterUsername: friendship.requesterUsername,
      requesterDisplayName: friendship.requesterDisplayName,
      requesterEmail: friendship.requesterEmail,
      requesterPhone: friendship.requesterPhone,
      requesterPhotoUrl: friendship.requesterPhotoUrl,
      status: friendship.status,
      createdAt: friendship.createdAt,
      updatedAt: friendship.updatedAt,
    );
  }
}
