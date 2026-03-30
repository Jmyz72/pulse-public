import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/core/usecases/usecase.dart';
import 'package:pulse/features/home/domain/entities/dashboard_data.dart';
import 'package:pulse/features/home/domain/repositories/home_repository.dart';
import 'package:pulse/features/home/domain/usecases/get_dashboard_data.dart';

class MockHomeRepository extends Mock implements HomeRepository {}

void main() {
  late GetDashboardData usecase;
  late MockHomeRepository mockHomeRepository;

  setUp(() {
    mockHomeRepository = MockHomeRepository();
    usecase = GetDashboardData(mockHomeRepository);
  });

  const tUserSummary = UserSummary(
    id: '1',
    name: 'Test User',
    username: 'testuser',
    email: 'test@example.com',
    avatarInitial: 'T',
  );

  const tFriendsSummary = FriendsSummary(friendCount: 3, friends: []);

  const tExpenseSummary = ExpenseSummary(
    totalGroupExpenses: 500.0,
    userShare: 166.67,
    pendingBillsCount: 2,
  );

  const tDashboardData = DashboardData(
    user: tUserSummary,
    friends: tFriendsSummary,
    expenses: tExpenseSummary,
    pendingTasksCount: 5,
    upcomingEventsCount: 3,
    unreadNotificationsCount: 2,
    recentActivities: [],
  );

  test('should return DashboardData when call is successful', () async {
    // arrange
    when(
      () => mockHomeRepository.getDashboardData(),
    ).thenAnswer((_) async => const Right(tDashboardData));

    // act
    final result = await usecase(const NoParams());

    // assert
    expect(result, const Right(tDashboardData));
    verify(() => mockHomeRepository.getDashboardData()).called(1);
    verifyNoMoreInteractions(mockHomeRepository);
  });

  test('should return NetworkFailure when there is no internet', () async {
    // arrange
    when(
      () => mockHomeRepository.getDashboardData(),
    ).thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(const NoParams());

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockHomeRepository.getDashboardData()).called(1);
  });

  test('should return AuthFailure when user is not authenticated', () async {
    // arrange
    when(() => mockHomeRepository.getDashboardData()).thenAnswer(
      (_) async => const Left(AuthFailure(message: 'User not authenticated')),
    );

    // act
    final result = await usecase(const NoParams());

    // assert
    expect(result, const Left(AuthFailure(message: 'User not authenticated')));
    verify(() => mockHomeRepository.getDashboardData()).called(1);
  });

  test('should return ServerFailure when server error occurs', () async {
    // arrange
    when(() => mockHomeRepository.getDashboardData()).thenAnswer(
      (_) async => const Left(ServerFailure(message: 'Internal server error')),
    );

    // act
    final result = await usecase(const NoParams());

    // assert
    expect(result, const Left(ServerFailure(message: 'Internal server error')));
  });
}
