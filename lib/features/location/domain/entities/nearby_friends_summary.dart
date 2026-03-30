import 'package:equatable/equatable.dart';

class NearbyFriendsSummary extends Equatable {
  final int count;
  final bool isReliable;

  const NearbyFriendsSummary({required this.count, required this.isReliable});

  const NearbyFriendsSummary.unreliable() : count = 0, isReliable = false;

  @override
  List<Object?> get props => [count, isReliable];
}
