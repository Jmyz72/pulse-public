import 'package:equatable/equatable.dart';

class UserLocation extends Equatable {
  final String userId;
  final String userName;
  final double latitude;
  final double longitude;
  final DateTime lastUpdated;
  final bool isSharing;
  final List<String> hiddenFrom;

  const UserLocation({
    required this.userId,
    required this.userName,
    required this.latitude,
    required this.longitude,
    required this.lastUpdated,
    this.isSharing = true,
    this.hiddenFrom = const [],
  });

  @override
  List<Object?> get props => [userId, userName, latitude, longitude, lastUpdated, isSharing, hiddenFrom];
}
