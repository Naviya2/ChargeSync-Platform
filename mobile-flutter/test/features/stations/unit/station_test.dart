import 'package:flutter_test/flutter_test.dart';
import 'package:chargesync/features/stations/models/station.dart';

void main() {
  group('Station Model Tests', () {
    final stationJson = {
      'id': 'st-123',
      'name': 'Super Station',
      'address': '123 Test Ave',
      'latitude': 45.123,
      'longitude': -120.456,
      'ownerId': 'owner-456',
      'status': 'Active',
      'rejectionReason': null,
      'documentUrls': ['http://doc1.com'],
      'chargers': [
        {
          'id': 'chg-1',
          'stationId': 'st-123',
          'identifier': 'C-1',
          'bayLabel': 'Bay 1',
          'connector': 'CCS2',
          'powerKw': 150.0,
          'tariff': 0.45,
          'status': 'Available',
        },
      ],
    };

    test('fromJson correctly parses JSON', () {
      final station = Station.fromJson(stationJson);

      expect(station.id, 'st-123');
      expect(station.name, 'Super Station');
      expect(station.latitude, 45.123);
      expect(station.documentUrls?.first, 'http://doc1.com');

      expect(station.chargers, isNotNull);
      expect(station.chargers!.length, 1);
      expect(station.chargers!.first.id, 'chg-1');
      expect(station.chargers!.first.powerKw, 150.0);
    });

    test('toJson returns correct JSON map', () {
      final station = Station.fromJson(stationJson);
      final jsonMap = station.toJson();

      expect(jsonMap['id'], 'st-123');
      expect(jsonMap['name'], 'Super Station');
      expect(jsonMap['chargers'], isA<List>());
      expect((jsonMap['chargers'] as List).first['connector'], 'CCS2');
      expect((jsonMap['documentUrls'] as List).first, 'http://doc1.com');
    });
  });
}
