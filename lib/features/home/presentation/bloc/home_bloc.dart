import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/bloc_event_transformers.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/usecases/get_dashboard_data.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetDashboardData getDashboardData;
  static const _homeTabIndex = 2;
  static const _autoRefreshStaleAfter = Duration(seconds: 30);

  HomeBloc({required this.getDashboardData}) : super(const HomeState()) {
    on<HomeTabChangeRequested>(_onTabChanged);
    on<HomeDashboardRequested>(_onDashboardRequested, transformer: droppable());
    on<HomeRefreshRequested>(
      _onRefreshRequested,
      transformer: throttle(const Duration(milliseconds: 500)),
    );
    on<HomeClearedRequested>(_onClearedRequested);
  }

  void _onTabChanged(HomeTabChangeRequested event, Emitter<HomeState> emit) {
    emit(state.copyWith(currentTab: event.tabIndex));

    // Auto-refresh when returning to Home tab.
    if (event.tabIndex == _homeTabIndex && state.status == HomeStatus.loaded) {
      add(const HomeRefreshRequested());
    }
  }

  Future<void> _onDashboardRequested(
    HomeDashboardRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(status: HomeStatus.loading));

    final result = await getDashboardData(const NoParams());

    result.fold(
      (failure) => emit(
        state.copyWith(status: HomeStatus.error, errorMessage: failure.message),
      ),
      (dashboardData) => emit(
        state.copyWith(
          status: HomeStatus.loaded,
          dashboardData: dashboardData,
          lastLoadedAt: DateTime.now(),
        ),
      ),
    );
  }

  Future<void> _onRefreshRequested(
    HomeRefreshRequested event,
    Emitter<HomeState> emit,
  ) async {
    if (!_shouldRefresh(force: event.force)) {
      return;
    }

    // Don't show loading indicator for refresh, just fetch new data
    final result = await getDashboardData(const NoParams());

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: HomeStatus.error,
          errorMessage: failure.message,
          refreshCount: state.refreshCount + 1,
        ),
      ),
      (dashboardData) => emit(
        state.copyWith(
          status: HomeStatus.loaded,
          dashboardData: dashboardData,
          refreshCount: state.refreshCount + 1,
          lastLoadedAt: DateTime.now(),
        ),
      ),
    );
  }

  void _onClearedRequested(
    HomeClearedRequested event,
    Emitter<HomeState> emit,
  ) {
    emit(const HomeState());
  }

  bool _shouldRefresh({required bool force}) {
    if (force) return true;
    if (state.status == HomeStatus.loading) return false;
    if (state.lastLoadedAt == null) return true;
    return DateTime.now().difference(state.lastLoadedAt!) >
        _autoRefreshStaleAfter;
  }
}
