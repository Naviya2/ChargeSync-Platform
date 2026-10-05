import 'package:flutter_test/flutter_test.dart';
import 'package:chargesync/features/stations/models/charger.dart';

void main() {
  group('Charger Model Tests', () {
    final chargerJson = {
      'id': 'chg-123',
      'stationId': 'st-123',
      'identifier': 'CHG-01',
      'bayLabel': 'Bay 1',
      'connector': 'CCS2',
      'powerKw': 50.0,
      'tariff': 0.55,
      'status': 'InUse'
    };

    test('fromJson correctly parses JSON', () {
      final charger = Charger.fromJson(chargerJson);
      
      expect(charger.id, 'chg-123');
      expect(charger.stationId, 'st-123');
      expect(charger.identifier, 'CHG-01');
      expect(charger.bayLabel, 'Bay 1');
      expect(charger.connector, 'CCS2');
      expect(charger.powerKw, 50.0);
      expect(charger.tariff, 0.55);
      expect(charger.status, 'InUse');
    });

    test('toJson returns correct JSON map', () {
      final charger = Charger.fromJson(chargerJson);
      final jsonMap = charger.toJson();

      expect(jsonMap['id'], 'chg-123');
      expect(jsonMap['stationId'], 'st-123');
      expect(jsonMap['identifier'], 'CHG-01');
      expect(jsonMap['powerKw'], 50.0);
      expect(jsonMap['status'], 'InUse');
    });
  });
}
