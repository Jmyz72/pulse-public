import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import 'user.dart';

sealed class GoogleAuthResult extends Equatable {
  const GoogleAuthResult();
}

class GooglePendingProfileData extends Equatable {
  final String email;
  final String displayName;
  final String? photoUrl;
  final firebase_auth.AuthCredential? pendingCredential;

  const GooglePendingProfileData({
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.pendingCredential,
  });

  GooglePendingProfileData copyWith({
    String? email,
    String? displayName,
    String? photoUrl,
    firebase_auth.AuthCredential? pendingCredential,
  }) {
    return GooglePendingProfileData(
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      pendingCredential: pendingCredential ?? this.pendingCredential,
    );
  }

  @override
  List<Object?> get props => [email, displayName, photoUrl, pendingCredential];
}

class GoogleAuthAuthenticated extends GoogleAuthResult {
  final User user;

  const GoogleAuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class GoogleAuthUsernameSetupRequired extends GoogleAuthResult {
  final GooglePendingProfileData pendingProfileData;

  const GoogleAuthUsernameSetupRequired(this.pendingProfileData);

  @override
  List<Object?> get props => [pendingProfileData];
}

class GoogleAuthLinkRequired extends GoogleAuthResult {
  final GooglePendingProfileData pendingProfileData;
  final String email;

  const GoogleAuthLinkRequired({
    required this.pendingProfileData,
    required this.email,
  });

  @override
  List<Object?> get props => [pendingProfileData, email];
}
