import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/constants/app_routes.dart';
import 'package:pulse/features/auth/domain/entities/google_auth_result.dart';
import 'package:pulse/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse/features/auth/presentation/screens/google_username_setup_screen.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class FakeAuthEvent extends Fake implements AuthEvent {}

void main() {
  const googleProfile = GooglePendingProfileData(
    email: 'test@example.com',
    displayName: 'John Doe',
    photoUrl: 'https://example.com/avatar.jpg',
  );

  setUpAll(() {
    registerFallbackValue(FakeAuthEvent());
  });

  Future<void> pumpScreen(
    WidgetTester tester,
    MockAuthBloc bloc, {
    Stream<AuthState>? stream,
    required AuthState initialState,
  }) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    when(() => bloc.state).thenReturn(initialState);
    if (stream != null) {
      whenListen(bloc, stream, initialState: initialState);
    }

    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: bloc,
        child: MaterialApp(
          routes: {
            AppRoutes.authIntro: (_) => const Scaffold(body: Text('Intro')),
            AppRoutes.login: (_) => const Scaffold(body: Text('Login')),
            AppRoutes.home: (_) => const Scaffold(body: Text('Home')),
            AppRoutes.profileCompletion: (_) =>
                const Scaffold(body: Text('Profile Completion')),
          },
          home: const GoogleUsernameSetupScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder fieldByKey(String key) {
    return find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byType(EditableText),
    );
  }

  testWidgets('renders Google profile details and username suggestions', (
    tester,
  ) async {
    final bloc = MockAuthBloc();

    await pumpScreen(
      tester,
      bloc,
      initialState: const AuthState(
        status: AuthStatus.usernameSetupRequired,
        pendingGoogleProfileData: googleProfile,
      ),
    );

    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('test@example.com'), findsOneWidget);
    expect(find.text('john_doe'), findsOneWidget);
    expect(find.text('johndoe'), findsOneWidget);
  });

  testWidgets('dispatches onboarding completion when username is available', (
    tester,
  ) async {
    final bloc = MockAuthBloc();
    final states = StreamController<AuthState>();
    addTearDown(states.close);

    await pumpScreen(
      tester,
      bloc,
      initialState: const AuthState(
        status: AuthStatus.usernameSetupRequired,
        pendingGoogleProfileData: googleProfile,
      ),
      stream: states.stream,
    );

    await tester.enterText(fieldByKey('google-username-field'), 'john_doe');
    await tester.pump(const Duration(milliseconds: 500));

    const availableState = AuthState(
      status: AuthStatus.usernameSetupRequired,
      pendingGoogleProfileData: googleProfile,
      usernameAvailable: true,
    );
    when(() => bloc.state).thenReturn(availableState);
    states.add(availableState);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('google-username-continue')));
    await tester.pump();

    verify(
      () => bloc.add(
        const AuthGoogleUsernameCompletionRequested(username: 'john_doe'),
      ),
    ).called(1);
  });

  testWidgets('dispatches onboarding completion with password when provided', (
    tester,
  ) async {
    final bloc = MockAuthBloc();
    final states = StreamController<AuthState>();
    addTearDown(states.close);

    await pumpScreen(
      tester,
      bloc,
      initialState: const AuthState(
        status: AuthStatus.usernameSetupRequired,
        pendingGoogleProfileData: googleProfile,
      ),
      stream: states.stream,
    );

    await tester.enterText(fieldByKey('google-username-field'), 'john_doe');
    await tester.pump(const Duration(milliseconds: 500));

    const availableState = AuthState(
      status: AuthStatus.usernameSetupRequired,
      pendingGoogleProfileData: googleProfile,
      usernameAvailable: true,
    );
    when(() => bloc.state).thenReturn(availableState);
    states.add(availableState);
    await tester.pumpAndSettle();

    await tester.enterText(fieldByKey('google-password-field'), 'Password123!');
    await tester.pump();
    await tester.enterText(
      fieldByKey('google-confirm-password-field'),
      'Password123!',
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('google-username-continue')));
    await tester.pump();

    verify(
      () => bloc.add(
        const AuthGoogleUsernameCompletionRequested(
          username: 'john_doe',
          password: 'Password123!',
        ),
      ),
    ).called(1);
  });

  testWidgets('cancel action dispatches Google onboarding cancel', (
    tester,
  ) async {
    final bloc = MockAuthBloc();

    await pumpScreen(
      tester,
      bloc,
      initialState: const AuthState(
        status: AuthStatus.usernameSetupRequired,
        pendingGoogleProfileData: googleProfile,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('google-username-cancel')));
    await tester.pump();

    verify(() => bloc.add(AuthGoogleOnboardingCancelled())).called(1);
  });

  testWidgets('navigates to login when onboarding is canceled', (tester) async {
    final bloc = MockAuthBloc();
    final states = StreamController<AuthState>();
    addTearDown(states.close);

    await pumpScreen(
      tester,
      bloc,
      initialState: const AuthState(
        status: AuthStatus.usernameSetupRequired,
        pendingGoogleProfileData: googleProfile,
      ),
      stream: states.stream,
    );

    states.add(const AuthState(status: AuthStatus.unauthenticated));
    await tester.pumpAndSettle();

    expect(find.text('Intro'), findsOneWidget);
  });
}
