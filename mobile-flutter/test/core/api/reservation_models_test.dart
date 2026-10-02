import 'package:flutter_test/flutter_test.dart';
import 'package:chargesync/core/api/reservation_models.dart';

void main() {
  group('ReservationDto Tests', () {
    test('fromJson correctly parses JSON', () {
      final json = {
        'id': 'res-1',
        'chargerId': 'charger-1',
        'startTime': '2026-10-01T10:00:00Z',
        'endTime': '2026-10-01T11:00:00Z',
        'advanceDepositAmount': 5.0,
        'status': 'Confirmed',
        'stationName': 'Station A',
      };
      
      final dto = ReservationDto.fromJson(json);
      
      expect(dto.id, 'res-1');
      expect(dto.chargerId, 'charger-1');
      expect(dto.advanceDepositAmount, 5.0);
      expect(dto.status, 'Confirmed');
      expect(dto.stationName, 'Station A');
    });
  });

  group('CreateReservationRequest Tests', () {
    test('toJson returns correct map', () {
      final req = CreateReservationRequest(
        chargerId: 'charger-1',
        startTime: DateTime.utc(2026, 10, 1, 10),
        endTime: DateTime.utc(2026, 10, 1, 11),
        advanceDepositAmount: 5.0,
      );

      final json = req.toJson();
      
      expect(json['chargerId'], 'charger-1');
      expect(json['startTime'], '2026-10-01T10:00:00.000Z');
      expect(json['advanceDepositAmount'], 5.0);
    });
  });
  
  group('WaitlistEntryDto Tests', () {
    test('fromJson correctly parses JSON', () {
      final json = {
        'id': 'wl-1',
        'chargerId': 'charger-1',
        'driverId': 'drv-1',
        'requestedStartTime': '2026-10-01T10:00:00Z',
        'priority': 1,
        'status': 'Waiting',
      };
      
      final dto = WaitlistEntryDto.fromJson(json);
      
      expect(dto.id, 'wl-1');
      expect(dto.chargerId, 'charger-1');
      expect(dto.priority, 1);
      expect(dto.status, 'Waiting');
    });
  });

  group('JoinWaitlistRequest Tests', () {
    test('toJson returns correct map', () {
      final req = JoinWaitlistRequest(
        chargerId: 'charger-1',
        requestedStartTime: DateTime.utc(2026, 10, 1, 10),
        maxPriceWillingToPay: 10.0,
        pricePreference: 'Budget',
      );

      final json = req.toJson();
      
      expect(json['chargerId'], 'charger-1');
      expect(json['maxPriceWillingToPay'], 10.0);
      expect(json['pricePreference'], 'Budget');
    });
  });
}
