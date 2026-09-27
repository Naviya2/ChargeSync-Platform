import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../features/payments/models/payment_models.dart';
import 'api_config.dart';

class SessionApiClient {
  SessionApiClient._();
  static final SessionApiClient instance = SessionApiClient._();

  final _storage = const FlutterSecureStorage();

  Future<String?> _getAccessToken() =>
      _storage.read(key: ApiConfig.kAccessToken);

  Future<SessionCompletion> stopSession({
    required String sessionId,
    double? staffOverriddenKwh,
  }) async {
    final token = await _getAccessToken();
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('${ApiConfig.baseUrl}/api/sessions/$sessionId/stop'),
    );
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (staffOverriddenKwh != null) {
      request.fields['staffOverriddenKwh'] = staffOverriddenKwh.toStringAsFixed(
        3,
      );
    }

    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return SessionCompletion.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception(_errorMessage(response));
  }

  Future<List<ChargingSessionSummary>> getActiveSessions() async {
    final token = await _getAccessToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/sessions?status=InProgress'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body) as List<dynamic>;
      return decoded
          .map(
            (item) =>
                ChargingSessionSummary.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }
    throw Exception(_errorMessage(response));
  }

  String _errorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['detail'] as String? ??
          body['title'] as String? ??
          'Request failed (${response.statusCode})';
    } catch (_) {
      return 'Request failed (${response.statusCode})';
    }
  }
}
