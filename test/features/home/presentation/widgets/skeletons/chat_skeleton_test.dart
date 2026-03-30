import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/home/presentation/widgets/skeletons/chat_skeleton.dart';
import 'package:pulse/shared/widgets/glass_card.dart';

void main() {
  group('ChatSkeleton', () {
    testWidgets('renders default 6 skeleton tiles', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ChatSkeleton(),
            ),
          ),
        ),
      );

      // Each tile is wrapped in a GlassContainer
      expect(find.byType(GlassContainer), findsNWidgets(6));
    });

    testWidgets('renders custom count of skeleton tiles', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ChatSkeleton(count: 3),
            ),
          ),
        ),
      );

      expect(find.byType(GlassContainer), findsNWidgets(3));
    });
  });
}
