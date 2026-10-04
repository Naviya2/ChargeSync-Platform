import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:chargesync/core/api/planning_models.dart';
import 'package:chargesync/core/api/planning_api_client.dart';
import 'package:chargesync/core/api/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  group('PlanningApiClient Http Tests', () {
    setUp(() async {
      PlanningApiClient.instance.tokenProvider = () async => 'fake_token';
    });

    test('generateChargingPlan returns PlanningResponse on 200', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/api/charging-plan/generate')) {
          return http.Response(
            jsonEncode({
              'plan_id': 'mock-plan-123',
              'ranked_itineraries': [
                {
                  'station_id': 's-123',
                  'station_name': 'Mock Station',
                  'charger_id': 'c-1',
                  'estimated_arrival_time': '2026-01-01T12:00:00.000Z',
                  'estimated_charge_duration_mins': 15,
                  'waitlist_override_required': false,
                  'cost_estimate': 10.0,
                  'match_score': 100
                }
              ],
              'requires_approval': false,
              'agent_reasoning': 'Mocked reasoning'
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      PlanningApiClient.instance.httpClient = mockClient;

      final request = PlanningRequest(
        deadline: DateTime.utc(2026, 1, 1),
        maxDistanceKm: 10,
        pricePreference: 'Speed'
      );

      final response = await PlanningApiClient.instance.generateChargingPlan(request);
      
      expect(response.planId, 'mock-plan-123');
      expect(response.agentReasoning, 'Mocked reasoning');
      expect(response.rankedItineraries.length, 1);
      expect(response.rankedItineraries[0].stationName, 'Mock Station');
    });

    test('generateChargingPlan throws Exception on 500', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      PlanningApiClient.instance.httpClient = mockClient;

      final request = PlanningRequest(
        deadline: DateTime.utc(2026, 1, 1),
      );

      expect(
        () => PlanningApiClient.instance.generateChargingPlan(request),
        throwsA(isA<Exception>()),
      );
    });
  });
}
