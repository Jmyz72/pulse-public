import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/auth/domain/entities/user.dart';
import 'package:pulse/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse/features/settings/presentation/screens/edit_profile_screen.dart';
import 'package:pulse/shared/widgets/glass_text_field.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class FakeAuthEvent extends Fake implements AuthEvent {}

void main() {
  late MockAuthBloc mockAuthBloc;

  const tUser = User(
    id: 'uid-123',
    username: 'jimmy',
    displayName: 'Jimmy Hew',
    email: 'jimmy@test.com',
    phone: '+14155552671',
  );

  setUpAll(() {
    registerFallbackValue(FakeAuthEvent());
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();

    when(() => mockAuthBloc.state).thenReturn(
      const AuthState(status: AuthStatus.authenticated, user: tUser),
    );
    whenListen(
      mockAuthBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthState(
        status: AuthStatus.authenticated,
        user: tUser,
      ),
    );
  });

  Widget buildSubject() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: const EditProfileScreen(),
      ),
    );
  }

  group('EditProfileScreen account info', () {
    testWidgets('shows read-only username/email and only two editable fields', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text('@jimmy'), findsOneWidget);
      expect(find.text('jimmy@test.com'), findsOneWidget);
      expect(find.byType(GlassTextField), findsNWidgets(2));
      expect(find.text('Display Name'), findsOneWidget);
      expect(find.text('Phone'), findsOneWidget);
    });

    testWidgets('shows Not set when username is empty', (tester) async {
      const userWithoutUsername = User(
        id: 'uid-123',
        username: '',
        displayName: 'Jimmy Hew',
        email: 'jimmy@test.com',
        phone: '+14155552671',
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
      await tester.pump();

      expect(find.text('Not set'), findsOneWidget);
      expect(find.text('jimmy@test.com'), findsOneWidget);
    });

    testWidgets('saves an international phone number as E.164', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('edit-profile-phone')),
          matching: find.byType(EditableText),
        ),
        '4155552671',
      );
      await tester.tap(find.byIcon(Icons.save));
      await tester.pump();

      verify(
        () => mockAuthBloc.add(
          any(
            that: isA<AuthProfileUpdateRequested>()
                .having(
                  (event) => event.displayName,
                  'displayName',
                  'Jimmy Hew',
                )
                .having((event) => event.phone, 'phone', '+14155552671'),
          ),
        ),
      ).called(1);
    });
  });
}
