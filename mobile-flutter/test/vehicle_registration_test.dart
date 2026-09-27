import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chargesync/core/api/vehicle_models.dart';
import 'package:chargesync/screens/vehicles/add_edit_vehicle_screen.dart';

void main() {
  group('Vehicle Models & Serialisation Tests', () {
    test('ConnectorType serialises to exact backend enum strings', () {
      expect(ConnectorType.ccs2.toBackendString(), 'CCS2');
      expect(ConnectorType.type2.toBackendString(), 'Type2');
      expect(ConnectorType.chademo.toBackendString(), 'CHAdeMO');
      expect(ConnectorType.nacs.toBackendString(), 'NACS');
      expect(ConnectorType.gbt.toBackendString(), 'GBT');
      expect(ConnectorType.mcs.toBackendString(), 'MCS');
    });

    test('ConnectorType correctly parses case-insensitively from backend values', () {
      expect(ConnectorType.fromString('NACS'), ConnectorType.nacs);
      expect(ConnectorType.fromString('CCS2'), ConnectorType.ccs2);
      expect(ConnectorType.fromString('Type2'), ConnectorType.type2);
      expect(ConnectorType.fromString('CHAdeMO'), ConnectorType.chademo);
      expect(ConnectorType.fromString('GBT'), ConnectorType.gbt);
      expect(ConnectorType.fromString('MCS'), ConnectorType.mcs);
      expect(ConnectorType.fromString('0'), ConnectorType.ccs2);
      expect(ConnectorType.fromString('3'), ConnectorType.nacs);
    });

    test('VehicleRequest creates valid payload matching backend specifications', () {
      final request = VehicleRequest(
        make: 'Tesla',
        model: 'Model 3',
        licensePlate: 'cab-1234',
        connector: ConnectorType.nacs,
        batteryCapacityKwh: 75.0,
        maxChargeRateKw: 170.0,
      );

      final json = request.toJson();
      expect(json['make'], 'Tesla');
      expect(json['model'], 'Model 3');
      expect(json['licensePlate'], 'CAB-1234');
      expect(json['connector'], 'NACS');
      expect(json['batteryCapacityKwh'], 75.0);
      expect(json['maxChargeRateKw'], 170.0);
    });

    test('Vehicle.fromJson correctly parses backend response', () {
      final json = {
        'id': 'a1b2c3d4-e5f6-7890-1234-56789abcdef0',
        'ownerId': 'user-123',
        'make': 'Hyundai',
        'model': 'Ioniq 5',
        'licensePlate': 'EV-8822',
        'connector': 'CCS2',
        'batteryCapacityKwh': 77.4,
        'maxChargeRateKw': 233.0,
        'createdAt': '2026-09-25T10:00:00Z',
      };

      final vehicle = Vehicle.fromJson(json);
      expect(vehicle.id, 'a1b2c3d4-e5f6-7890-1234-56789abcdef0');
      expect(vehicle.make, 'Hyundai');
      expect(vehicle.model, 'Ioniq 5');
      expect(vehicle.fullName, 'Hyundai Ioniq 5');
      expect(vehicle.licensePlate, 'EV-8822');
      expect(vehicle.connector, ConnectorType.ccs2);
      expect(vehicle.batteryCapacityKwh, 77.4);
      expect(vehicle.maxChargeRateKw, 233.0);
    });
  });

  group('AddEditVehicleScreen Widget Tests', () {
    testWidgets('Renders all required vehicle registration fields and presets', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      await tester.pumpWidget(
        const MaterialApp(
          home: AddEditVehicleScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header and Title
      expect(find.text('Register New Vehicle'), findsOneWidget);

      // Verify Make and Model fields
      expect(find.text('Make / Brand'), findsOneWidget);
      expect(find.text('Model'), findsOneWidget);

      // Verify Connector standard choices
      expect(find.text('Connector Standard'), findsOneWidget);
      expect(find.text('CCS Combo 2'), findsWidgets);
      expect(find.text('NACS (Tesla)'), findsOneWidget);
      expect(find.text('Type 2 (Mennekes)'), findsOneWidget);

      // Verify Battery Capacity and Max Charge Rate sections
      expect(find.text('Battery Capacity (kWh)'), findsOneWidget);
      expect(find.text('Maximum Charge Rate (kW)'), findsOneWidget);

      // Verify CTA button
      expect(find.text('Register Vehicle'), findsOneWidget);
    });

    testWidgets('Validates required fields when submitting empty form', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      await tester.pumpWidget(
        const MaterialApp(
          home: AddEditVehicleScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure button is visible in scroll view and tap it
      final registerButton = find.widgetWithText(ElevatedButton, 'Register Vehicle');
      await tester.ensureVisible(registerButton);
      await tester.pumpAndSettle();
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      // Should show validation error for Make and Model
      expect(find.text('Make is required'), findsOneWidget);
      expect(find.text('Model is required'), findsOneWidget);
    });
  });
}
