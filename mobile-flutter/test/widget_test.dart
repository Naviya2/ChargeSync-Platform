// ChargeSync Flutter Widget Tests
//
// Basic smoke tests to verify the app loads correctly.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chargesync/main.dart';

void main() {
  testWidgets('App launches and renders home screen', (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(const ChargeSyncApp());
    await tester.pump();

    // Verify the app renders without crashing.
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Home screen has a Scaffold', (WidgetTester tester) async {
    await tester.pumpWidget(const ChargeSyncApp());
    await tester.pump();

    // Verify basic scaffold structure exists.
    expect(find.byType(Scaffold), findsWidgets);
  });
}
