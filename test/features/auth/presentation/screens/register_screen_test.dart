import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse/core/constants/app_routes.dart';
import 'package:pulse/features/auth/domain/entities/password_policy_validation.dart';
import 'package:pulse/features/auth/domain/entities/user.dart';
import 'package:pulse/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:pulse/features/auth/presentation/screens/register_screen.dart';
import 'package:pulse/shared/widgets/glass_text_field.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class FakeAuthEvent extends Fake implements AuthEvent {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAuthEvent());
  });

  const email = 'test@example.com';
  const displayName = 'John Doe';
  const password = 'Password123!';
  const username = 'john_doe';
  const user = User(
    id: '1',
    username: username,
    displayName: displayName,
    email: email,
    phone: '',
  );
  const validPasswordValidation = PasswordPolicyValidation(
    isValid: true,
    minPasswordLength: 8,
    maxPasswordLength: 4096,
    requiresLowercase: true,
    requiresUppercase: true,
    requiresDigits: true,
    requiresSymbols: true,
    meetsMinPasswordLength: true,
    meetsMaxPasswordLength: true,
    meetsLowercaseRequirement: true,
    meetsUppercaseRequirement: true,
    meetsDigitsRequirement: true,
    meetsSymbolsRequirement: true,
  );

  Future<void> pumpRegisterScreen(
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
            AppRoutes.login: (_) => const Scaffold(body: Text('Login Screen')),
            AppRoutes.register: (_) =>
                const Scaffold(body: Text('Register Screen')),
            AppRoutes.emailVerification: (_) => const EmailVerificationScreen(),
          },
          home: const RegisterScreen(),
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

  testWidgets('step 1 blocks advance until fields are valid', (tester) async {
    final bloc = MockAuthBloc();
    const initialState = AuthState(passwordValidation: validPasswordValidation);

    await pumpRegisterScreen(tester, bloc, initialState: initialState);

    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(find.text('Choose your username.'), findsNothing);
    expect(find.byKey(const ValueKey('username-step')), findsNothing);
  });

  testWidgets('step 2 shows username suggestions and fills the field', (
    tester,
  ) async {
    final bloc = MockAuthBloc();
    final states = StreamController<AuthState>();
    addTearDown(states.close);

    await pumpRegisterScreen(
      tester,
      bloc,
      initialState: const AuthState(
        passwordValidation: validPasswordValidation,
      ),
      stream: states.stream,
    );

    await tester.enterText(fieldByKey('register-display-name'), displayName);
    await tester.enterText(fieldByKey('register-email'), email);
    await tester.enterText(fieldByKey('register-password'), password);
    await tester.enterText(fieldByKey('register-confirm-password'), password);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Choose your username.'), findsOneWidget);
    expect(find.text('john_doe'), findsOneWidget);
    expect(find.text('johndoe'), findsOneWidget);
    expect(find.text('john_doe1'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('username-suggestion-john_doe')),
    );
    await tester.pump();

    final usernameField = tester.widget<GlassTextField>(
      find.byKey(const ValueKey('register-username')),
    );
    expect(usernameField.controller?.text, username);
    verify(
      () => bloc.add(
        any(
          that: isA<AuthUsernameCheckRequested>().having(
            (event) => event.username,
            'username',
            username,
          ),
        ),
      ),
    ).called(1);
  });

  testWidgets('username checking and availability states render inline', (
    tester,
  ) async {
    final bloc = MockAuthBloc();
    final states = StreamController<AuthState>();
    addTearDown(states.close);

    await pumpRegisterScreen(
      tester,
      bloc,
      initialState: const AuthState(
        passwordValidation: validPasswordValidation,
      ),
      stream: states.stream,
    );

    await tester.enterText(fieldByKey('register-display-name'), displayName);
    await tester.enterText(fieldByKey('register-email'), email);
    await tester.enterText(fieldByKey('register-password'), password);
    await tester.enterText(fieldByKey('register-confirm-password'), password);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.enterText(fieldByKey('register-username'), username);
    await tester.pump(const Duration(milliseconds: 500));
    states.add(
      const AuthState(
        passwordValidation: validPasswordValidation,
        isCheckingUsername: true,
      ),
    );
    await tester.pump();
    expect(find.text('Checking availability'), findsOneWidget);

    states.add(
      const AuthState(
        passwordValidation: validPasswordValidation,
        usernameAvailable: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Username available'), findsOneWidget);

    await tester.enterText(fieldByKey('register-username'), 'taken_user');
    await tester.pump(const Duration(milliseconds: 500));
    states.add(
      const AuthState(
        passwordValidation: validPasswordValidation,
        isCheckingUsername: true,
      ),
    );
    await tester.pump();

    states.add(
      const AuthState(
        passwordValidation: validPasswordValidation,
        usernameAvailable: false,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Username taken'), findsOneWidget);
  });

  testWidgets('successful registration navigates to verification screen', (
    tester,
  ) async {
    final bloc = MockAuthBloc();
    final states = StreamController<AuthState>();
    addTearDown(states.close);

    await pumpRegisterScreen(
      tester,
      bloc,
      initialState: const AuthState(
        passwordValidation: validPasswordValidation,
      ),
      stream: states.stream,
    );

    await tester.enterText(fieldByKey('register-display-name'), displayName);
    await tester.enterText(fieldByKey('register-email'), email);
    await tester.enterText(fieldByKey('register-password'), password);
    await tester.enterText(fieldByKey('register-confirm-password'), password);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    states.add(const AuthState(passwordValidation: validPasswordValidation));
    await tester.enterText(fieldByKey('register-username'), username);
    await tester.pump(const Duration(milliseconds: 500));
    states.add(
      const AuthState(
        passwordValidation: validPasswordValidation,
        usernameAvailable: true,
      ),
    );
    await tester.pumpAndSettle();

    states.add(
      const AuthState(
        status: AuthStatus.loading,
        passwordValidation: validPasswordValidation,
        usernameAvailable: true,
      ),
    );
    await tester.pump();
    states.add(
      const AuthState(
        status: AuthStatus.emailVerificationSent,
        user: user,
        passwordValidation: validPasswordValidation,
        usernameAvailable: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(EmailVerificationScreen), findsOneWidget);
    expect(find.text(email), findsOneWidget);
  });
}
