import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse/features/auth/presentation/screens/auth_gate.dart';
import 'package:pulse/shared/widgets/pulse_lottie.dart';
import 'package:visibility_detector/visibility_detector.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class FakeAuthEvent extends Fake implements AuthEvent {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAuthEvent());
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  testWidgets('shows lottie loading state while auth status is unresolved', (
    tester,
  ) async {
    final bloc = MockAuthBloc();
    when(() => bloc.state).thenReturn(const AuthState());

    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: bloc,
        child: const MaterialApp(home: AuthGate()),
      ),
    );

    await tester.pump();

    expect(find.byKey(const ValueKey('auth-gate-lottie')), findsOneWidget);
    expect(find.byType(PulseLottie), findsOneWidget);
    final lottie = tester.widget<PulseLottie>(
      find.byKey(const ValueKey('auth-gate-lottie')),
    );
    expect(lottie.assetPath, 'assets/animations/Handshake Loop.lottie');
    expect(find.text('Syncing your Pulse flow...'), findsOneWidget);
  });
}
