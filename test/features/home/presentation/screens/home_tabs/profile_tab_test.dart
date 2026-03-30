import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/constants/app_routes.dart';
import 'package:pulse/features/auth/domain/entities/user.dart' as auth;
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse/features/home/domain/entities/dashboard_data.dart';
import 'package:pulse/features/home/presentation/screens/home_tabs/profile_tab.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class FakeAuthEvent extends Fake implements AuthEvent {}

void main() {
  late MockAuthBloc mockAuthBloc;

  const tUser = UserSummary(
    id: 'u1',
    name: 'Jimmy Hew',
    username: 'jimmy',
    email: 'jimmy@test.com',
    avatarInitial: 'J',
  );

  setUpAll(() {
    registerFallbackValue(FakeAuthEvent());
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    when(() => mockAuthBloc.state).thenReturn(
      const AuthState(
        status: AuthStatus.authenticated,
        user: auth.User(
          id: 'auth-1',
          username: 'authjimmy',
          displayName: 'Auth Jimmy',
          email: 'auth@test.com',
          phone: '',
        ),
      ),
    );
    whenListen(
      mockAuthBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthState(
        status: AuthStatus.authenticated,
        user: auth.User(
          id: 'auth-1',
          username: 'authjimmy',
          displayName: 'Auth Jimmy',
          email: 'auth@test.com',
          phone: '',
        ),
      ),
    );
  });

  Widget buildSubject({UserSummary? user}) {
    return MaterialApp(
      routes: {
        AppRoutes.editProfile: (_) =>
            const Scaffold(body: Text('Edit Profile')),
        AppRoutes.notifications: (_) =>
            const Scaffold(body: Text('Notifications')),
        AppRoutes.friends: (_) => const Scaffold(body: Text('My Friends')),
        AppRoutes.timetable: (_) => const Scaffold(body: Text('Timetable')),
        AppRoutes.settings: (_) => const Scaffold(body: Text('Settings')),
      },
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: Scaffold(body: ProfileTab(user: user)),
      ),
    );
  }

  Future<void> pumpStagger(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 700));
  }

  group('ProfileTab username display', () {
    testWidgets('shows @username when available', (tester) async {
      await tester.pumpWidget(buildSubject(user: tUser));
      await pumpStagger(tester);

      expect(find.text('@jimmy'), findsOneWidget);
      expect(find.text('Jimmy Hew'), findsOneWidget);
      expect(find.text('jimmy@test.com'), findsOneWidget);
    });

    testWidgets('hides username row when username is empty', (tester) async {
      const userWithoutUsername = UserSummary(
        id: 'u1',
        name: 'Jimmy Hew',
        username: '',
        email: 'jimmy@test.com',
        avatarInitial: 'J',
      );

      await tester.pumpWidget(buildSubject(user: userWithoutUsername));
      await pumpStagger(tester);

      expect(find.text('@jimmy'), findsNothing);
      expect(find.text('Jimmy Hew'), findsOneWidget);
      expect(find.text('jimmy@test.com'), findsOneWidget);
    });

    testWidgets('falls back to AuthBloc user when dashboard user is absent', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await pumpStagger(tester);

      expect(find.text('Auth Jimmy'), findsOneWidget);
      expect(find.text('@authjimmy'), findsOneWidget);
      expect(find.text('auth@test.com'), findsOneWidget);
    });

    testWidgets('renders personal menu items and hides old house content', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(user: tUser));
      await pumpStagger(tester);

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('My Friends'), findsOneWidget);
      expect(find.text('Timetable'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('House Feed'), findsNothing);
      expect(find.text('Living Space'), findsNothing);
    });

    testWidgets('navigates from menu items', (tester) async {
      await tester.pumpWidget(buildSubject(user: tUser));
      await pumpStagger(tester);

      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();
      expect(find.text('Notifications'), findsWidgets);
    });

    testWidgets('dispatches logout request after confirmation', (tester) async {
      await tester.pumpWidget(buildSubject(user: tUser));
      await pumpStagger(tester);

      final logoutButton = find.widgetWithText(OutlinedButton, 'Logout');
      await tester.dragUntilVisible(
        logoutButton,
        find.byType(CustomScrollView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      await tester.tap(logoutButton);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Logout'));
      await tester.pumpAndSettle();

      verify(() => mockAuthBloc.add(AuthLogoutRequested())).called(1);
    });
  });
}
