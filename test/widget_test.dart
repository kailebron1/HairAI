// This is a basic Flutter widget test for HairStyle AI app.

import 'package:flutter_test/flutter_test.dart';

import 'package:my_first_app/main.dart';

void main() {
  testWidgets('HairStyle AI app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HairStyleAIApp());

    // Verify that the upload screen loads
    expect(find.text('Transform Your Hair Journey'), findsOneWidget);
    expect(
      find.text('Step 1: Upload a selfie with your current hairstyle'),
      findsOneWidget,
    );

    // Verify upload area is present
    expect(find.text('Drag and drop your selfie here'), findsOneWidget);
    expect(find.text('or click to browse files'), findsOneWidget);
  });
}
