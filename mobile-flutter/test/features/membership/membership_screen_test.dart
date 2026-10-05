import 'dart:convert';

import 'package:chargesync/features/membership/screens/membership_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/student4_http.dart';

class MembershipFixture {
  bool loadFails = false;
  bool actionFails = false;
  bool redemptionFailsOnce = false;
  int points = 6000;
  List<Map<String, dynamic>> subscriptions = [];
  List<Map<String, dynamic>> redemptions = [];
  final writes = <http.Request>[];

  Map<String, dynamic> subscription({String status = 'Active'}) => {
    'id': 'subscription-1',
    'planId': 'old-plan',
    'planName': 'Basic',
    'status': status,
    'discountPercentage': 2,
    'startDate': DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String(),
    'endDate': DateTime.now().add(const Duration(days: 20)).toIso8601String(),
    'feePaid': 100,
    'creditApplied': 0,
  };

  Future<http.Response> respond(http.Request request) async {
    expect(request.headers['authorization'], 'Bearer test-token');
    final path = request.url.path.replaceFirst('/api/', '');
    if (request.method != 'GET') {
      writes.add(request);
      if (actionFails)
        return jsonResponse({'detail': 'Insufficient wallet funds'}, 400);
      if (path == 'loyalty/redeem') {
        if (redemptionFailsOnce &&
            writes.where((r) => r.url.path.endsWith('/redeem')).length == 1) {
          return jsonResponse({'detail': 'Please retry the request'}, 503);
        }
        redemptions = [
          {
            'rewardDescription': 'Large reward',
            'pointsRedeemed': 5500,
            'createdAt': DateTime.now().toIso8601String(),
            'status': 'Pending',
          },
        ];
        points -= 5500;
      } else if (request.method == 'DELETE') {
        subscriptions = [subscription(status: 'Cancelled')];
      } else {
        subscriptions = [
          {...subscription(), 'planId': 'plus', 'planName': 'Plus'},
        ];
      }
      return jsonResponse({});
    }
    if (loadFails)
      return jsonResponse({'detail': 'Membership service unavailable'}, 503);
    return jsonResponse(switch (path) {
      'membership-plans' => [
        {
          'id': 'plus',
          'name': 'Plus',
          'monthlyFee': 500,
          'discountPercentage': 5,
          'description': 'Plus benefits',
        },
      ],
      'subscriptions' => subscriptions,
      'loyalty/me' => {
        'tier': 'Gold',
        'pointsBalance': points,
        'lifetimePoints': 7000,
        'walletBalance': 1000,
      },
      'loyalty/rewards' => [
        {
          'id': 'reward-1',
          'name': 'Large reward',
          'pointsCost': 5500,
          'requiresApproval': true,
        },
      ],
      'loyalty/history' => [],
      'loyalty/redemptions' => redemptions,
      _ => throw StateError('Unexpected endpoint: $path'),
    });
  }
}

void main() {
  setUp(prepareStudent4Test);

  testWidgets('M01: shows loyalty balance, tier and current membership', (
    tester,
  ) async {
    final fixture = MembershipFixture();
    fixture.subscriptions = [fixture.subscription()];
    await http.runWithClient(() async {
      await showTestScreen(tester, const MembershipScreen());
      expect(find.text('Gold member'), findsOneWidget);
      expect(find.text('6000 points'), findsOneWidget);
      expect(find.text('Wallet: LKR 1000.00'), findsOneWidget);
      expect(find.text('Basic'), findsOneWidget);
      expect(find.text('Cancel membership'), findsOneWidget);
    }, () => MockClient(fixture.respond));
  });

  testWidgets(
    'M02: subscribing requires confirmation and posts the selected plan',
    (tester) async {
      final fixture = MembershipFixture();
      await http.runWithClient(() async {
        await showTestScreen(tester, const MembershipScreen());
        await tapVisible(tester, find.text('Subscribe'));
        expect(fixture.writes, isEmpty);
        await tapVisible(tester, find.text('Confirm'));
        expect(fixture.writes.single.method, 'POST');
        expect(fixture.writes.single.url.path, '/api/subscriptions');
        expect(jsonDecode(fixture.writes.single.body), {'planId': 'plus'});
        expect(find.text('Current plan'), findsOneWidget);
        expect(find.text('Saved successfully.'), findsOneWidget);
      }, () => MockClient(fixture.respond));
    },
  );

  testWidgets(
    'M03: Back in the confirmation dialog makes no subscription request',
    (tester) async {
      final fixture = MembershipFixture();
      await http.runWithClient(() async {
        await showTestScreen(tester, const MembershipScreen());
        await tapVisible(tester, find.text('Subscribe'));
        await tapVisible(tester, find.text('Back'));
        expect(fixture.writes, isEmpty);
        expect(
          find.text('Pay as you go. No paid membership active.'),
          findsOneWidget,
        );
      }, () => MockClient(fixture.respond));
    },
  );

  testWidgets(
    'M04: subscription failure displays server error without success',
    (tester) async {
      final fixture = MembershipFixture()..actionFails = true;
      await http.runWithClient(() async {
        await showTestScreen(tester, const MembershipScreen());
        await tapVisible(tester, find.text('Subscribe'));
        await tapVisible(tester, find.text('Confirm'));
        expect(find.text('Insufficient wallet funds'), findsOneWidget);
        expect(find.text('Saved successfully.'), findsNothing);
        expect(
          find.text('Pay as you go. No paid membership active.'),
          findsOneWidget,
        );
      }, () => MockClient(fixture.respond));
    },
  );

  testWidgets(
    'M05: changing plan puts the selected plan to the existing subscription',
    (tester) async {
      final fixture = MembershipFixture();
      fixture.subscriptions = [fixture.subscription()];
      await http.runWithClient(() async {
        await showTestScreen(tester, const MembershipScreen());
        await tapVisible(tester, find.text('Change plan'));
        await tapVisible(tester, find.text('Confirm'));
        expect(fixture.writes.single.method, 'PUT');
        expect(
          fixture.writes.single.url.path,
          '/api/subscriptions/subscription-1/change',
        );
        expect(jsonDecode(fixture.writes.single.body), {'planId': 'plus'});
        expect(find.text('Current plan'), findsOneWidget);
      }, () => MockClient(fixture.respond));
    },
  );

  testWidgets('M06: cancelling sends DELETE and retains unexpired benefits', (
    tester,
  ) async {
    final fixture = MembershipFixture();
    fixture.subscriptions = [fixture.subscription()];
    await http.runWithClient(() async {
      await showTestScreen(tester, const MembershipScreen());
      await tapVisible(tester, find.text('Cancel membership'));
      await tapVisible(tester, find.text('Confirm'));
      expect(fixture.writes.single.method, 'DELETE');
      expect(
        fixture.writes.single.url.path,
        '/api/subscriptions/subscription-1',
      );
      expect(find.text('Basic'), findsOneWidget);
      expect(find.text('2% charging discount • Cancelled'), findsOneWidget);
      expect(find.text('Cancel membership'), findsNothing);
    }, () => MockClient(fixture.respond));
  });

  testWidgets('M07: failed initial load can be retried using Refresh', (
    tester,
  ) async {
    final fixture = MembershipFixture()..loadFails = true;
    await http.runWithClient(() async {
      await showTestScreen(tester, const MembershipScreen());
      expect(find.text('Membership service unavailable'), findsOneWidget);
      fixture.loadFails = false;
      await tapVisible(tester, find.text('Refresh'));
      expect(find.text('Membership service unavailable'), findsNothing);
      expect(find.text('6000 points'), findsOneWidget);
    }, () => MockClient(fixture.respond));
  });

  testWidgets('L01: insufficient points disable redemption', (tester) async {
    final fixture = MembershipFixture()..points = 100;
    await http.runWithClient(() async {
      await showTestScreen(tester, const MembershipScreen());
      final button = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Redeem'),
      );
      expect(button.onPressed, isNull);
      expect(fixture.writes, isEmpty);
    }, () => MockClient(fixture.respond));
  });

  testWidgets(
    'L02: confirmed reward posts its ID and displays pending approval',
    (tester) async {
      final fixture = MembershipFixture();
      await http.runWithClient(() async {
        await showTestScreen(tester, const MembershipScreen());
        await tapVisible(tester, find.text('Redeem'));
        expect(
          find.textContaining('Credit is issued only after admin approval.'),
          findsOneWidget,
        );
        expect(fixture.writes, isEmpty);
        await tapVisible(tester, find.text('Confirm'));
        final body = jsonDecode(fixture.writes.single.body) as Map;
        expect(fixture.writes.single.url.path, '/api/loyalty/redeem');
        expect(body['rewardId'], 'reward-1');
        expect(
          body['requestId'],
          matches(
            RegExp(
              r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
            ),
          ),
        );
        expect(find.text('Pending'), findsOneWidget);
        expect(find.text('500 points'), findsOneWidget);
      }, () => MockClient(fixture.respond));
    },
  );

  testWidgets('L03: retry after redemption error reuses the same request ID', (
    tester,
  ) async {
    final fixture = MembershipFixture()..redemptionFailsOnce = true;
    await http.runWithClient(() async {
      await showTestScreen(tester, const MembershipScreen());
      await tapVisible(tester, find.text('Redeem'));
      await tapVisible(tester, find.text('Confirm'));
      expect(find.text('Please retry the request'), findsOneWidget);
      expect(find.text('6000 points'), findsOneWidget);
      await tapVisible(tester, find.text('Redeem'));
      await tapVisible(tester, find.text('Confirm'));
      expect(fixture.writes, hasLength(2));
      expect(
        jsonDecode(fixture.writes[0].body)['requestId'],
        jsonDecode(fixture.writes[1].body)['requestId'],
      );
      expect(find.text('Pending'), findsOneWidget);
    }, () => MockClient(fixture.respond));
  });
}
