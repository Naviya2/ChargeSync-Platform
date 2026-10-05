import 'package:chargesync/core/api/reservation_models.dart';
import 'package:chargesync/features/reservations/widgets/reservation_charge_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final fee in [0.0, 500.0, 1000.0]) {
    testWidgets('Shows separate advance and fee $fee before confirmation', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReservationChargeDialog(
              charges: BookingCharges(
                walletBalance: 2000,
                pendingCancellationFees: fee,
              ),
            ),
          ),
        ),
      );
      expect(find.textContaining('Advance: LKR 500.00'), findsOneWidget);
      expect(
        find.textContaining(
          'Outstanding cancellation fees: LKR ${fee.toStringAsFixed(2)}',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Total wallet deduction: LKR ${(500 + fee).toStringAsFixed(2)}',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('2 hours or more before start is free'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Cancellation fees are non-refundable'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final confirm in [false, true]) {
    testWidgets(
      'Small screen keeps ${confirm ? 'confirmation' : 'cancellation'} accessible',
      (tester) async {
        tester.view.physicalSize = const Size(320, 480);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        bool? result;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    result = await showDialog<bool>(
                      context: context,
                      builder: (_) => const ReservationChargeDialog(
                        charges: BookingCharges(
                          walletBalance: 1500,
                          pendingCancellationFees: 500,
                        ),
                      ),
                    );
                  },
                  child: const Text('Book'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Book'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text(confirm ? 'Confirm booking' : 'Cancel'));
        await tester.pumpAndSettle();
        expect(result, confirm);
      },
    );
  }
}
