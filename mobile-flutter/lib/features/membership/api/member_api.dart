import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../core/api/api_config.dart';

class MemberApi {
  static final instance = MemberApi();
  final _storage = const FlutterSecureStorage();

  Future<dynamic> request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final token = await _storage.read(key: ApiConfig.kAccessToken);
    final request = http.Request(
      method,
      Uri.parse('${ApiConfig.baseUrl}/api/$path'),
    );
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });
    if (body != null) request.body = jsonEncode(body);
    final response = await http.Response.fromStream(
      await request.send().timeout(const Duration(seconds: 30)),
    );
    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {
      data = null;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data is Map
            ? data['detail'] ?? data['title'] ?? 'Request failed'
            : 'Request failed (${response.statusCode})',
      );
    }
    return data;
  }

  static String requestId() {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex = bytes.map((n) => n.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
