import 'dart:convert';

import 'package:chargesync/features/payments/models/payment_models.dart';
import 'package:chargesync/features/payments/screens/session_checkout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/student4_http.dart';

class CheckoutFixture {
  bool empty = false;
  bool loadFails = false;
  bool stopFails = false;
  bool settlementFails = false;
  bool walkIn = false;
  final writes = <http.Request>[];

  Map<String, dynamic> get session => {
    'id': 'session-1',
    'reservationId': 'reservation-1',
    'chargerId': 'charger-1',
    'driverId': walkIn ? null : 'driver-1',
    'stationName': 'Test station',
    'chargerIdentifier': 'CH1',
    'bayLabel': 'Bay A',
    'chargerPowerKw': 20,
    'tariffPerKwh': 100,
    'startTime': DateTime.now()
        .subtract(const Duration(minutes: 30))
        .toIso8601String(),
    'status': 'InProgress',
  };

  Map<String, dynamic> invoice({bool paid = false}) => {
    'id': 'invoice-1',
    'sessionId': 'session-1',
    'driverId': walkIn ? null : 'driver-1',
    'stationName': 'Test station',
    'chargerIdentifier': 'CH1',
    'energyDeliveredKwh': 10,
    'tariffPerKwh': 100,
    'grossAmount': 1000,
    'discountAmount': 50,
    'advanceDeducted': 200,
    'netAmountDue': 750,
    'status': paid ? 'Paid' : 'Pending',
    'paymentMethod': paid ? (walkIn ? 'Cash' : 'Wallet') : null,
    'issuedAt': '2026-01-01T10:00:00Z',
  };

  Future<http.Response> respond(http.Request request) async {
    expect(request.headers['authorization'], 'Bearer test-token');
    if (request.method == 'GET' && request.url.path == '/api/sessions') {
      expect(request.url.queryParameters['status'], 'InProgress');
      if (loadFails)
        return jsonResponse({'detail': 'Cannot load sessions'}, 503);
      return jsonResponse(empty ? [] : [session]);
    }
    writes.add(request);
    if (request.method == 'PUT' &&
        request.url.path == '/api/sessions/session-1/stop') {
      if (stopFails)
        return jsonResponse({'detail': 'Session already completed'}, 409);
      return jsonResponse({
        'session': {...session, 'status': 'Completed'},
        'invoice': invoice(),
      });
    }
    if (request.method == 'POST' &&
        request.url.path == '/api/payments/invoices/invoice-1/settle') {
      if (settlementFails)
        return jsonResponse({'detail': 'Insufficient wallet funds'}, 400);
      return jsonResponse(invoice(paid: true));
    }
    throw StateError('Unexpected request: ${request.method} ${request.url}');
  }
}

const stopLabel = 'Stop session & generate invoice';
const payLabel = 'Confirm LKR 750.00 payment';

void main() {
  setUp(prepareStudent4Test);

  test('S01: energy estimate uses charger power and elapsed hours', () {
    final fixture = CheckoutFixture();
    final data = {...fixture.session, 'startTime': '2026-01-01T10:00:00Z'};
    final session = ChargingSessionSummary.fromJson(data);
    expect(session.estimatedEnergyAt(DateTime.utc(2026, 1, 1, 10, 30)), 10);
    expect(session.estimatedEnergyAt(DateTime.utc(2026, 1, 1, 9, 59)), 0);
  });

  testWidgets('S02: empty sessions show a useful message and Refresh reloads', (
    tester,
  ) async {
    final fixture = CheckoutFixture()..empty = true;
    await http.runWithClient(() async {
      await showTestScreen(tester, const SessionCheckoutScreen());
      expect(find.text('No active sessions'), findsOneWidget);
      fixture.empty = false;
      await tapVisible(tester, find.text('Refresh'));
      expect(find.text('No active sessions'), findsNothing);
      expect(find.text(stopLabel), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }, () => MockClient(fixture.respond));
  });

  testWidgets('S03: load failure shows the API error and can be retried', (
    tester,
  ) async {
    final fixture = CheckoutFixture()..loadFails = true;
    await http.runWithClient(() async {
      await showTestScreen(tester, const SessionCheckoutScreen());
      expect(find.text('Cannot load sessions'), findsOneWidget);
      fixture.loadFails = false;
      await tapVisible(tester, find.text('Refresh'));
      expect(find.text('Cannot load sessions'), findsNothing);
      expect(find.text(stopLabel), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }, () => MockClient(fixture.respond));
  });

  for (final reading in ['', 'abc', '-1', '0']) {
    testWidgets(
      'S04: invalid physical meter reading "$reading" never calls stop API',
      (tester) async {
        final fixture = CheckoutFixture();
        await http.runWithClient(() async {
          await showTestScreen(tester, const SessionCheckoutScreen());
          await tapVisible(tester, find.byType(SwitchListTile));
          await tester.enterText(find.byType(TextField), reading);
          await tapVisible(tester, find.text(stopLabel));
          expect(
            find.text('Enter a valid physical meter reading.'),
            findsOneWidget,
          );
          expect(fixture.writes, isEmpty);
          await tester.pumpWidget(const SizedBox.shrink());
        }, () => MockClient(fixture.respond));
      },
    );
  }

  testWidgets('S05: physical reading without a photo blocks submission', (
    tester,
  ) async {
    final fixture = CheckoutFixture();
    await http.runWithClient(() async {
      await showTestScreen(tester, const SessionCheckoutScreen());
      await tapVisible(tester, find.byType(SwitchListTile));
      await tester.enterText(find.byType(TextField), '10');
      await tapVisible(tester, find.text(stopLabel));
      expect(
        find.text(
          'Meter photo is required when using a physical meter reading.',
        ),
        findsOneWidget,
      );
      expect(fixture.writes, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    }, () => MockClient(fixture.respond));
  });

  testWidgets(
    'S06: stop sends the selected session and renders returned invoice amounts',
    (tester) async {
      final fixture = CheckoutFixture();
      await http.runWithClient(() async {
        await showTestScreen(tester, const SessionCheckoutScreen());
        await tapVisible(tester, find.text(stopLabel));
        expect(fixture.writes.single.method, 'PUT');
        expect(fixture.writes.single.url.path, '/api/sessions/session-1/stop');
        expect(jsonDecode(fixture.writes.single.body), isEmpty);
        expect(find.text('Invoice generated'), findsOneWidget);
        expect(find.text('LKR 1000.00'), findsOneWidget);
        expect(find.text('- LKR 50.00'), findsOneWidget);
        expect(find.text('- LKR 200.00'), findsOneWidget);
        expect(find.text('LKR 750.00'), findsOneWidget);
        expect(find.text(stopLabel), findsNothing);
        await tester.pumpWidget(const SizedBox.shrink());
      }, () => MockClient(fixture.respond));
    },
  );

  testWidgets(
    'S07: rejected stop displays error without claiming an invoice was generated',
    (tester) async {
      final fixture = CheckoutFixture()..stopFails = true;
      await http.runWithClient(() async {
        await showTestScreen(tester, const SessionCheckoutScreen());
        await tapVisible(tester, find.text(stopLabel));
        expect(find.text('Session already completed'), findsOneWidget);
        expect(find.text('Invoice generated'), findsNothing);
        await tester.pumpWidget(const SizedBox.shrink());
      }, () => MockClient(fixture.respond));
    },
  );

  testWidgets(
    'P01: registered invoice sends Wallet settlement and removes payment controls',
    (tester) async {
      final fixture = CheckoutFixture();
      await http.runWithClient(() async {
        await showTestScreen(tester, const SessionCheckoutScreen());
        await tapVisible(tester, find.text(stopLabel));
        await tapVisible(tester, find.text(payLabel));
        expect(jsonDecode(fixture.writes.last.body), {
          'paymentMethod': 'Wallet',
        });
        expect(find.text('Payment recorded • Wallet.'), findsOneWidget);
        expect(find.text(payLabel), findsNothing);
        await tester.pumpWidget(const SizedBox.shrink());
      }, () => MockClient(fixture.respond));
    },
  );

  testWidgets(
    'P02: insufficient funds retain pending invoice and allow payment retry',
    (tester) async {
      final fixture = CheckoutFixture()..settlementFails = true;
      await http.runWithClient(() async {
        await showTestScreen(tester, const SessionCheckoutScreen());
        await tapVisible(tester, find.text(stopLabel));
        await tapVisible(tester, find.text(payLabel));
        expect(find.text('Insufficient wallet funds'), findsOneWidget);
        expect(find.text('PENDING'), findsOneWidget);
        expect(find.text('Payment recorded • Wallet.'), findsNothing);
        fixture.settlementFails = false;
        await tapVisible(tester, find.text(payLabel));
        expect(find.text('Payment recorded • Wallet.'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
      }, () => MockClient(fixture.respond));
    },
  );

  testWidgets(
    'P03: walk-in invoice offers cash only and submits Cash settlement',
    (tester) async {
      final fixture = CheckoutFixture()..walkIn = true;
      await http.runWithClient(() async {
        await showTestScreen(tester, const SessionCheckoutScreen());
        await tapVisible(tester, find.text(stopLabel));
        expect(find.text('Wallet'), findsNothing);
        expect(
          find.text('Walk-in invoices must be settled in cash.'),
          findsOneWidget,
        );
        await tapVisible(tester, find.text(payLabel));
        expect(jsonDecode(fixture.writes.last.body), {'paymentMethod': 'Cash'});
        expect(find.text('Payment recorded • Cash.'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
      }, () => MockClient(fixture.respond));
    },
  );
}
