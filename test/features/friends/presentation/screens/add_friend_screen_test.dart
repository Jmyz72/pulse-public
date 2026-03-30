import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/auth/domain/entities/user.dart';
import 'package:pulse/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse/features/friends/presentation/bloc/friend_bloc.dart';
import 'package:pulse/features/friends/presentation/bloc/friend_event.dart';
import 'package:pulse/features/friends/presentation/bloc/friend_state.dart';
import 'package:pulse/features/friends/presentation/screens/add_friend_screen.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockFriendBloc extends MockBloc<FriendEvent, FriendState>
    implements FriendBloc {}

class FakeAuthEvent extends Fake implements AuthEvent {}

class FakeFriendEvent extends Fake implements FriendEvent {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockFriendBloc mockFriendBloc;

  const tCurrentUser = User(
    id: 'user-123',
    username: 'jimmy',
    displayName: 'Jimmy Hew',
    email: 'jimmy@test.com',
    phone: '+1234567890',
  );

  setUpAll(() {
    registerFallbackValue(FakeAuthEvent());
    registerFallbackValue(FakeFriendEvent());
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockFriendBloc = MockFriendBloc();

    when(() => mockAuthBloc.state).thenReturn(
      const AuthState(status: AuthStatus.authenticated, user: tCurrentUser),
    );
    when(() => mockFriendBloc.state).thenReturn(const FriendState());
    when(() => mockFriendBloc.add(any())).thenReturn(null);

    whenListen(
      mockAuthBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthState(
        status: AuthStatus.authenticated,
        user: tCurrentUser,
      ),
    );
    whenListen(
      mockFriendBloc,
      const Stream<FriendState>.empty(),
      initialState: const FriendState(),
    );
  });

  Widget buildSubject() {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<FriendBloc>.value(value: mockFriendBloc),
        ],
        child: const AddFriendScreen(),
      ),
    );
  }

  testWidgets('clears previous search state when screen is opened', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());

    verify(() => mockFriendBloc.add(const FriendSearchCleared())).called(1);
  });
}
