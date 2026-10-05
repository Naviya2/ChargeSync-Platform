import 'package:chargesync/features/payments/api/payment_api_client.dart';
import 'package:chargesync/features/payments/models/driver_payment_history_item.dart';
import 'package:chargesync/features/payments/models/payment_models.dart';
import 'package:chargesync/features/payments/screens/driver_payment_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses the driver payment history response', () {
    final item = DriverPaymentHistoryItem.fromJson({
      'referenceId': 'reservation-1',
      'type': 'CancellationFee',
      'description': 'Previous late cancellation fees',
      'amount': 500,
      'direction': 'Out',
      'occurredAt': '2026-10-04T10:00:00Z',
      'method': 'Wallet',
    });

    expect(item.amount, 500);
    expect(item.isCredit, isFalse);
    expect(item.occurredAt.toUtc(), DateTime.utc(2026, 10, 4, 10));
  });

  test('parses the linked charging invoice and refund amount', () {
    final item = DriverPaymentHistoryItem.fromJson({
      'referenceId': 'invoice-1',
      'type': 'ChargingPayment',
      'description': 'Charging invoice',
      'amount': 1500,
      'direction': 'Out',
      'occurredAt': '2026-10-04T10:00:00Z',
      'method': 'Wallet',
      'invoice': {
        'id': 'invoice-1',
        'sessionId': 'session-1',
        'driverId': 'driver-1',
        'stationName': 'Test station',
        'chargerIdentifier': 'CH1',
        'bayLabel': 'Bay A',
        'energyDeliveredKwh': 20,
        'tariffPerKwh': 100,
        'grossAmount': 2000,
        'discountAmount': 0,
        'advanceDeducted': 500,
        'netAmountDue': 1500,
        'refundedAmount': 200,
        'paymentMethod': 'Wallet',
        'status': 'Paid',
        'issuedAt': '2026-10-04T09:55:00Z',
        'settledAt': '2026-10-04T10:00:00Z',
      },
    });

    expect(item.invoice?.id, 'invoice-1');
    expect(item.invoice?.advanceDeducted, 500);
    expect(item.invoice?.refundedAmount, 200);
  });

  testWidgets('expands a charging receipt and copies its invoice ID', (
    tester,
  ) async {
    String? copied;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    final at = DateTime(2026, 10, 4, 10);
    final invoice = PaymentInvoice(
      id: 'invoice-123',
      sessionId: 'session-1',
      driverId: 'driver-1',
      stationName: 'Test station',
      chargerIdentifier: 'CH1',
      bayLabel: 'Bay A',
      energyDeliveredKwh: 20,
      tariffPerKwh: 100,
      grossAmount: 2000,
      advanceDeducted: 500,
      netAmountDue: 1500,
      refundedAmount: 200,
      paymentMethod: 'Wallet',
      status: 'Paid',
      issuedAt: at,
      settledAt: at,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: DriverPaymentHistoryScreen(
          loadHistory: () async => [
            DriverPaymentHistoryItem(
              referenceId: invoice.id,
              type: 'ChargingPayment',
              description: 'Charging invoice',
              amount: 1500,
              direction: 'Out',
              occurredAt: at,
              method: 'Wallet',
              invoice: invoice,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Test station charging invoice'), findsOneWidget);
    expect(find.textContaining('−LKR 1500.00'), findsOneWidget);
    await tester.tap(find.text('Test station charging invoice'));
    await tester.pumpAndSettle();
    expect(find.text('invoice-123'), findsOneWidget);
    expect(find.text('LKR 2000.00'), findsOneWidget);
    expect(find.text('−LKR 500.00'), findsOneWidget);
    expect(find.text('LKR 200.00'), findsOneWidget);
    await tester.ensureVisible(find.text('Copy invoice ID'));
    await tester.tap(find.text('Copy invoice ID'));
    await tester.pump();
    expect(copied, 'invoice-123');
    expect(find.text('Invoice ID copied'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('identifies an invoice fully paid from the advance', (
    tester,
  ) async {
    final at = DateTime(2026, 10, 4, 10);
    final invoice = PaymentInvoice(
      id: 'invoice-zero',
      sessionId: 'session-zero',
      driverId: 'driver-1',
      stationName: 'Test station',
      chargerIdentifier: 'CH1',
      bayLabel: '',
      energyDeliveredKwh: 4,
      tariffPerKwh: 100,
      grossAmount: 400,
      advanceDeducted: 400,
      netAmountDue: 0,
      paymentMethod: 'Wallet',
      status: 'Paid',
      issuedAt: at,
      settledAt: at,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: DriverPaymentHistoryScreen(
          loadHistory: () async => [
            DriverPaymentHistoryItem(
              referenceId: invoice.id,
              type: 'ChargingPayment',
              description: 'Charging invoice',
              amount: 0,
              direction: 'Info',
              occurredAt: at,
              method: 'Wallet',
              invoice: invoice,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Paid from advance'), findsOneWidget);
    expect(find.textContaining('−LKR 0.00'), findsNothing);
  });

  testWidgets('shows payments and wallet credits with distinct signs', (
    tester,
  ) async {
    final at = DateTime(2026, 10, 4, 10);
    await tester.pumpWidget(
      MaterialApp(
        home: DriverPaymentHistoryScreen(
          loadHistory: () async => [
            DriverPaymentHistoryItem(
              referenceId: 'r1',
              type: 'ReservationAdvance',
              description: 'Reservation advance',
              amount: 500,
              direction: 'Out',
              occurredAt: at,
              method: 'Wallet',
            ),
            DriverPaymentHistoryItem(
              referenceId: 'r1',
              type: 'AdvanceRefund',
              description: 'Cancelled reservation advance refund',
              amount: 500,
              direction: 'In',
              occurredAt: at,
              method: 'Wallet',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Payment history'), findsOneWidget);
    expect(find.text('Reservation advance'), findsOneWidget);
    expect(find.text('Cancelled reservation advance refund'), findsOneWidget);
    expect(find.text('−LKR 500.00'), findsOneWidget);
    expect(find.text('+LKR 500.00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('offers retry when the history request fails', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: DriverPaymentHistoryScreen(
          loadHistory: () async {
            attempts++;
            if (attempts == 1) throw Exception('offline');
            return [];
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Could not load payment history'),
      findsOneWidget,
    );
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('No payments or wallet activity yet.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the reason when payment history is unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DriverPaymentHistoryScreen(
          loadHistory: () async => throw const PaymentHistoryLoadException(
            'Your session has expired. Sign out and sign in again.',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Your session has expired. Sign out and sign in again.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });
}
