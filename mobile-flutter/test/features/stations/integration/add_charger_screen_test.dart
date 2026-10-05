import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chargesync/features/stations/screens/add_charger_screen.dart';
import 'package:chargesync/core/api/vehicle_models.dart';

void main() {
  group('AddChargerScreen Widget Tests', () {
    Widget createWidgetUnderTest() {
      return const MaterialApp(home: AddChargerScreen(stationId: 'st-123'));
    }

    testWidgets('renders all form fields correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Add Charger'), findsNWidgets(2));

      expect(find.byType(TextFormField), findsNWidgets(4));

      expect(find.text('Identifier (e.g. CS-001)'), findsOneWidget);
      expect(find.text('Bay Label'), findsOneWidget);
      expect(find.text('Power Output (kW)'), findsOneWidget);
      expect(find.text('Tariff (\$/kWh)'), findsOneWidget);

      expect(
        find.byType(DropdownButtonFormField<ConnectorType>),
        findsOneWidget,
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('shows validation errors when submitting empty form', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Required'), findsNWidgets(2));
      expect(find.text('Invalid number'), findsNWidgets(2));
    });

    testWidgets('entering text removes validation errors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Required'), findsNWidgets(2));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Identifier (e.g. CS-001)'),
        'CHG-01',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Bay Label'),
        'Bay 1',
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Required'), findsNothing);
    });
  });
}
