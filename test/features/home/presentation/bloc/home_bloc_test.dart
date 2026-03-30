import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/core/usecases/usecase.dart';
import 'package:pulse/features/home/domain/entities/dashboard_data.dart';
import 'package:pulse/features/home/domain/usecases/get_dashboard_data.dart';
import 'package:pulse/features/home/presentation/bloc/home_bloc.dart';

class MockGetDashboardData extends Mock implements GetDashboardData {}

void main() {
  late HomeBloc bloc;
  late MockGetDashboardData mockGetDashboardData;

  setUp(() {
    mockGetDashboardData = MockGetDashboardData();
    bloc = HomeBloc(getDashboardData: mockGetDashboardData);
  });

  tearDown(() {
    bloc.close();
  });

  // Test data with 't' prefix
  const tUserSummary = UserSummary(
    id: 'user-1',
    name: 'John Doe',
    username: 'john_doe',
    email: 'john@example.com',
    avatarInitial: 'J',
  );

  const tMemberSummary = MemberSummary(
    id: 'member-1',
    name: 'Jane Doe',
    avatarInitial: 'JD',
    isOnline: true,
    latitude: 3.1390,
    longitude: 101.6869,
  );

  const tFriendsSummary = FriendsSummary(
    friendCount: 3,
    friends: [tMemberSummary],
  );

  const tExpenseSummary = ExpenseSummary(
    totalGroupExpenses: 500.00,
    userShare: 150.00,
    pendingBillsCount: 2,
  );

  final tRecentActivity = RecentActivity(
    id: 'activity-1',
    sourceId: 'expense-1',
    type: DashboardActivityType.expense,
    title: 'Electricity Bill',
    description: 'Added by John',
    timestamp: DateTime(2024, 1, 15, 10, 30),
    chatRoomId: 'room-1',
    userId: 'user-1',
    userName: 'John Doe',
  );

  final tDashboardData = DashboardData(
    user: tUserSummary,
    friends: tFriendsSummary,
    expenses: tExpenseSummary,
    pendingTasksCount: 5,
    upcomingEventsCount: 3,
    unreadNotificationsCount: 7,
    recentActivities: [tRecentActivity],
  );

  const tTabIndex = 1;
  const tErrorMessage = 'Failed to load dashboard data';

  setUpAll(() {
    registerFallbackValue(const NoParams());
  });

  group('HomeBloc initial state', () {
    test(
      'initial state should be HomeState with initial status and default tab',
      () {
        expect(bloc.state, const HomeState());
        expect(bloc.state.status, HomeStatus.initial);
        expect(
          bloc.state.currentTab,
          2,
        ); // Default home tab is center (index 2)
        expect(bloc.state.dashboardData, isNull);
        expect(bloc.state.errorMessage, isNull);
      },
    );
  });

  group('HomeTabChangeRequested', () {
    blocTest<HomeBloc, HomeState>(
      'emits state with updated currentTab when HomeTabChangeRequested is added',
      build: () => bloc,
      act: (bloc) =>
          bloc.add(const HomeTabChangeRequested(tabIndex: tTabIndex)),
      expect: () => [const HomeState(currentTab: tTabIndex)],
    );

    blocTest<HomeBloc, HomeState>(
      'emits state with tab index 0 when switching to first tab',
      build: () => bloc,
      act: (bloc) => bloc.add(const HomeTabChangeRequested(tabIndex: 0)),
      expect: () => [const HomeState(currentTab: 0)],
    );

    blocTest<HomeBloc, HomeState>(
      'emits state with tab index 4 when switching to last tab',
      build: () => bloc,
      act: (bloc) => bloc.add(const HomeTabChangeRequested(tabIndex: 4)),
      expect: () => [const HomeState(currentTab: 4)],
    );

    blocTest<HomeBloc, HomeState>(
      'preserves other state fields when changing tab',
      build: () => bloc,
      seed: () => HomeState(
        status: HomeStatus.loaded,
        currentTab: 2,
        dashboardData: tDashboardData,
      ),
      act: (bloc) => bloc.add(const HomeTabChangeRequested(tabIndex: 3)),
      expect: () => [
        HomeState(
          status: HomeStatus.loaded,
          currentTab: 3,
          dashboardData: tDashboardData,
        ),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'allows multiple tab changes in sequence',
      build: () => bloc,
      act: (bloc) {
        bloc.add(const HomeTabChangeRequested(tabIndex: 0));
        bloc.add(const HomeTabChangeRequested(tabIndex: 2));
        bloc.add(const HomeTabChangeRequested(tabIndex: 4));
      },
      expect: () => [
        const HomeState(currentTab: 0),
        const HomeState(currentTab: 2),
        const HomeState(currentTab: 4),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'auto-refreshes when switching back to Home tab from loaded state',
      build: () {
        final tUpdatedDashboardData = DashboardData(
          user: tUserSummary,
          friends: tFriendsSummary,
          expenses: const ExpenseSummary(
            totalGroupExpenses: 700.00,
            userShare: 220.00,
            pendingBillsCount: 4,
          ),
          pendingTasksCount: 9,
          upcomingEventsCount: 6,
          unreadNotificationsCount: 10,
          recentActivities: [tRecentActivity],
        );
        when(
          () => mockGetDashboardData(any()),
        ).thenAnswer((_) async => Right(tUpdatedDashboardData));
        return bloc;
      },
      seed: () => HomeState(
        status: HomeStatus.loaded,
        currentTab: 1,
        dashboardData: tDashboardData,
      ),
      act: (bloc) => bloc.add(const HomeTabChangeRequested(tabIndex: 2)),
      expect: () => [
        HomeState(
          status: HomeStatus.loaded,
          currentTab: 2,
          dashboardData: tDashboardData,
        ),
        HomeState(
          status: HomeStatus.loaded,
          currentTab: 2,
          dashboardData: DashboardData(
            user: tUserSummary,
            friends: tFriendsSummary,
            expenses: const ExpenseSummary(
              totalGroupExpenses: 700.00,
              userShare: 220.00,
              pendingBillsCount: 4,
            ),
            pendingTasksCount: 9,
            upcomingEventsCount: 6,
            unreadNotificationsCount: 10,
            recentActivities: [tRecentActivity],
          ),
          refreshCount: 1,
        ),
      ],
      verify: (_) {
        verify(() => mockGetDashboardData(any())).called(1);
      },
    );

    blocTest<HomeBloc, HomeState>(
      'does not auto-refresh when returning to Home tab while data is fresh',
      build: () => bloc,
      seed: () => HomeState(
        status: HomeStatus.loaded,
        currentTab: 1,
        dashboardData: tDashboardData,
        lastLoadedAt: DateTime.now().subtract(const Duration(seconds: 5)),
      ),
      act: (bloc) => bloc.add(const HomeTabChangeRequested(tabIndex: 2)),
      expect: () => [
        HomeState(
          status: HomeStatus.loaded,
          currentTab: 2,
          dashboardData: tDashboardData,
        ),
      ],
      verify: (_) {
        verifyNever(() => mockGetDashboardData(any()));
      },
    );
  });

  group('HomeDashboardRequested', () {
    blocTest<HomeBloc, HomeState>(
      'emits [loading, loaded] when GetDashboardData returns successfully',
      build: () {
        when(
          () => mockGetDashboardData(any()),
        ).thenAnswer((_) async => Right(tDashboardData));
        return bloc;
      },
      act: (bloc) => bloc.add(const HomeDashboardRequested()),
      expect: () => [
        const HomeState(status: HomeStatus.loading),
        HomeState(status: HomeStatus.loaded, dashboardData: tDashboardData),
      ],
      verify: (_) {
        verify(() => mockGetDashboardData(any())).called(1);
      },
    );

    blocTest<HomeBloc, HomeState>(
      'emits [loading, error] when GetDashboardData fails with ServerFailure',
      build: () {
        when(() => mockGetDashboardData(any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: tErrorMessage)),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const HomeDashboardRequested()),
      expect: () => [
        const HomeState(status: HomeStatus.loading),
        const HomeState(status: HomeStatus.error, errorMessage: tErrorMessage),
      ],
      verify: (_) {
        verify(() => mockGetDashboardData(any())).called(1);
      },
    );

    blocTest<HomeBloc, HomeState>(
      'emits [loading, error] when GetDashboardData fails with NetworkFailure',
      build: () {
        when(
          () => mockGetDashboardData(any()),
        ).thenAnswer((_) async => const Left(NetworkFailure()));
        return bloc;
      },
      act: (bloc) => bloc.add(const HomeDashboardRequested()),
      expect: () => [
        const HomeState(status: HomeStatus.loading),
        const HomeState(
          status: HomeStatus.error,
          errorMessage: 'No internet connection',
        ),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'emits [loading, error] when GetDashboardData fails with CacheFailure',
      build: () {
        when(() => mockGetDashboardData(any())).thenAnswer(
          (_) async => const Left(CacheFailure(message: 'Cache error')),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const HomeDashboardRequested()),
      expect: () => [
        const HomeState(status: HomeStatus.loading),
        const HomeState(status: HomeStatus.error, errorMessage: 'Cache error'),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'preserves currentTab when loading dashboard data',
      build: () {
        when(
          () => mockGetDashboardData(any()),
        ).thenAnswer((_) async => Right(tDashboardData));
        return bloc;
      },
      seed: () => const HomeState(currentTab: 3),
      act: (bloc) => bloc.add(const HomeDashboardRequested()),
      expect: () => [
        const HomeState(status: HomeStatus.loading, currentTab: 3),
        HomeState(
          status: HomeStatus.loaded,
          currentTab: 3,
          dashboardData: tDashboardData,
        ),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'calls GetDashboardData with NoParams',
      build: () {
        when(
          () => mockGetDashboardData(any()),
        ).thenAnswer((_) async => Right(tDashboardData));
        return bloc;
      },
      act: (bloc) => bloc.add(const HomeDashboardRequested()),
      verify: (_) {
        final captured = verify(
          () => mockGetDashboardData(captureAny()),
        ).captured;
        expect(captured.first, isA<NoParams>());
      },
    );
  });

  group('HomeRefreshRequested', () {
    blocTest<HomeBloc, HomeState>(
      'emits [loaded] without loading state when refresh succeeds with new data',
      build: () {
        final tUpdatedDashboardData = DashboardData(
          user: tUserSummary,
          friends: tFriendsSummary,
          expenses: const ExpenseSummary(
            totalGroupExpenses: 550.00,
            userShare: 175.00,
            pendingBillsCount: 3,
          ),
          pendingTasksCount: 6,
          upcomingEventsCount: 4,
          unreadNotificationsCount: 8,
          recentActivities: [tRecentActivity],
        );
        when(
          () => mockGetDashboardData(any()),
        ).thenAnswer((_) async => Right(tUpdatedDashboardData));
        return bloc;
      },
      seed: () =>
          HomeState(status: HomeStatus.loaded, dashboardData: tDashboardData),
      act: (bloc) => bloc.add(const HomeRefreshRequested()),
      verify: (bloc) {
        verify(() => mockGetDashboardData(any())).called(1);
        expect(bloc.state.dashboardData!.pendingTasksCount, 6);
        expect(bloc.state.status, HomeStatus.loaded);
      },
    );

    blocTest<HomeBloc, HomeState>(
      'emits state with incremented refreshCount when refresh returns same data',
      build: () {
        when(
          () => mockGetDashboardData(any()),
        ).thenAnswer((_) async => Right(tDashboardData));
        return bloc;
      },
      seed: () =>
          HomeState(status: HomeStatus.loaded, dashboardData: tDashboardData),
      act: (bloc) => bloc.add(const HomeRefreshRequested()),
      expect: () => [
        HomeState(
          status: HomeStatus.loaded,
          dashboardData: tDashboardData,
          refreshCount: 1,
        ),
      ],
      verify: (_) {
        verify(() => mockGetDashboardData(any())).called(1);
      },
    );

    blocTest<HomeBloc, HomeState>(
      'emits [error] when refresh fails with ServerFailure',
      build: () {
        when(() => mockGetDashboardData(any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: tErrorMessage)),
        );
        return bloc;
      },
      seed: () =>
          HomeState(status: HomeStatus.loaded, dashboardData: tDashboardData),
      act: (bloc) => bloc.add(const HomeRefreshRequested()),
      expect: () => [
        HomeState(
          status: HomeStatus.error,
          dashboardData: tDashboardData,
          errorMessage: tErrorMessage,
          refreshCount: 1,
        ),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'emits [error] when refresh fails with NetworkFailure',
      build: () {
        when(
          () => mockGetDashboardData(any()),
        ).thenAnswer((_) async => const Left(NetworkFailure()));
        return bloc;
      },
      seed: () =>
          HomeState(status: HomeStatus.loaded, dashboardData: tDashboardData),
      act: (bloc) => bloc.add(const HomeRefreshRequested()),
      expect: () => [
        HomeState(
          status: HomeStatus.error,
          dashboardData: tDashboardData,
          errorMessage: 'No internet connection',
          refreshCount: 1,
        ),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'preserves currentTab when refreshing data with new data',
      build: () {
        final tUpdatedDashboardData = DashboardData(
          user: tUserSummary,
          friends: tFriendsSummary,
          expenses: const ExpenseSummary(
            totalGroupExpenses: 700.00,
            userShare: 250.00,
            pendingBillsCount: 4,
          ),
          pendingTasksCount: 8,
          upcomingEventsCount: 4,
          unreadNotificationsCount: 9,
          recentActivities: [tRecentActivity],
        );
        when(
          () => mockGetDashboardData(any()),
        ).thenAnswer((_) async => Right(tUpdatedDashboardData));
        return bloc;
      },
      seed: () => HomeState(
        status: HomeStatus.loaded,
        currentTab: 1,
        dashboardData: tDashboardData,
      ),
      act: (bloc) => bloc.add(const HomeRefreshRequested()),
      verify: (bloc) {
        expect(bloc.state.currentTab, 1);
        expect(bloc.state.status, HomeStatus.loaded);
        expect(bloc.state.dashboardData!.pendingTasksCount, 8);
      },
    );

    blocTest<HomeBloc, HomeState>(
      'updates dashboard data with new data on successful refresh',
      build: () {
        final tUpdatedDashboardData = DashboardData(
          user: tUserSummary,
          friends: tFriendsSummary,
          expenses: const ExpenseSummary(
            totalGroupExpenses: 600.00,
            userShare: 200.00,
            pendingBillsCount: 3,
          ),
          pendingTasksCount: 10,
          upcomingEventsCount: 5,
          unreadNotificationsCount: 12,
          recentActivities: [tRecentActivity],
        );
        when(
          () => mockGetDashboardData(any()),
        ).thenAnswer((_) async => Right(tUpdatedDashboardData));
        return bloc;
      },
      seed: () =>
          HomeState(status: HomeStatus.loaded, dashboardData: tDashboardData),
      act: (bloc) => bloc.add(const HomeRefreshRequested()),
      verify: (bloc) {
        expect(bloc.state.dashboardData!.pendingTasksCount, 10);
        expect(bloc.state.dashboardData!.upcomingEventsCount, 5);
        expect(bloc.state.dashboardData!.expenses.totalGroupExpenses, 600.00);
      },
    );

    blocTest<HomeBloc, HomeState>(
      'can refresh from initial state',
      build: () {
        when(
          () => mockGetDashboardData(any()),
        ).thenAnswer((_) async => Right(tDashboardData));
        return bloc;
      },
      act: (bloc) => bloc.add(const HomeRefreshRequested()),
      expect: () => [
        HomeState(
          status: HomeStatus.loaded,
          dashboardData: tDashboardData,
          refreshCount: 1,
        ),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'can refresh from error state',
      build: () {
        when(
          () => mockGetDashboardData(any()),
        ).thenAnswer((_) async => Right(tDashboardData));
        return bloc;
      },
      seed: () => const HomeState(
        status: HomeStatus.error,
        errorMessage: 'Previous error',
      ),
      act: (bloc) => bloc.add(const HomeRefreshRequested()),
      expect: () => [
        HomeState(
          status: HomeStatus.loaded,
          dashboardData: tDashboardData,
          refreshCount: 1,
        ),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'skips non-forced refresh when data is still fresh',
      build: () => bloc,
      seed: () => HomeState(
        status: HomeStatus.loaded,
        dashboardData: tDashboardData,
        lastLoadedAt: DateTime.now(),
      ),
      act: (bloc) => bloc.add(const HomeRefreshRequested()),
      expect: () => <HomeState>[],
      verify: (_) {
        verifyNever(() => mockGetDashboardData(any()));
      },
    );

    blocTest<HomeBloc, HomeState>(
      'force refresh bypasses freshness guard',
      build: () {
        when(
          () => mockGetDashboardData(any()),
        ).thenAnswer((_) async => Right(tDashboardData));
        return bloc;
      },
      seed: () => HomeState(
        status: HomeStatus.loaded,
        dashboardData: tDashboardData,
        lastLoadedAt: DateTime.now(),
      ),
      act: (bloc) => bloc.add(const HomeRefreshRequested(force: true)),
      expect: () => [
        HomeState(
          status: HomeStatus.loaded,
          dashboardData: tDashboardData,
          refreshCount: 1,
        ),
      ],
      verify: (_) {
        verify(() => mockGetDashboardData(any())).called(1);
      },
    );
  });

  group('HomeState convenience getters', () {
    test(
      'user getter returns dashboardData.user when dashboardData is not null',
      () {
        final state = HomeState(
          status: HomeStatus.loaded,
          dashboardData: tDashboardData,
        );
        expect(state.user, tUserSummary);
      },
    );

    test('user getter returns null when dashboardData is null', () {
      const state = HomeState(status: HomeStatus.initial);
      expect(state.user, isNull);
    });

    test(
      'friends getter returns dashboardData.friends when dashboardData is not null',
      () {
        final state = HomeState(
          status: HomeStatus.loaded,
          dashboardData: tDashboardData,
        );
        expect(state.friends, tFriendsSummary);
      },
    );

    test('friends getter returns null when dashboardData is null', () {
      const state = HomeState(status: HomeStatus.initial);
      expect(state.friends, isNull);
    });

    test(
      'expenses getter returns dashboardData.expenses when dashboardData is not null',
      () {
        final state = HomeState(
          status: HomeStatus.loaded,
          dashboardData: tDashboardData,
        );
        expect(state.expenses, tExpenseSummary);
      },
    );

    test('expenses getter returns null when dashboardData is null', () {
      const state = HomeState(status: HomeStatus.initial);
      expect(state.expenses, isNull);
    });

    test('pendingTasksCount returns value from dashboardData', () {
      final state = HomeState(
        status: HomeStatus.loaded,
        dashboardData: tDashboardData,
      );
      expect(state.pendingTasksCount, 5);
    });

    test('pendingTasksCount returns 0 when dashboardData is null', () {
      const state = HomeState(status: HomeStatus.initial);
      expect(state.pendingTasksCount, 0);
    });

    test('upcomingEventsCount returns value from dashboardData', () {
      final state = HomeState(
        status: HomeStatus.loaded,
        dashboardData: tDashboardData,
      );
      expect(state.upcomingEventsCount, 3);
    });

    test('upcomingEventsCount returns 0 when dashboardData is null', () {
      const state = HomeState(status: HomeStatus.initial);
      expect(state.upcomingEventsCount, 0);
    });

    test('unreadNotificationsCount returns value from dashboardData', () {
      final state = HomeState(
        status: HomeStatus.loaded,
        dashboardData: tDashboardData,
      );
      expect(state.unreadNotificationsCount, 7);
    });

    test('unreadNotificationsCount returns 0 when dashboardData is null', () {
      const state = HomeState(status: HomeStatus.initial);
      expect(state.unreadNotificationsCount, 0);
    });

    test('recentActivities returns list from dashboardData', () {
      final state = HomeState(
        status: HomeStatus.loaded,
        dashboardData: tDashboardData,
      );
      expect(state.recentActivities, [tRecentActivity]);
    });

    test('recentActivities returns empty list when dashboardData is null', () {
      const state = HomeState(status: HomeStatus.initial);
      expect(state.recentActivities, isEmpty);
    });
  });

  group('HomeState copyWith', () {
    test('copyWith returns same object when no parameters are passed', () {
      final state = HomeState(
        status: HomeStatus.loaded,
        currentTab: 3,
        dashboardData: tDashboardData,
        errorMessage: 'error',
      );
      final newState = state.copyWith();
      expect(newState.status, state.status);
      expect(newState.currentTab, state.currentTab);
      expect(newState.dashboardData, state.dashboardData);
      // Note: errorMessage is intentionally nulled in copyWith if not provided
    });

    test('copyWith updates only specified fields', () {
      final state = HomeState(
        status: HomeStatus.loaded,
        currentTab: 2,
        dashboardData: tDashboardData,
      );
      final newState = state.copyWith(currentTab: 4);
      expect(newState.status, HomeStatus.loaded);
      expect(newState.currentTab, 4);
      expect(newState.dashboardData, tDashboardData);
    });

    test('copyWith can update all fields', () {
      const state = HomeState();
      final newState = state.copyWith(
        status: HomeStatus.error,
        currentTab: 1,
        dashboardData: tDashboardData,
        errorMessage: 'New error',
      );
      expect(newState.status, HomeStatus.error);
      expect(newState.currentTab, 1);
      expect(newState.dashboardData, tDashboardData);
      expect(newState.errorMessage, 'New error');
    });
  });

  group('HomeEvent equality', () {
    test('HomeTabChangeRequested events with same tabIndex are equal', () {
      const event1 = HomeTabChangeRequested(tabIndex: 1);
      const event2 = HomeTabChangeRequested(tabIndex: 1);
      expect(event1, equals(event2));
    });

    test(
      'HomeTabChangeRequested events with different tabIndex are not equal',
      () {
        const event1 = HomeTabChangeRequested(tabIndex: 1);
        const event2 = HomeTabChangeRequested(tabIndex: 2);
        expect(event1, isNot(equals(event2)));
      },
    );

    test('HomeDashboardRequested events are equal', () {
      const event1 = HomeDashboardRequested();
      const event2 = HomeDashboardRequested();
      expect(event1, equals(event2));
    });

    test('HomeRefreshRequested events are equal', () {
      const event1 = HomeRefreshRequested();
      const event2 = HomeRefreshRequested();
      expect(event1, equals(event2));
    });

    test('HomeRefreshRequested events with different force are not equal', () {
      const event1 = HomeRefreshRequested(force: false);
      const event2 = HomeRefreshRequested(force: true);
      expect(event1, isNot(equals(event2)));
    });

    test('Different event types are not equal', () {
      const tabEvent = HomeTabChangeRequested(tabIndex: 1);
      const dashboardEvent = HomeDashboardRequested();
      const refreshEvent = HomeRefreshRequested();
      expect(tabEvent, isNot(equals(dashboardEvent)));
      expect(dashboardEvent, isNot(equals(refreshEvent)));
      expect(tabEvent, isNot(equals(refreshEvent)));
    });
  });

  group('HomeState equality', () {
    test('HomeStates with same values are equal', () {
      final state1 = HomeState(
        status: HomeStatus.loaded,
        currentTab: 2,
        dashboardData: tDashboardData,
        errorMessage: null,
      );
      final state2 = HomeState(
        status: HomeStatus.loaded,
        currentTab: 2,
        dashboardData: tDashboardData,
        errorMessage: null,
      );
      expect(state1, equals(state2));
    });

    test('HomeStates with different status are not equal', () {
      final state1 = HomeState(
        status: HomeStatus.loaded,
        dashboardData: tDashboardData,
      );
      final state2 = HomeState(
        status: HomeStatus.loading,
        dashboardData: tDashboardData,
      );
      expect(state1, isNot(equals(state2)));
    });

    test('HomeStates with different currentTab are not equal', () {
      const state1 = HomeState(currentTab: 1);
      const state2 = HomeState(currentTab: 2);
      expect(state1, isNot(equals(state2)));
    });

    test('HomeStates with different errorMessage are not equal', () {
      const state1 = HomeState(errorMessage: 'Error 1');
      const state2 = HomeState(errorMessage: 'Error 2');
      expect(state1, isNot(equals(state2)));
    });
  });

  group('UserSummary', () {
    test('firstName returns first part of name', () {
      expect(tUserSummary.firstName, 'John');
    });

    test('firstName returns full name when no space', () {
      const singleNameUser = UserSummary(
        id: 'user-1',
        name: 'Madonna',
        username: 'madonna',
        email: 'madonna@example.com',
        avatarInitial: 'M',
      );
      expect(singleNameUser.firstName, 'Madonna');
    });
  });

  group('Integration tests', () {
    blocTest<HomeBloc, HomeState>(
      'can change tab after loading dashboard data',
      build: () {
        when(
          () => mockGetDashboardData(any()),
        ).thenAnswer((_) async => Right(tDashboardData));
        return bloc;
      },
      act: (bloc) async {
        bloc.add(const HomeDashboardRequested());
        await Future.delayed(const Duration(milliseconds: 100));
        bloc.add(const HomeTabChangeRequested(tabIndex: 1));
      },
      expect: () => [
        const HomeState(status: HomeStatus.loading),
        HomeState(status: HomeStatus.loaded, dashboardData: tDashboardData),
        HomeState(
          status: HomeStatus.loaded,
          currentTab: 1,
          dashboardData: tDashboardData,
        ),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'can refresh after changing tab with new data',
      build: () {
        final tUpdatedDashboardData = DashboardData(
          user: tUserSummary,
          friends: tFriendsSummary,
          expenses: const ExpenseSummary(
            totalGroupExpenses: 800.00,
            userShare: 300.00,
            pendingBillsCount: 5,
          ),
          pendingTasksCount: 15,
          upcomingEventsCount: 8,
          unreadNotificationsCount: 20,
          recentActivities: [tRecentActivity],
        );
        when(
          () => mockGetDashboardData(any()),
        ).thenAnswer((_) async => Right(tUpdatedDashboardData));
        return bloc;
      },
      seed: () => HomeState(
        status: HomeStatus.loaded,
        currentTab: 3,
        dashboardData: tDashboardData,
      ),
      act: (bloc) {
        bloc.add(const HomeTabChangeRequested(tabIndex: 1));
        bloc.add(const HomeRefreshRequested());
      },
      verify: (bloc) {
        expect(bloc.state.currentTab, 1);
        expect(bloc.state.status, HomeStatus.loaded);
        expect(bloc.state.dashboardData!.pendingTasksCount, 15);
      },
    );

    blocTest<HomeBloc, HomeState>(
      'can recover from error by refreshing',
      build: () {
        var callCount = 0;
        when(() => mockGetDashboardData(any())).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            return const Left(ServerFailure(message: 'First call failed'));
          }
          return Right(tDashboardData);
        });
        return bloc;
      },
      act: (bloc) async {
        bloc.add(const HomeDashboardRequested());
        await Future.delayed(const Duration(milliseconds: 100));
        bloc.add(const HomeRefreshRequested());
      },
      expect: () => [
        const HomeState(status: HomeStatus.loading),
        const HomeState(
          status: HomeStatus.error,
          errorMessage: 'First call failed',
        ),
        HomeState(
          status: HomeStatus.loaded,
          dashboardData: tDashboardData,
          refreshCount: 1,
        ),
      ],
    );
  });

  group('HomeClearedRequested', () {
    blocTest<HomeBloc, HomeState>(
      'resets state to initial when home is cleared',
      build: () => bloc,
      seed: () => HomeState(
        status: HomeStatus.error,
        currentTab: 4,
        dashboardData: tDashboardData,
        errorMessage: 'User not authenticated',
        refreshCount: 2,
      ),
      act: (bloc) => bloc.add(const HomeClearedRequested()),
      expect: () => [const HomeState()],
    );
  });
}
