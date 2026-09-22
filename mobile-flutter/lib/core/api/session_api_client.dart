import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';

/// Calls Function 4's session stop endpoint with an optional kWh override and meter photo.
/// Endpoint: PUT /api/sessions/{id}/stop  (multipart/form-data)
class SessionApiClient {
  SessionApiClient._();
  static final SessionApiClient instance = SessionApiClient._();

  final _storage = const FlutterSecureStorage();

  Future<String?> _getAccessToken() => _storage.read(key: ApiConfig.kAccessToken);

  // ── Stop session with optional kWh override + meter photo ────────────────────
  Future<Map<String, dynamic>> stopSessionWithOverride({
    required String sessionId,
    required double staffOverriddenKwh,
    File? meterPhoto,
  }) async {
    final token = await _getAccessToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/sessions/$sessionId/stop');

    final request = http.MultipartRequest('PUT', url);

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Add the kWh override as a form field
    request.fields['staffOverriddenKwh'] = staffOverriddenKwh.toStringAsFixed(2);

    // Attach the meter photo if provided
    if (meterPhoto != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'meterPhoto',
          meterPhoto.path,
          filename: 'meter_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw HttpException('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  // ── List active sessions (for staff to pick which session to override) ────────
  Future<List<Map<String, dynamic>>> getActiveSessions() async {
    final token = await _getAccessToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/sessions?status=InProgress');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List decoded = jsonDecode(response.body);
      return decoded.cast<Map<String, dynamic>>();
    } else {
      throw HttpException('HTTP ${response.statusCode}: ${response.body}');
    }
  }
}
