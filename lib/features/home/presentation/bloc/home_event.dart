part of 'home_bloc.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class HomeTabChangeRequested extends HomeEvent {
  final int tabIndex;

  const HomeTabChangeRequested({required this.tabIndex});

  @override
  List<Object> get props => [tabIndex];
}

class HomeDashboardRequested extends HomeEvent {
  const HomeDashboardRequested();
}

class HomeRefreshRequested extends HomeEvent {
  final bool force;

  const HomeRefreshRequested({this.force = false});

  @override
  List<Object?> get props => [force];
}

class HomeClearedRequested extends HomeEvent {
  const HomeClearedRequested();
}
