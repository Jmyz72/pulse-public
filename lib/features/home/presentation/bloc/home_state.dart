part of 'home_bloc.dart';

enum HomeStatus { initial, loading, loaded, error }

class HomeState extends Equatable {
  final HomeStatus status;
  final int currentTab;
  final DashboardData? dashboardData;
  final String? errorMessage;
  final int refreshCount; // Incremented on each refresh to ensure state change
  final DateTime? lastLoadedAt;

  const HomeState({
    this.status = HomeStatus.initial,
    this.currentTab = 2, // Start with Home tab (center)
    this.dashboardData,
    this.errorMessage,
    this.refreshCount = 0,
    this.lastLoadedAt,
  });

  // Convenience getters for dashboard data
  UserSummary? get user => dashboardData?.user;
  FriendsSummary? get friends => dashboardData?.friends;
  ExpenseSummary? get expenses => dashboardData?.expenses;
  int get pendingTasksCount => dashboardData?.pendingTasksCount ?? 0;
  int get upcomingEventsCount => dashboardData?.upcomingEventsCount ?? 0;
  int get unreadNotificationsCount =>
      dashboardData?.unreadNotificationsCount ?? 0;
  List<RecentActivity> get recentActivities =>
      dashboardData?.recentActivities ?? [];
  int get groceryItemsCount => dashboardData?.groceryItemsCount ?? 0;

  HomeState copyWith({
    HomeStatus? status,
    int? currentTab,
    DashboardData? dashboardData,
    String? errorMessage,
    int? refreshCount,
    DateTime? lastLoadedAt,
  }) {
    return HomeState(
      status: status ?? this.status,
      currentTab: currentTab ?? this.currentTab,
      dashboardData: dashboardData ?? this.dashboardData,
      errorMessage: errorMessage,
      refreshCount: refreshCount ?? this.refreshCount,
      lastLoadedAt: lastLoadedAt ?? this.lastLoadedAt,
    );
  }

  @override
  List<Object?> get props => [
    status,
    currentTab,
    dashboardData,
    errorMessage,
    refreshCount,
  ];
}
