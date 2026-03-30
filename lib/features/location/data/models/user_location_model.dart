import '../../domain/entities/location.dart';

class UserLocationModel extends UserLocation {
  const UserLocationModel({
    required super.userId,
    required super.userName,
    required super.latitude,
    required super.longitude,
    required super.lastUpdated,
    super.isSharing,
    super.hiddenFrom = const [],
  });

  factory UserLocationModel.fromJson(Map<String, dynamic> json) {
    return UserLocationModel(
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
      isSharing: json['isSharing'] ?? true,
      hiddenFrom: List<String>.from(json['hiddenFrom'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'latitude': latitude,
      'longitude': longitude,
      'lastUpdated': lastUpdated.toIso8601String(),
      'isSharing': isSharing,
      'hiddenFrom': hiddenFrom,
    };
  }

  factory UserLocationModel.fromEntity(UserLocation location) {
    return UserLocationModel(
      userId: location.userId,
      userName: location.userName,
      latitude: location.latitude,
      longitude: location.longitude,
      lastUpdated: location.lastUpdated,
      isSharing: location.isSharing,
      hiddenFrom: location.hiddenFrom,
    );
  }
}
