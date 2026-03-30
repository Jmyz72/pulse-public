import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/auth/domain/entities/auth_security.dart';
import 'package:pulse/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse/features/settings/presentation/screens/account_security_screen.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class FakeAuthEvent extends Fake implements AuthEvent {}

void main() {
  const googleOnlySecurity = AuthSecurity(
    email: 'jimmy@test.com',
    hasPasswordProvider: false,
    hasGoogleProvider: true,
    emailVerified: true,
  );

  const passwordEnabledSecurity = AuthSecurity(
    email: 'jimmy@test.com',
    hasPasswordProvider: true,
    hasGoogleProvider: true,
    emailVerified: true,
  );

  setUpAll(() {
    registerFallbackValue(FakeAuthEvent());
  });

  Finder fieldByKey(String key) {
    return find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byType(EditableText),
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    MockAuthBloc bloc, {
    required AuthState state,
  }) async {
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, const Stream<AuthState>.empty(), initialState: state);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: bloc,
          child: const AccountSecurityScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('loads account security on open and shows set password form', (
    tester,
  ) async {
    final bloc = MockAuthBloc();

    await pumpScreen(
      tester,
      bloc,
      state: const AuthState(
        status: AuthStatus.authenticated,
        authSecurity: googleOnlySecurity,
      ),
    );

    verify(() => bloc.add(AuthAccountSecurityRequested())).called(1);
    expect(find.text('Set Password'), findsOneWidget);
    expect(find.text('Password sign-in is enabled'), findsNothing);
  });

  testWidgets('shows enabled state when password provider already exists', (
    tester,
  ) async {
    final bloc = MockAuthBloc();

    await pumpScreen(
      tester,
      bloc,
      state: const AuthState(
        status: AuthStatus.authenticated,
        authSecurity: passwordEnabledSecurity,
      ),
    );

    expect(find.text('Password sign-in is enabled'), findsOneWidget);
    expect(find.text('Set Password'), findsNothing);
  });

  testWidgets('dispatches set password request when form is valid', (
    tester,
  ) async {
    final bloc = MockAuthBloc();

    await pumpScreen(
      tester,
      bloc,
      state: const AuthState(
        status: AuthStatus.authenticated,
        authSecurity: googleOnlySecurity,
      ),
    );

    await tester.enterText(
      fieldByKey('account-security-password'),
      'Password123!',
    );
    await tester.pump();
    await tester.enterText(
      fieldByKey('account-security-confirm-password'),
      'Password123!',
    );
    await tester.pump();
    await tester.tap(find.text('Set Password'));
    await tester.pump();

    verify(
      () => bloc.add(const AuthSetPasswordRequested(password: 'Password123!')),
    ).called(1);
  });
}
