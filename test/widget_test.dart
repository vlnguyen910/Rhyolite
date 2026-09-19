import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhyolite/app.dart';

void main() {
  testWidgets('App renders HomeView with desktop NavigationRail', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RhyoliteApp());
    await tester.pumpAndSettle();

    // Verify initial screen shows Curriculum tab content
    expect(find.text('Curriculum Exploration'), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);

    // Verify presence of navigation destinations
    expect(find.text('Curriculum'), findsOneWidget);
    expect(find.text('Transcript'), findsOneWidget);
    expect(find.text('Analysis'), findsOneWidget);
    expect(find.text('AI Chat'), findsOneWidget);
    expect(find.text('Strategy'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Tap on 'Transcript' tab and trigger a frame
    await tester.tap(find.text('Transcript'));
    await tester.pumpAndSettle();

    // Verify content changed to Transcript Management
    expect(find.text('Transcript Management'), findsOneWidget);
    expect(find.text('Curriculum Exploration'), findsNothing);
  });
}
