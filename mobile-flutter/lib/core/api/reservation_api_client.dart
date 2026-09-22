import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'reservation_models.dart';

class ReservationApiClient {
  ReservationApiClient._();
  static final ReservationApiClient instance = ReservationApiClient._();

  final _storage = const FlutterSecureStorage();
  final _client = http.Client();

  Future<String?> _getAccessToken() => _storage.read(key: ApiConfig.kAccessToken);

  Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final token = await _getAccessToken();
    final url = Uri.parse('${ApiConfig.baseUrl}$path');
    final response = await _client.get(url, headers: _headers(token));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw HttpException('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic>? body) async {
    final token = await _getAccessToken();
    final url = Uri.parse('${ApiConfig.baseUrl}$path');
    final response = await _client.post(
      url,
      headers: _headers(token),
      body: body != null ? jsonEncode(body) : null,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw HttpException('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  Future<void> _put(String path) async {
    final token = await _getAccessToken();
    final url = Uri.parse('${ApiConfig.baseUrl}$path');
    final response = await _client.put(url, headers: _headers(token));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  // ── Endpoints ─────────────────────────────────────────────────────────────

  Future<ReservationDto> createReservation(CreateReservationRequest request) async {
    final result = await _post('/api/reservations', request.toJson());
    return ReservationDto.fromJson(result);
  }

  Future<ReservationDto> createWalkIn(String chargerId, DateTime startTime, DateTime endTime) async {
    final result = await _post('/api/reservations/walk-in', {
      'chargerId': chargerId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
    });
    return ReservationDto.fromJson(result);
  }

  Future<ReservationDto> staffCheckin(String qrCode) async {
    final result = await _post('/api/reservations/staff-checkin', {
      'qrCode': qrCode,
    });
    return ReservationDto.fromJson(result);
  }

  Future<PagedResult<ReservationDto>> getMyReservations() async {
    final result = await _get('/api/reservations'); // Backend filters by current user
    return PagedResult.fromJson(result, (json) => ReservationDto.fromJson(json));
  }

  Future<void> cancelReservation(String id) async {
    await _put('/api/reservations/$id/cancel');
  }

  Future<WaitlistEntryDto> joinWaitlist(JoinWaitlistRequest request) async {
    final result = await _post('/api/waitlist', request.toJson());
    return WaitlistEntryDto.fromJson(result);
  }

  Future<List<WaitlistEntryDto>> getMyWaitlist() async {
    final result = await _get('/api/waitlist/mine');
    // The endpoint returns a list, not a PagedResult for waitlist mine? Let's check backend WaitlistController.
    // Yes, GetMine returns Task<ActionResult<IReadOnlyList<WaitlistEntryDto>>>
    throw UnimplementedError('We will handle lists in another helper if needed.');
  }

  Future<List<WaitlistEntryDto>> getMyWaitlistList() async {
    final token = await _getAccessToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/waitlist/mine');
    final response = await _client.get(url, headers: _headers(token));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List decoded = jsonDecode(response.body);
      return decoded.map((e) => WaitlistEntryDto.fromJson(e)).toList();
    } else {
      throw HttpException('HTTP ${response.statusCode}: ${response.body}');
    }
  }
}
