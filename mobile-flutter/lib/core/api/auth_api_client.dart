import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_models.dart';

/// Low-level HTTP client for the ChargeSync backend.
/// Handles JSON serialisation, bearer tokens, and error mapping.
class AuthApiClient {
  AuthApiClient._();
  static final AuthApiClient instance = AuthApiClient._();

  final _storage = const FlutterSecureStorage();
  final _client  = http.Client();

  // ── Token helpers ────────────────────────────────────────────────────────────

  Future<String?> getAccessToken()  => _storage.read(key: ApiConfig.kAccessToken);
  Future<String?> getRefreshToken() => _storage.read(key: ApiConfig.kRefreshToken);

  Future<void> _saveTokens(AuthResult result) async {
    await Future.wait([
      _storage.write(key: ApiConfig.kAccessToken,  value: result.accessToken),
      _storage.write(key: ApiConfig.kRefreshToken, value: result.refreshToken),
      _storage.write(key: ApiConfig.kUserJson,     value: result.user.toJsonString()),
    ]);
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: ApiConfig.kAccessToken),
      _storage.delete(key: ApiConfig.kRefreshToken),
      _storage.delete(key: ApiConfig.kUserJson),
    ]);
  }

  Future<AuthUser?> getCachedUser() async {
    final json = await _storage.read(key: ApiConfig.kUserJson);
    if (json == null) return null;
    try {
      return AuthUser.fromJsonString(json);
    } catch (_) {
      return null;
    }
  }

  // ── Auth endpoints ────────────────────────────────────────────────────────────

  /// POST /api/auth/login
  Future<AuthResult> login(LoginRequest request) async {
    final result = await _post(ApiConfig.login, request.toJson(), requireAuth: false);
    final authResult = AuthResult.fromJson(result);
    await _saveTokens(authResult);
    return authResult;
  }

  /// POST /api/auth/google
  Future<AuthResult> googleLogin(String idToken, {String role = 'Driver'}) async {
    final result = await _post(
      ApiConfig.googleLogin,
      {'idToken': idToken, 'role': role},
      requireAuth: false,
    );
    final authResult = AuthResult.fromJson(result);
    await _saveTokens(authResult);
    return authResult;
  }

  /// POST /api/auth/register
  Future<AuthResult> register(RegisterRequest request) async {
    final result = await _post(ApiConfig.register, request.toJson(), requireAuth: false);
    final authResult = AuthResult.fromJson(result);
    await _saveTokens(authResult);
    return authResult;
  }

  /// POST /api/auth/refresh
  Future<AuthResult> refresh(String refreshToken) async {
    final result = await _post(
      ApiConfig.refresh,
      RefreshRequest(refreshToken).toJson(),
      requireAuth: false,
    );
    final authResult = AuthResult.fromJson(result);
    await _saveTokens(authResult);
    return authResult;
  }

  /// POST /api/auth/logout
  Future<void> logout(String refreshToken) async {
    try {
      await _post(ApiConfig.logout, RefreshRequest(refreshToken).toJson());
    } finally {
      await clearTokens();
    }
  }

  /// GET /api/auth/me
  Future<AuthUser> me() async {
    final token = await getAccessToken();
    final response = await _getWithRetry(ApiConfig.me, token);
    return AuthUser.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  // ── Private HTTP helpers ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _post(
    String url,
    Map<String, dynamic> body, {
    bool requireAuth = true,
  }) async {
    final headers = <String, String>{
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader:      'application/json',
    };

    if (requireAuth) {
      final token = await getAccessToken();
      if (token != null) headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
    }

    late http.Response response;
    try {
      response = await _client
          .post(Uri.parse(url), headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
    } on SocketException {
      throw const ApiException(0, 'Network unreachable');
    } on Exception {
      throw const ApiException(0, 'Request timed out');
    }

    return _handleResponse(response);
  }

  /// Performs a GET with automatic token refresh on 401.
  Future<http.Response> _getWithRetry(String url, String? token) async {
    final headers = <String, String>{
      HttpHeaders.acceptHeader: 'application/json',
      if (token != null) HttpHeaders.authorizationHeader: 'Bearer $token',
    };

    http.Response response;
    try {
      response = await _client
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));
    } on SocketException {
      throw const ApiException(0, 'Network unreachable');
    } on Exception {
      throw const ApiException(0, 'Request timed out');
    }

    if (response.statusCode == 401) {
      // Try refreshing
      final refreshToken = await getRefreshToken();
      if (refreshToken != null) {
        try {
          final refreshed = await refresh(refreshToken);
          final retryHeaders = {
            HttpHeaders.acceptHeader:        'application/json',
            HttpHeaders.authorizationHeader: 'Bearer ${refreshed.accessToken}',
          };
          response = await _client
              .get(Uri.parse(url), headers: retryHeaders)
              .timeout(const Duration(seconds: 15));
        } catch (_) {
          await clearTokens();
          throw const ApiException(401, 'Session expired. Please sign in again.');
        }
      }
    }

    return response;
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    // Try to extract a ProblemDetails message from the backend
    String errorMessage = '';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      errorMessage = (body['title'] ?? body['detail'] ?? body['message'] ?? '') as String;
    } catch (_) {
      errorMessage = response.body;
    }

    throw ApiException(statusCode, errorMessage);
  }
}
