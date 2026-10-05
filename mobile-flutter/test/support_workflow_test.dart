import 'package:chargesync/features/support/api/support_api.dart';
import 'package:chargesync/features/support/models/workflow_status.dart';
import 'package:chargesync/features/support/screens/support_tickets_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSupportApi extends SupportApi {
  Map<String, dynamic> ticket = {
    'id': 'ticket-1',
    'subject': 'Charging stopped early',
    'category': 'Charging',
    'status': 'Open',
    'priority': 'Medium',
    'refundStatus': 'NotRequested',
    'messages': <dynamic>[],
    'assignedToUserId': null,
  };
  String status = 'Running';
  bool unavailable = false;
  Map<String, dynamic>? submitted;
  String? sent;
  bool invoiceUnavailable = false;
  List<dynamic> invoices = [];
  @override
  Future<List<dynamic>> paidInvoices() async {
    if (invoiceUnavailable) throw Exception('Request failed (401)');
    return invoices;
  }

  @override
  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    submitted = body;
    ticket = {...ticket, ...body};
    return Map.from(ticket);
  }

  @override
  Future<Map<String, dynamic>> get(String id) async => Map.from(ticket);
  @override
  Future<Map<String, dynamic>> workflow(String id) async {
    if (unavailable) throw Exception('Service unavailable');
    return {
      'workflow': {'id': 'run-1', 'status': status},
    };
  }

  @override
  Future<Map<String, dynamic>> message(String id, String body) async {
    sent = body;
    return Map.from(ticket);
  }
}

void main() {
  testWidgets('Invoice error can be retried and distinguishes empty results', (
    tester,
  ) async {
    final api = FakeSupportApi()..invoiceUnavailable = true;
    await tester.pumpWidget(
      MaterialApp(home: CreateSupportTicketScreen(api: api)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Refund').last);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Could not load paid invoices.'),
      findsOneWidget,
    );
    api.invoiceUnavailable = false;
    await tester.ensureVisible(find.text('Refresh invoices'));
    await tester.tap(find.text('Refresh invoices'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No paid invoices found'), findsOneWidget);
    api.invoices = [
      {'id': 'invoice-1', 'stationName': 'Test station', 'grossAmount': 100},
    ];
    await tester.ensureVisible(find.text('Refresh invoices'));
    await tester.tap(find.text('Refresh invoices'));
    await tester.pumpAndSettle();
    final selector = find.byType(DropdownButtonFormField<String>).last;
    await tester.ensureVisible(selector);
    await tester.tap(selector);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test station • LKR 100.00 • #invoice').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('No paid invoices found'), findsNothing);
    expect(find.text('Test station • LKR 100.00 • #invoice'), findsOneWidget);
  });

  test(
    'Completed analysis does not falsely resolve an open ticket or pay a refund',
    () {
      expect(
        SupportWorkflowStatus.fromRecords(
          {'status': 'Open'},
          {'status': 'Completed'},
        ).label,
        'Processing',
      );
      expect(
        SupportWorkflowStatus.fromRecords(
          {'status': 'Open', 'refundStatus': 'PendingReview'},
          {'status': 'Completed'},
        ).label,
        'Pending Approval',
      );
      expect(
        SupportWorkflowStatus.fromRecords(
          {'status': 'Open', 'refundStatus': 'PendingReview'},
          {'status': 'Running'},
        ).label,
        'Processing',
      );
      expect(
        SupportWorkflowStatus.fromRecords(
          {'status': 'Resolved'},
          {'status': 'PendingApproval'},
        ).label,
        'Resolved',
      );
      expect(
        SupportWorkflowStatus.fromRecords(
          {'status': 'Open'},
          {'status': 'Failed'},
        ).label,
        'Failed',
      );
      final rejected = SupportWorkflowStatus.fromRecords(
        {'status': 'Open'},
        {'status': 'Rejected', 'decision': 'Rejected'},
      );
      expect(rejected.label, 'Resolved');
      expect(rejected.description, contains('rejected'));
    },
  );

  testWidgets(
    'Submission opens details and refreshes Processing to Pending Approval',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      final api = FakeSupportApi();
      await tester.pumpWidget(
        MaterialApp(home: CreateSupportTicketScreen(api: api)),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Charging stopped early',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Please check my charging session.',
      );
      await tester.ensureVisible(find.text('Submit ticket'));
      await tester.tap(find.text('Submit ticket'));
      await tester.pumpAndSettle();
      expect(api.submitted?['subject'], 'Charging stopped early');
      expect(find.text('Ticket details'), findsOneWidget);
      expect(find.text('Processing'), findsOneWidget);
      api.status = 'PendingApproval';
      await tester.pump(const Duration(seconds: 11));
      await tester.pumpAndSettle();
      expect(find.text('Pending Approval'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Refresh preserves draft and failed workflow still allows replies',
    (tester) async {
      final api = FakeSupportApi();
      await tester.pumpWidget(
        MaterialApp(
          home: SupportTicketDetailScreen(ticket: api.ticket, api: api),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'Please review this manually.',
      );
      api.status = 'Failed';
      await tester.tap(find.byTooltip('Refresh ticket status'));
      await tester.pumpAndSettle();
      expect(find.text('Failed'), findsOneWidget);
      expect(find.text('Please review this manually.'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();
      expect(api.sent, 'Please review this manually.');
      api.ticket['status'] = 'Resolved';
      await tester.tap(find.byTooltip('Refresh ticket status'));
      await tester.pumpAndSettle();
      expect(find.text('Resolved'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Workflow endpoint failure keeps ticket and reply composer available',
    (tester) async {
      final api = FakeSupportApi()..unavailable = true;
      await tester.pumpWidget(
        MaterialApp(
          home: SupportTicketDetailScreen(ticket: api.ticket, api: api),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Charging stopped early'), findsOneWidget);
      expect(find.text('Status unavailable'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
