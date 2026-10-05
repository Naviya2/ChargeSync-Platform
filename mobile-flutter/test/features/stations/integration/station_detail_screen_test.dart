import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chargesync/features/stations/screens/station_detail_screen.dart';

void main() {
  group('StationDetailScreen Widget Tests', () {
    testWidgets('renders loading state initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StationDetailScreen(stationId: 'st-123'),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
