import 'package:chargesync/features/payments/models/driver_payment_history_item.dart';
import 'package:chargesync/features/payments/screens/driver_payment_history_screen.dart';
import 'package:flutter/material.dart';
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
}
