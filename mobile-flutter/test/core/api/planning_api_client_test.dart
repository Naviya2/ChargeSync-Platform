import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:chargesync/core/api/planning_models.dart';

void main() {
  group('PlanningModels Test', () {
    test('PlanningRequest toJson() correctly formats data', () {
      final deadline = DateTime.utc(2026, 1, 1, 12, 0);
      final request = PlanningRequest(
        deadline: deadline,
        maxDistanceKm: 15.0,
        pricePreference: 'Budget',
      );

      final jsonMap = request.toJson();

      expect(jsonMap['deadline'], '2026-01-01T12:00:00.000Z');
      expect(jsonMap['max_distance_km'], 15.0);
      expect(jsonMap['price_preference'], 'Budget');
    });

    test('PlanningResponse fromJson() correctly parses data', () {
      final jsonResponse = {
        'plan_id': 'plan-123',
        'ranked_itineraries': [
          {
            'station_id': 's-123',
            'station_name': 'Test Station',
            'charger_id': 'c-123',
            'estimated_arrival_time': '2026-01-01T12:00:00.000Z',
            'estimated_charge_duration_mins': 30,
            'waitlist_override_required': true,
            'cost_estimate': 12.50,
            'match_score': 95
          }
        ],
        'requires_approval': true,
        'agent_reasoning': 'Best match due to speed'
      };

      final response = PlanningResponse.fromJson(jsonResponse);

      expect(response.planId, 'plan-123');
      expect(response.requiresApproval, true);
      expect(response.agentReasoning, 'Best match due to speed');
      expect(response.rankedItineraries.length, 1);
      
      final itinerary = response.rankedItineraries.first;
      expect(itinerary.stationId, 's-123');
      expect(itinerary.stationName, 'Test Station');
      expect(itinerary.costEstimate, 12.50);
      expect(itinerary.waitlistOverrideRequired, true);
    });
  });
}
