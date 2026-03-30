import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:pulse/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:pulse/shared/widgets/pulse_lottie.dart';
import 'package:visibility_detector/visibility_detector.dart';

class MockNotificationBloc
    extends MockBloc<NotificationEvent, NotificationState>
    implements NotificationBloc {}

class FakeNotificationEvent extends Fake implements NotificationEvent {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeNotificationEvent());
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  Future<void> pumpScreen(
    WidgetTester tester,
    MockNotificationBloc bloc, {
    NotificationState initialState = const NotificationState(
      status: NotificationStatus.loaded,
    ),
  }) async {
    when(() => bloc.state).thenReturn(initialState);

    await tester.pumpWidget(
      BlocProvider<NotificationBloc>.value(
        value: bloc,
        child: const MaterialApp(home: NotificationsScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('shows lottie empty state when there are no notifications', (
    tester,
  ) async {
    final bloc = MockNotificationBloc();

    await pumpScreen(tester, bloc);

    expect(
      find.byKey(const ValueKey('notifications-empty-lottie')),
      findsOneWidget,
    );
    expect(find.byType(PulseLottie), findsOneWidget);
    expect(find.text('No notifications'), findsOneWidget);
    expect(find.text('You are all caught up for now.'), findsOneWidget);
  });
}
