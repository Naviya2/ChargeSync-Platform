import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../core/api/api_config.dart';
import '../models/station.dart';
import '../models/charger.dart';

class StationService {
  StationService._();
  static final StationService instance = StationService._();

  final _storage = const FlutterSecureStorage();
  final _client = http.Client();

  Future<String?> _getAccessToken() => _storage.read(key: ApiConfig.kAccessToken);

  Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> _get(String path) async {
    final token = await _getAccessToken();
    final url = Uri.parse('${ApiConfig.baseUrl}$path');
    final response = await _client.get(url, headers: _headers(token));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      throw HttpException('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final token = await _getAccessToken();
    final url = Uri.parse('${ApiConfig.baseUrl}$path');
    final response = await _client.post(
      url,
      headers: _headers(token),
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      throw HttpException('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  Future<dynamic> _put(String path, dynamic body) async {
    final token = await _getAccessToken();
    final url = Uri.parse('${ApiConfig.baseUrl}$path');
    final response = await _client.put(
      url,
      headers: _headers(token),
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      throw HttpException('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  Future<List<Station>> getMyStations() async {
    final response = await _get('/api/Stations');
    if (response == null) return [];
    return (response as List).map((e) => Station.fromJson(e)).toList();
  }

  Future<List<Station>> getAllStations() async {
    final response = await _get('/api/Stations/all');
    if (response == null) return [];
    return (response as List).map((e) => Station.fromJson(e)).toList();
  }

  Future<Station> getStationById(String id) async {
    final response = await _get('/api/Stations/$id');
    return Station.fromJson(response);
  }

  Future<Station> registerStation(Map<String, dynamic> request) async {
    final response = await _post('/api/Stations', request);
    return Station.fromJson(response);
  }

  Future<Station> updateStation(String id, Map<String, dynamic> request) async {
    final response = await _put('/api/Stations/$id', request);
    return Station.fromJson(response);
  }

  Future<Charger> addCharger(String stationId, Map<String, dynamic> request) async {
    final response = await _post('/api/Stations/$stationId/chargers', request);
    return Charger.fromJson(response);
  }

  Future<void> updateOperatingHours(String stationId, List<Map<String, dynamic>> hours) async {
    await _put('/api/Stations/$stationId/operating-hours', hours);
  }
}
