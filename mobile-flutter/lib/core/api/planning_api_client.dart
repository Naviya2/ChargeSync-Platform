import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_service.dart';
import 'planning_models.dart';

class PlanningApiClient {
  PlanningApiClient._privateConstructor();
  static final PlanningApiClient instance = PlanningApiClient._privateConstructor();

  Future<PlanningResponse> generateChargingPlan(PlanningRequest request) async {
    final token = await AuthService.instance.token;
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/api/charging-plan/generate');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(response.body);
      return PlanningResponse.fromJson(jsonMap);
    } else {
      throw Exception('Failed to generate charging plan: ${response.statusCode}');
    }
  }
}
