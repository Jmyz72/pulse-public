import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String username;
  final String displayName;
  final String email;
  final String phone;
  final String? paymentIdentity;
  final String? photoUrl;
  final DateTime? dateJoining;
  final List<String> groupIds;

  const User({
    required this.id,
    required this.username,
    required this.displayName,
    required this.email,
    required this.phone,
    this.paymentIdentity,
    this.photoUrl,
    this.dateJoining,
    this.groupIds = const [],
  });

  @override
  List<Object?> get props => [
    id,
    username,
    displayName,
    email,
    phone,
    paymentIdentity,
    photoUrl,
    dateJoining,
    groupIds,
  ];
}
