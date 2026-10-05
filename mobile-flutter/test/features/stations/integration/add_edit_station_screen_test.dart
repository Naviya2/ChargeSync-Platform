import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chargesync/features/stations/screens/add_edit_station_screen.dart';

void main() {
  group('AddEditStationScreen Widget Tests', () {
    Widget createWidgetUnderTest() {
      return const MaterialApp(home: AddEditStationScreen());
    }

    testWidgets('renders registration form fields correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Register Station'), findsOneWidget);

      expect(find.text('Station Name'), findsOneWidget);
      expect(find.text('Address'), findsOneWidget);
      expect(
        find.text('Drag the map or tap to place the station marker'),
        findsOneWidget,
      );

      expect(find.text('Documents / Images'), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);
    });

    testWidgets('shows validation errors when submitting empty form', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.widgetWithText(ElevatedButton, 'Register'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Required'), findsNWidgets(2));
    });

    testWidgets('entering short text shows length validation errors', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Station Name'),
        'ab',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Address'),
        'abcd',
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Register'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Name must be at least 3 characters'), findsOneWidget);
      expect(
        find.text('Address must be at least 5 characters'),
        findsOneWidget,
      );
    });
  });
}
