import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_api_client.dart';
import 'auth_models.dart';
import 'station_models.dart';

/// HTTP client for all station-related API calls.
class StationApiClient {
  StationApiClient._();
  static final StationApiClient instance = StationApiClient._();

  final _client = http.Client();
  final _auth   = AuthApiClient.instance;

  // ── Endpoints ─────────────────────────────────────────────────────────────────

  /// GET /api/stations  — returns stations owned by the logged-in StationOwner.
  Future<List<StationDto>> getMyStations() async {
    final token    = await _auth.getAccessToken();
    final response = await _getWithRetry(ApiConfig.myStations, token);
    final list     = jsonDecode(response.body) as List<dynamic>;
    return list.map((e) => StationDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /api/stations/all  — returns all approved stations (public/EV driver view).
  Future<List<StationDto>> getAllStations() async {
    final response = await _get(ApiConfig.allStations, null);
    final list     = jsonDecode(response.body) as List<dynamic>;
    return list.map((e) => StationDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /api/stations/search?query=...&latitude=...&longitude=...&radiusKm=...
  Future<List<StationDto>> searchStations({
    double? latitude,
    double? longitude,
    double radiusKm = 25,
    String? query,
  }) async {
    final params = <String, String>{
      'radiusKm': radiusKm.toString(),
      if (latitude  != null) 'latitude':  latitude.toString(),
      if (longitude != null) 'longitude': longitude.toString(),
      if (query     != null && query.isNotEmpty) 'query': query,
    };
    final uri      = Uri.parse(ApiConfig.searchStations).replace(queryParameters: params);
    final response = await _get(uri.toString(), null);
    final list     = jsonDecode(response.body) as List<dynamic>;
    return list.map((e) => StationDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Private helpers ───────────────────────────────────────────────────────────

  Future<http.Response> _get(String url, String? token) async {
    final headers = <String, String>{
      HttpHeaders.acceptHeader: 'application/json',
      if (token != null) HttpHeaders.authorizationHeader: 'Bearer $token',
    };
    try {
      final response = await _client
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));
      _checkStatus(response);
      return response;
    } on SocketException {
      throw const ApiException(0, 'Network unreachable');
    } on ApiException {
      rethrow;
    } on Exception {
      throw const ApiException(0, 'Request timed out');
    }
  }

  Future<http.Response> _getWithRetry(String url, String? token) async {
    var response = await _get(url, token);

    if (response.statusCode == 401) {
      final refreshToken = await _auth.getRefreshToken();
      if (refreshToken != null) {
        try {
          final refreshed = await _auth.refresh(refreshToken);
          response = await _get(url, refreshed.accessToken);
        } catch (_) {
          await _auth.clearTokens();
          throw const ApiException(401, 'Session expired. Please sign in again.');
        }
      }
    }

    return response;
  }

  void _checkStatus(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    String msg = '';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      msg = (body['title'] ?? body['detail'] ?? body['message'] ?? '') as String;
    } catch (_) {
      msg = response.body;
    }
    throw ApiException(response.statusCode, msg);
  }
}
