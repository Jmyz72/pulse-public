import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.username,
    required super.displayName,
    required super.email,
    required super.phone,
    super.paymentIdentity,
    super.photoUrl,
    super.dateJoining,
    super.groupIds = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['userId'] ?? '',
      username: json['username'] ?? '',
      displayName: json['displayName'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      paymentIdentity: json['paymentIdentity'] as String?,
      photoUrl: json['photoUrl'],
      dateJoining: _parseDateTime(json['dateJoining']),
      groupIds:
          (json['groupIds'] as List<dynamic>?)?.whereType<String>().toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': id,
      'username': username,
      'displayName': displayName,
      'email': email,
      'phone': phone,
      'paymentIdentity': paymentIdentity,
      'photoUrl': photoUrl,
      'dateJoining': dateJoining?.toIso8601String(),
      'groupIds': groupIds,
    };
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      username: user.username,
      displayName: user.displayName,
      email: user.email,
      phone: user.phone,
      paymentIdentity: user.paymentIdentity,
      photoUrl: user.photoUrl,
      dateJoining: user.dateJoining,
      groupIds: user.groupIds,
    );
  }
}
