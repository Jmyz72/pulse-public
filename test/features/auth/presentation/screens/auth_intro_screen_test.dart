import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/constants/app_routes.dart';
import 'package:pulse/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse/features/auth/presentation/screens/auth_intro_screen.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class FakeAuthEvent extends Fake implements AuthEvent {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAuthEvent());
  });

  Future<void> pumpScreen(
    WidgetTester tester,
    MockAuthBloc bloc, {
    Stream<AuthState>? stream,
    AuthState initialState = const AuthState(
      status: AuthStatus.unauthenticated,
    ),
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
            AppRoutes.authIntro: (_) => const AuthIntroScreen(),
            AppRoutes.login: (_) => const Scaffold(body: Text('Login')),
            AppRoutes.register: (_) => const Scaffold(body: Text('Register')),
            AppRoutes.home: (_) => const Scaffold(body: Text('Home')),
          },
          home: const AuthIntroScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows intro actions', (tester) async {
    final bloc = MockAuthBloc();

    await pumpScreen(tester, bloc);

    expect(find.text('Pick an entry point'), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-intro-sign-in')), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-intro-register')), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-intro-google')), findsOneWidget);
  });

  testWidgets('sign in action navigates to login', (tester) async {
    final bloc = MockAuthBloc();

    await pumpScreen(tester, bloc);
    await tester.tap(find.byKey(const ValueKey('auth-intro-sign-in')));
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('register action navigates to register', (tester) async {
    final bloc = MockAuthBloc();

    await pumpScreen(tester, bloc);
    await tester.tap(find.byKey(const ValueKey('auth-intro-register')));
    await tester.pumpAndSettle();

    expect(find.text('Register'), findsOneWidget);
  });

  testWidgets('google action dispatches sign-in event', (tester) async {
    final bloc = MockAuthBloc();

    await pumpScreen(tester, bloc);
    await tester.tap(find.byKey(const ValueKey('auth-intro-google')));
    await tester.pump();

    verify(() => bloc.add(AuthGoogleSignInRequested())).called(1);
  });

  testWidgets('authenticated state navigates to home', (tester) async {
    final bloc = MockAuthBloc();
    final states = StreamController<AuthState>();
    addTearDown(states.close);

    await pumpScreen(tester, bloc, stream: states.stream);

    states.add(const AuthState(status: AuthStatus.authenticated));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });
}
