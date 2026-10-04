import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chargesync/features/reservations/screens/waitlist_screen.dart';

void main() {
  testWidgets('WaitlistScreen shows loading initially', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: WaitlistScreen(),
    ));

    // Initially should show loading indicator since it fetches data on init
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    
    // We don't pump further to avoid hitting actual API calls in the init state
  });
}
