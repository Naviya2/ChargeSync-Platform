import 'package:flutter/material.dart';

import '../../../core/api/reservation_models.dart';

class ReservationChargeDialog extends StatelessWidget {
  const ReservationChargeDialog({super.key, required this.charges});

  final BookingCharges charges;
  static const double advanceAmount = 500;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Confirm Reservation'),
    scrollable: true,
    content: Text(
      'Advance: LKR ${advanceAmount.toStringAsFixed(2)}\n'
      'Outstanding cancellation fees: LKR ${charges.pendingCancellationFees.toStringAsFixed(2)}\n'
      'Total wallet deduction: LKR ${(advanceAmount + charges.pendingCancellationFees).toStringAsFixed(2)}\n'
      'Available balance: LKR ${charges.walletBalance.toStringAsFixed(2)}\n\n'
      'Only the advance is applied to your charging bill. Cancellation fees are non-refundable.\n\n'
      'If you cancel less than 2 hours before the booked start (including after it), '
      'your advance is refunded and a LKR 500 fee is added to your next booking. '
      'Each late cancellation adds a fee. Cancellation 2 hours or more before start is free.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: () => Navigator.pop(context, true),
        child: const Text('Confirm booking'),
      ),
    ],
  );
}
