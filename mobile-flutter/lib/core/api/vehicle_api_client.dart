import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_service.dart';
import 'vehicle_models.dart';

class VehicleApiClient {
  VehicleApiClient._();
  static final VehicleApiClient instance = VehicleApiClient._();

  Future<Map<String, String>> get _headers async {
    final token = await AuthService.instance.token;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  String _extractErrorMessage(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        if (decoded['message'] != null && decoded['message'].toString().isNotEmpty) {
          return decoded['message'].toString();
        }
        if (decoded['detail'] != null && decoded['detail'].toString().isNotEmpty) {
          return decoded['detail'].toString();
        }
        if (decoded['title'] != null) {
          if (decoded['errors'] is Map) {
            final errorMap = decoded['errors'] as Map;
            final errorList = errorMap.values
                .expand((v) => v is List ? v : [v])
                .map((e) => e.toString())
                .where((s) => s.isNotEmpty)
                .toList();
            if (errorList.isNotEmpty) {
              return errorList.join('\n');
            }
          }
          return decoded['title'].toString();
        }
      }
    } catch (_) {}
    return fallback;
  }

  /// Get all registered vehicles owned by the current driver (FR-1.2)
  Future<List<Vehicle>> getMyVehicles() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/vehicles'),
      headers: await _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((json) => Vehicle.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      final errorMsg = _extractErrorMessage(response, 'Failed to load vehicles (${response.statusCode})');
      throw Exception(errorMsg);
    }
  }

  /// Get a single vehicle by ID (FR-1.2)
  Future<Vehicle?> getVehicleById(String vehicleId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/vehicles/$vehicleId'),
      headers: await _headers,
    );

    if (response.statusCode == 200) {
      return Vehicle.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      final errorMsg = _extractErrorMessage(response, 'Failed to load vehicle (${response.statusCode})');
      throw Exception(errorMsg);
    }
  }

  /// Register a new vehicle (FR-1.1)
  Future<Vehicle> createVehicle(VehicleRequest request) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/vehicles'),
      headers: await _headers,
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Vehicle.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      final errorMsg = _extractErrorMessage(response, 'Failed to register vehicle (${response.statusCode})');
      throw Exception(errorMsg);
    }
  }

  /// Update vehicle details (FR-1.2)
  Future<Vehicle> updateVehicle(String vehicleId, VehicleRequest request) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/api/vehicles/$vehicleId'),
      headers: await _headers,
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return Vehicle.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      final errorMsg = _extractErrorMessage(response, 'Failed to update vehicle (${response.statusCode})');
      throw Exception(errorMsg);
    }
  }

  /// Delete a registered vehicle (FR-1.2)
  Future<bool> deleteVehicle(String vehicleId) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/vehicles/$vehicleId'),
      headers: await _headers,
    );

    if (response.statusCode == 204 || response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 404) {
      return false;
    } else {
      final errorMsg = _extractErrorMessage(response, 'Failed to delete vehicle.');
      throw Exception(errorMsg);
    }
  }

  /// Find compatible stations with calculated score & estimated charge time for vehicle (FR-1.3)
  Future<List<CompatibleStation>> getCompatibleStations({
    required String vehicleId,
    required double latitude,
    required double longitude,
    double radiusKm = 25,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/vehicles/$vehicleId/compatible-stations').replace(
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'radiusKm': radiusKm.toString(),
      },
    );

    final response = await http.get(uri, headers: await _headers);

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((json) => CompatibleStation.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      final errorMsg = _extractErrorMessage(response, 'Failed to load compatible stations.');
      throw Exception(errorMsg);
    }
  }

  /// Search nearby stations directly with connector type and distance filters (FR-1.5)
  Future<List<dynamic>> searchNearbyStations({
    double? latitude,
    double? longitude,
    double radiusKm = 25,
    ConnectorType? connector,
    String? query,
  }) async {
    final queryParams = <String, String>{
      'radiusKm': radiusKm.toString(),
      if (latitude != null) 'latitude': latitude.toString(),
      if (longitude != null) 'longitude': longitude.toString(),
      if (connector != null) 'connector': connector.toBackendString(),
      if (query != null && query.isNotEmpty) 'query': query,
    };

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/stations/search').replace(
      queryParameters: queryParams,
    );

    final response = await http.get(uri, headers: await _headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      // Fallback to all stations if search endpoint unavailable
      final fallbackUri = Uri.parse('${ApiConfig.baseUrl}/api/stations/all');
      final fallbackRes = await http.get(fallbackUri, headers: await _headers);
      if (fallbackRes.statusCode == 200) {
        return jsonDecode(fallbackRes.body) as List<dynamic>;
      }
      throw Exception('Failed to fetch stations.');
    }
  }
}
