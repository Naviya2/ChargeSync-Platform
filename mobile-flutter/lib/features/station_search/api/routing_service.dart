import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../core/api/api_config.dart';

class RoutingService {
  RoutingService._();
  static final RoutingService instance = RoutingService._();

  final _storage = const FlutterSecureStorage();
  final _client = http.Client();

  Future<String?> _getAccessToken() => _storage.read(key: ApiConfig.kAccessToken);

  Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> getDirections(
      double originLat, double originLng, double destLat, double destLng) async {
    final token = await _getAccessToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/Routing/directions');
    
    final payload = {
      'origin': {'latitude': originLat, 'longitude': originLng},
      'destination': {'latitude': destLat, 'longitude': destLng}
    };

    final response = await _client.post(
      url,
      headers: _headers(token),
      body: jsonEncode(payload),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw HttpException('HTTP ${response.statusCode}: ${response.body}');
    }
  }
}
