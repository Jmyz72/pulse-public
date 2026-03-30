import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/constants/app_routes.dart';
import 'package:pulse/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse/features/auth/presentation/screens/login_screen.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class FakeAuthEvent extends Fake implements AuthEvent {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAuthEvent());
  });

  Future<void> pumpLoginScreen(WidgetTester tester, MockAuthBloc bloc) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    when(
      () => bloc.state,
    ).thenReturn(const AuthState(status: AuthStatus.unauthenticated));

    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: bloc,
        child: MaterialApp(
          routes: {
            AppRoutes.authIntro: (_) => const Scaffold(body: Text('Intro')),
            AppRoutes.login: (_) => const LoginScreen(),
            AppRoutes.register: (_) => const Scaffold(body: Text('Register')),
            AppRoutes.forgotPassword: (_) =>
                const Scaffold(body: Text('Forgot Password')),
          },
          home: const LoginScreen(),
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

  testWidgets('shows a back button on sign in', (tester) async {
    final bloc = MockAuthBloc();

    await pumpLoginScreen(tester, bloc);

    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
  });

  testWidgets('back button navigates to auth intro', (tester) async {
    final bloc = MockAuthBloc();

    await pumpLoginScreen(tester, bloc);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Intro'), findsOneWidget);
  });

  testWidgets('dispatches email-link request from the login screen', (
    tester,
  ) async {
    final bloc = MockAuthBloc();

    await pumpLoginScreen(tester, bloc);
    await tester.enterText(fieldByKey('login-email'), 'test@example.com');
    await tester.tap(find.byKey(const ValueKey('login-email-link')));
    await tester.pump();

    verify(
      () => bloc.add(
        const AuthEmailLinkSignInRequested(email: 'test@example.com'),
      ),
    ).called(1);
  });

  testWidgets('shows email-link completion state when a pending link exists', (
    tester,
  ) async {
    final bloc = MockAuthBloc();
    when(() => bloc.state).thenReturn(
      const AuthState(
        status: AuthStatus.unauthenticated,
        pendingEmailLink: 'https://example.invalid/__/auth/action',
      ),
    );

    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: bloc,
        child: MaterialApp(
          routes: {
            AppRoutes.authIntro: (_) => const Scaffold(body: Text('Intro')),
            AppRoutes.login: (_) => const LoginScreen(),
            AppRoutes.register: (_) => const Scaffold(body: Text('Register')),
            AppRoutes.forgotPassword: (_) =>
                const Scaffold(body: Text('Forgot Password')),
          },
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Finish sign-in'), findsOneWidget);
    expect(find.text('Forgot password?'), findsNothing);
    expect(find.byKey(const ValueKey('login-email-link')), findsNothing);
  });
}
