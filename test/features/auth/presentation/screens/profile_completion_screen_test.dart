import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/constants/app_routes.dart';
import 'package:pulse/features/auth/domain/entities/user.dart';
import 'package:pulse/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse/features/auth/presentation/screens/profile_completion_screen.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class FakeAuthEvent extends Fake implements AuthEvent {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAuthEvent());
  });

  const user = User(
    id: '1',
    username: 'john_doe',
    displayName: 'John Doe',
    email: 'john@example.com',
    phone: '',
  );

  Finder fieldByKey(String key) {
    return find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byType(EditableText),
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    MockAuthBloc bloc, {
    Stream<AuthState>? stream,
  }) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    when(() => bloc.state).thenReturn(
      const AuthState(
        status: AuthStatus.profileCompletionRequired,
        user: user,
        shouldCompleteProfile: true,
      ),
    );

    if (stream != null) {
      whenListen(
        bloc,
        stream,
        initialState: const AuthState(
          status: AuthStatus.profileCompletionRequired,
          user: user,
          shouldCompleteProfile: true,
        ),
      );
    }

    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: bloc,
        child: MaterialApp(
          routes: {
            AppRoutes.home: (_) => const Scaffold(body: Text('Home Screen')),
          },
          home: const ProfileCompletionScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders optional profile fields', (tester) async {
    final bloc = MockAuthBloc();

    await pumpScreen(tester, bloc);

    expect(find.text('Add the details your crew uses.'), findsOneWidget);
    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('john@example.com'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('profile-completion-phone')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('profile-completion-payment-identity')),
      findsOneWidget,
    );
  });

  testWidgets('skip dispatches completion skipped event', (tester) async {
    final bloc = MockAuthBloc();

    await pumpScreen(tester, bloc);
    await tester.ensureVisible(
      find.byKey(const ValueKey('profile-completion-skip')),
    );
    await tester.tap(find.byKey(const ValueKey('profile-completion-skip')));
    await tester.pump();

    verify(
      () => bloc.add(any(that: isA<AuthProfileCompletionSkipped>())),
    ).called(1);
  });

  testWidgets('save dispatches formatted profile update event', (tester) async {
    final bloc = MockAuthBloc();

    await pumpScreen(tester, bloc);

    await tester.enterText(fieldByKey('profile-completion-phone'), '123456789');
    await tester.enterText(
      fieldByKey('profile-completion-payment-identity'),
      'DuitNow John',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('profile-completion-save')),
    );
    await tester.tap(find.byKey(const ValueKey('profile-completion-save')));
    await tester.pump();

    verify(
      () => bloc.add(
        any(
          that: isA<AuthProfileUpdateRequested>()
              .having((event) => event.displayName, 'displayName', 'John Doe')
              .having((event) => event.phone, 'phone', '+60123456789')
              .having(
                (event) => event.paymentIdentity,
                'paymentIdentity',
                'DuitNow John',
              ),
        ),
      ),
    ).called(1);
  });
}
