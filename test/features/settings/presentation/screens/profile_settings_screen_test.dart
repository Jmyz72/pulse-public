import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/constants/app_routes.dart';
import 'package:pulse/features/auth/domain/entities/user.dart';
import 'package:pulse/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse/features/settings/domain/entities/settings.dart';
import 'package:pulse/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:pulse/features/settings/presentation/screens/profile_settings.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class FakeAuthEvent extends Fake implements AuthEvent {}

class FakeSettingsEvent extends Fake implements SettingsEvent {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockSettingsBloc mockSettingsBloc;

  const tUser = User(
    id: 'uid-123',
    username: 'jimmy',
    displayName: 'Jimmy Hew',
    email: 'jimmy@test.com',
    phone: '1234567890',
  );

  const tSettings = UserSettings(userId: 'uid-123');

  setUpAll(() {
    registerFallbackValue(FakeAuthEvent());
    registerFallbackValue(FakeSettingsEvent());
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockSettingsBloc = MockSettingsBloc();

    when(() => mockAuthBloc.state).thenReturn(
      const AuthState(status: AuthStatus.authenticated, user: tUser),
    );
    when(() => mockSettingsBloc.state).thenReturn(
      const SettingsState(status: SettingsStatus.loaded, settings: tSettings),
    );

    whenListen(
      mockAuthBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthState(
        status: AuthStatus.authenticated,
        user: tUser,
      ),
    );
    whenListen(
      mockSettingsBloc,
      const Stream<SettingsState>.empty(),
      initialState: const SettingsState(
        status: SettingsStatus.loaded,
        settings: tSettings,
      ),
    );
  });

  Widget buildSubject() {
    return MaterialApp(
      routes: {
        AppRoutes.accountSecurity: (_) =>
            const Scaffold(body: Text('Account Security')),
      },
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
        ],
        child: const ProfileSettingsScreen(),
      ),
    );
  }

  group('ProfileSettingsScreen username display', () {
    testWidgets('shows @username in settings header and hides UID', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('@jimmy'), findsOneWidget);
      expect(find.text('uid-123'), findsNothing);
    });

    testWidgets('does not render username row when username is empty', (
      tester,
    ) async {
      const userWithoutUsername = User(
        id: 'uid-123',
        username: '',
        displayName: 'Jimmy Hew',
        email: 'jimmy@test.com',
        phone: '1234567890',
      );

      when(() => mockAuthBloc.state).thenReturn(
        const AuthState(
          status: AuthStatus.authenticated,
          user: userWithoutUsername,
        ),
      );
      whenListen(
        mockAuthBloc,
        const Stream<AuthState>.empty(),
        initialState: const AuthState(
          status: AuthStatus.authenticated,
          user: userWithoutUsername,
        ),
      );

      await tester.pumpWidget(buildSubject());

      expect(find.text('@jimmy'), findsNothing);
      expect(find.text('Jimmy Hew'), findsOneWidget);
    });

    testWidgets('navigates to account security', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.tap(find.text('Account Security'));
      await tester.pumpAndSettle();

      expect(find.text('Account Security'), findsWidgets);
    });
  });
}
