import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/constants/app_routes.dart';
import 'package:pulse/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse/features/auth/presentation/screens/email_verification_screen.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class FakeAuthEvent extends Fake implements AuthEvent {}

void main() {
  const email = 'test@example.com';
  late MockAuthBloc bloc;

  setUpAll(() {
    registerFallbackValue(FakeAuthEvent());
  });

  setUp(() {
    bloc = MockAuthBloc();
    when(
      () => bloc.state,
    ).thenReturn(const AuthState(pendingVerificationEmail: email));
  });

  Widget buildApp() {
    return BlocProvider<AuthBloc>.value(
      value: bloc,
      child: MaterialApp(
        routes: {
          AppRoutes.login: (_) => const Scaffold(body: Text('Login Screen')),
          AppRoutes.register: (_) =>
              const Scaffold(body: Text('Register Screen')),
        },
        home: const EmailVerificationScreen(),
      ),
    );
  }

  testWidgets('shows the verification details', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Check your inbox.'), findsOneWidget);
    expect(find.text(email), findsOneWidget);
    expect(find.textContaining('Open your email app'), findsOneWidget);
    expect(find.byKey(const ValueKey('verification-login')), findsOneWidget);
    expect(find.byKey(const ValueKey('verification-register')), findsOneWidget);
  });

  testWidgets('back to sign in navigates to login', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('verification-login')));
    await tester.pumpAndSettle();
    expect(find.text('Login Screen'), findsOneWidget);
  });

  testWidgets('use different email navigates to register', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('verification-register')));
    await tester.pumpAndSettle();
    expect(find.text('Register Screen'), findsOneWidget);
  });
}
