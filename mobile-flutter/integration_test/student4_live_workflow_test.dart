import 'dart:convert';
import 'package:chargesync/core/api/auth_service.dart';
import 'package:chargesync/core/api/reservation_api_client.dart';
import 'package:chargesync/core/api/reservation_models.dart';
import 'package:chargesync/core/api/session_api_client.dart';
import 'package:chargesync/features/membership/api/member_api.dart';
import 'package:chargesync/features/payments/screens/session_checkout_screen.dart';
import 'package:chargesync/features/support/api/support_api.dart';
import 'package:chargesync/features/support/screens/support_tickets_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

// Uses real HTTP, browser secure storage, production screens and the real AI.
// Booking and QR check-in use the real API; camera hardware is outside this test.
const bridge = 'http://127.0.0.1:4567';
const bridgeToken = String.fromEnvironment('E2E_BRIDGE_TOKEN');

Future<Map<String, dynamic>> coordinator(
  String path, {
  Map<String, dynamic>? body,
}) async {
  final headers = {
    'X-E2E-Token': bridgeToken,
    'Content-Type': 'application/json',
  };
  final response = body == null
      ? await http.get(Uri.parse('$bridge/$path'), headers: headers)
      : await http.post(
          Uri.parse('$bridge/$path'),
          headers: headers,
          body: jsonEncode(body),
        );
  if (response.statusCode != 200) {
    throw StateError('E2E coordinator failed (${response.statusCode}).');
  }
  return jsonDecode(response.body) as Map<String, dynamic>;
}

Future<void> waitFor(
  WidgetTester tester,
  Finder finder,
  String description, {
  int seconds = 60,
}) async {
  final deadline = DateTime.now().add(Duration(seconds: seconds));
  while (finder.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  expect(finder, findsWidgets, reason: description);
}

Finder field(String label) => find.widgetWithText(TextFormField, label);

Future<void> tapVisible(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(target);
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> signIn(Map<String, dynamic> account) => AuthService.instance
    .login(
      email: account['email'] as String,
      password: account['password'] as String,
    )
    .then((_) {});

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Live checkout, wallet settlement, AI review and React refund approval',
    (tester) async {
      expect(bridgeToken, isNotEmpty, reason: 'Run through e2e/Run.ps1.');
      final config = await coordinator('config');
      debugPrint('E2E: loaded isolated fixture configuration.');
      // Overrides configuration in memory; never reads or changes the ordinary .env.
      dotenv.loadFromString(envString: 'API_URL=${config['apiUrl']}');

      await signIn(Map<String, dynamic>.from(config['driver']));
      final charges = await ReservationApiClient.instance.getBookingCharges();
      expect(charges.walletBalance, config['initialWalletBalance']);
      expect(charges.pendingCancellationFees, 0);

      final now = DateTime.now().toUtc();
      // The test fixture operates until 23:59:59 Sri Lankan time.
      final local = now.add(const Duration(hours: 5, minutes: 30));
      final midnight = DateTime.utc(
        local.year,
        local.month,
        local.day + 1,
      ).subtract(const Duration(hours: 5, minutes: 30, seconds: 2));
      final ordinaryEnd = now.add(const Duration(minutes: 10));
      final end = ordinaryEnd.isBefore(midnight) ? ordinaryEnd : midnight;
      expect(
        end.difference(now).inSeconds,
        greaterThan(60),
        reason: 'Run outside the last minute before midnight.',
      );
      final reservation = await ReservationApiClient.instance.createReservation(
        CreateReservationRequest(
          chargerId: config['chargerId'],
          vehicleId: config['vehicleId'],
          startTime: now,
          endTime: end,
          advanceDepositAmount: 0,
          expectedCancellationFees: charges.pendingCancellationFees,
        ),
      );
      expect(reservation.status, 'Confirmed');
      expect(reservation.reservationQRCode, isNotEmpty);
      debugPrint('E2E: reservation confirmed.');

      await signIn(Map<String, dynamic>.from(config['owner']));
      final checkedIn = await ReservationApiClient.instance.staffCheckin(
        reservation.reservationQRCode!,
      );
      expect(checkedIn.status, 'CheckedIn');
      debugPrint('E2E: staff checked in the reservation.');
      final sessions = await SessionApiClient.instance.getActiveSessions();
      expect(
        sessions,
        hasLength(1),
        reason: 'Use a fresh fixture for each run.',
      );
      final session = sessions.single;

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SessionCheckoutScreen())),
      );
      await waitFor(
        tester,
        find.text('Stop session & generate invoice'),
        'Checkout did not load the active session.',
      );
      // 20 kW at LKR 1000/kWh creates more than LKR 20 of delivered energy.
      await tester.pump(const Duration(seconds: 12));
      await tapVisible(tester, find.text('Stop session & generate invoice'));
      await waitFor(
        tester,
        find.text('Invoice generated'),
        'Session completion did not generate an invoice.',
      );
      await waitFor(
        tester,
        find.textContaining('Confirm LKR'),
        'Wallet settlement button did not appear.',
      );
      await tapVisible(tester, find.textContaining('Confirm LKR'));
      await waitFor(
        tester,
        find.text('Payment recorded • Wallet.'),
        'Wallet settlement failed.',
      );
      debugPrint('E2E: session completed and wallet payment recorded.');
      await tester.pumpWidget(const SizedBox.shrink());

      await signIn(Map<String, dynamic>.from(config['driver']));
      final paid = await SupportApi().paidInvoices();
      expect(paid, hasLength(1));
      final invoice = Map<String, dynamic>.from(paid.single);
      expect(invoice['status'], 'Paid');
      expect(invoice['paymentMethod'], 'Wallet');
      expect(invoice['sessionId'], session.id);
      expect((invoice['grossAmount'] as num).toDouble(), greaterThan(20));
      final wallet =
          await MemberApi.instance.request('wallet') as Map<String, dynamic>;
      final beforeRefund = (wallet['balance'] as num).toDouble();
      expect(
        beforeRefund,
        closeTo(
          (config['initialWalletBalance'] as num).toDouble() -
              (invoice['netAmountDue'] as num).toDouble(),
          0.001,
        ),
      );

      final subject = 'E2E refund ${config['runId']}';
      await tester.pumpWidget(
        const MaterialApp(home: CreateSupportTicketScreen()),
      );
      await tapVisible(
        tester,
        find.byType(DropdownButtonFormField<String>).first,
      );
      await tester.tap(find.text('Refund').last);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(field('Subject'), subject);
      await tester.enterText(
        field('Describe what happened'),
        'Please review my paid charging invoice and refund LKR 20 to my wallet. This is an isolated E2E test.',
      );
      final invoiceLabel = find.textContaining(
        '#${(invoice['id'] as String).split('-').first}',
      );
      await waitFor(
        tester,
        find.byWidgetPredicate(
          (widget) =>
              widget is DropdownButton<String> &&
              (widget.items?.any((item) => item.value == invoice['id']) ??
                  false),
        ),
        'Paid invoice did not load.',
      );
      await tapVisible(
        tester,
        find.byType(DropdownButtonFormField<String>).last,
      );
      await tester.tap(invoiceLabel.last);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.ensureVisible(field('Requested refund (LKR)'));
      await tester.enterText(field('Requested refund (LKR)'), '20');
      await tapVisible(tester, find.text('Submit ticket'));
      await waitFor(
        tester,
        find.byType(SupportTicketDetailScreen),
        'Ticket submission failed.',
      );
      final rows = await SupportApi().list();
      final ticket = Map<String, dynamic>.from(
        rows.singleWhere((row) => row['subject'] == subject),
      );
      expect(ticket['refundStatus'], 'PendingReview');
      debugPrint(
        'E2E: refund ticket submitted; waiting for AI and React approval.',
      );

      await coordinator(
        'review',
        body: {
          'ticketId': ticket['id'],
          'invoiceId': invoice['id'],
          'sessionId': session.id,
          'reservationId': reservation.id,
          'subject': subject,
          'beforeRefund': beforeRefund,
        },
      );
      final deadline = DateTime.now().add(const Duration(minutes: 4));
      Map<String, dynamic> state = {};
      while (DateTime.now().isBefore(deadline)) {
        state = await coordinator('status');
        if (state['status'] == 'failed') fail(state['error'] as String);
        if (state['status'] == 'approved') break;
        await tester.pump(const Duration(seconds: 1));
      }
      expect(
        state['status'],
        'approved',
        reason: 'React approval did not finish within four minutes.',
      );

      final finalTicket = await SupportApi().get(ticket['id']);
      final workflow = await SupportApi().workflow(ticket['id']);
      final finalWallet =
          await MemberApi.instance.request('wallet') as Map<String, dynamic>;
      final updatedInvoices =
          await MemberApi.instance.request('payments/invoices') as List;
      final finalInvoice = updatedInvoices.singleWhere(
        (row) => row['id'] == invoice['id'],
      );
      expect(finalTicket['refundStatus'], 'Approved');
      expect(workflow['workflow']['status'], 'Completed');
      expect(
        (finalWallet['balance'] as num).toDouble(),
        closeTo(beforeRefund + 20, 0.001),
      );
      expect(finalInvoice['refundedAmount'], 20);
      // Reopen the detail screen with a fresh Navigator after pushReplacement.
      // Replacing MaterialApp.home alone leaves the previous pushed route active.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        MaterialApp(home: SupportTicketDetailScreen(ticket: finalTicket)),
      );
      await waitFor(
        tester,
        find.text('Refund: Approved'),
        'Driver does not see the approved refund.',
      );
      binding.reportData = {
        'runId': config['runId'],
        'ticketId': ticket['id'],
        'invoiceId': invoice['id'],
        'status': 'passed',
      };
      await coordinator(
        'complete',
        body: {
          'ticketId': ticket['id'],
          'invoiceId': invoice['id'],
          'sessionId': session.id,
          'reservationId': reservation.id,
          'refundAmount': 20,
        },
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await AuthService.instance.logout();
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );
}
