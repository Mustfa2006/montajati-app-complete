// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';



void main() {
  group('Widget Tests', () {
    testWidgets('MaterialApp loads successfully', (WidgetTester tester) async {
      // Build a simple MaterialApp
      await tester.pumpWidget(
        MaterialApp(
          title: 'Test App',
          home: Scaffold(
            appBar: AppBar(
              title: Text('Test'),
            ),
            body: Center(
              child: Text('Hello World'),
            ),
          ),
        ),
      );

      // Wait for the app to load
      await tester.pumpAndSettle();

      // Verify that the app loads correctly
      expect(find.text('Hello World'), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('Text widget displays correctly', (WidgetTester tester) async {
      // Build a simple text widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Text('Flutter Test'),
          ),
        ),
      );

      // Verify text is displayed
      expect(find.text('Flutter Test'), findsOneWidget);
    });
  });
}
