import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:pulse/features/home/presentation/screens/home_tabs/home_tab.dart';
import 'package:pulse/shared/widgets/pulse_lottie.dart';
import 'package:visibility_detector/visibility_detector.dart';

void main() {
  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  testWidgets('renders walking pencil animation on top of hero card', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HomeTab(
            unreadNotificationsCount: 0,
            recentActivities: [],
            pendingTasksCount: 0,
            upcomingEventsCount: 0,
            groceryItemsCount: 0,
            aroundNowCount: 0,
            aroundNowMode: HomeHeroAroundNowMode.onlineFallback,
            onViewAllActivities: _noop,
            onRefresh: _onRefresh,
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 700));

    final lottie = tester.widget<PulseLottie>(
      find.byKey(const ValueKey('home-hero-walking-pencil')),
    );

    expect(lottie.assetPath, 'assets/animations/Walking Pencil.lottie');
    expect(lottie.renderCache, RenderCache.drawingCommands);
    expect(
      find.byKey(const ValueKey('home-hero-walker-repaint-boundary')),
      findsOneWidget,
    );
  });
}

void _noop() {}

Future<void> _onRefresh() async {}
