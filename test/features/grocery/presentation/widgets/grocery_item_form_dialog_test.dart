import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/grocery/presentation/widgets/grocery_item_form_dialog.dart';

void main() {
  Widget buildSubject({void Function(GroceryItemFormSubmission)? onSubmit}) {
    return MaterialApp(
      home: Scaffold(body: GroceryItemFormDialog(onSubmit: onSubmit ?? (_) {})),
    );
  }

  testWidgets('renders enriched grocery fields and image controls', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Brand (optional)'), findsOneWidget);
    expect(find.text('Size (optional)'), findsOneWidget);
    expect(find.text('Variant (optional)'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Product Image (optional)'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Product Image (optional)'), findsOneWidget);
    expect(find.text('Add Image'), findsOneWidget);
  });

  testWidgets('validates required item name before submit', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Add'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add'));
    await tester.pump();

    expect(find.text('Please enter an item name'), findsOneWidget);
  });
}
