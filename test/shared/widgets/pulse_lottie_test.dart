import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:pulse/shared/widgets/pulse_lottie.dart';
import 'package:visibility_detector/visibility_detector.dart';

void main() {
  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  testWidgets('uses decoder and background loading for .lottie assets', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PulseLottie(
            assetPath: 'assets/animations/Handshake Loop.lottie',
            width: 120,
            height: 120,
          ),
        ),
      ),
    );

    await tester.pump();

    final builder = tester.widget<LottieBuilder>(find.byType(LottieBuilder));
    final dynamic provider = builder.lottie;

    expect(provider.decoder, isNotNull);
    expect(provider.backgroundLoading, isTrue);
    expect(builder.animate, isTrue);
  });

  testWidgets('pauses when route is no longer current', (tester) async {
    await tester.pumpWidget(const _RouteVisibilityHarness());
    await tester.pump();

    expect(
      tester.widget<LottieBuilder>(find.byType(LottieBuilder)).animate,
      isTrue,
    );

    await tester.tap(find.text('Open next'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<LottieBuilder>(
            find.byType(LottieBuilder, skipOffstage: false),
          )
          .animate,
      isFalse,
    );
  });

  testWidgets('pauses when fully out of the viewport and resumes in place', (
    tester,
  ) async {
    final builderStates = <State<StatefulWidget>>[];

    await tester.binding.setSurfaceSize(const Size(400, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const _ScrollVisibilityHarness());
    await tester.pump();
    await tester.pump();

    final visibleFinder = find.byType(LottieBuilder);
    builderStates.add(tester.state(visibleFinder));
    expect(tester.widget<LottieBuilder>(visibleFinder).animate, isTrue);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -700),
    );
    await tester.pump();
    await tester.pump();

    final hiddenFinder = find.byType(LottieBuilder, skipOffstage: false);
    builderStates.add(tester.state(hiddenFinder));
    expect(tester.widget<LottieBuilder>(hiddenFinder).animate, isFalse);

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 700));
    await tester.pump();
    await tester.pump();

    final resumedFinder = find.byType(LottieBuilder);
    builderStates.add(tester.state(resumedFinder));
    expect(tester.widget<LottieBuilder>(resumedFinder).animate, isTrue);
    expect(builderStates[0], same(builderStates[1]));
    expect(builderStates[1], same(builderStates[2]));
  });

  testWidgets('respects ticker mode when disabled', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TickerMode(
            enabled: false,
            child: PulseLottie(
              assetPath: 'assets/animations/Walking Pencil.lottie',
              width: 120,
              height: 120,
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(
      tester.widget<LottieBuilder>(find.byType(LottieBuilder)).animate,
      isFalse,
    );
  });
}

class _RouteVisibilityHarness extends StatelessWidget {
  const _RouteVisibilityHarness();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Column(
              children: [
                const PulseLottie(
                  assetPath: 'assets/animations/Handshake Loop.lottie',
                  width: 120,
                  height: 120,
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const Scaffold(body: Text('Next')),
                      ),
                    );
                  },
                  child: const Text('Open next'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ScrollVisibilityHarness extends StatelessWidget {
  const _ScrollVisibilityHarness();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 24),
              PulseLottie(
                assetPath: 'assets/animations/notifications_empty.json',
                width: 120,
                height: 120,
              ),
              SizedBox(height: 900),
            ],
          ),
        ),
      ),
    );
  }
}
