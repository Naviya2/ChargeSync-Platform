import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central config for all backend API calls.
class ApiConfig {
  ApiConfig._();

  /// Reads API_URL from .env file, falls back to compile-time env or local defaults
  static String get baseUrl {
    try {
      final envUrl = dotenv.env['API_URL'];
      if (envUrl != null && envUrl.isNotEmpty) {
        return envUrl;
      }
    } catch (_) {
      // Ignored for tests if dotenv is not initialized
    }

    const buildUrl = String.fromEnvironment('API_URL');
    if (buildUrl.isNotEmpty) {
      return buildUrl;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5035';
    }
    return 'http://localhost:5035';
  }

  // ── Auth endpoints ──────────────────────────────────────────────────────────
  static String get login       => '$baseUrl/api/auth/login';
  static String get googleLogin => '$baseUrl/api/auth/google';
  static String get register    => '$baseUrl/api/auth/register';
  static String get refresh  => '$baseUrl/api/auth/refresh';
  static String get logout   => '$baseUrl/api/auth/logout';
  static String get me       => '$baseUrl/api/auth/me';

  // ── Station endpoints ────────────────────────────────────────────────────────
  /// GET /api/stations  — owner's own stations (requires StationOwner or Admin role)
  static String get myStations     => '$baseUrl/api/stations';
  /// GET /api/stations/all  — all approved stations (public)
  static String get allStations    => '$baseUrl/api/stations/all';
  /// GET /api/stations/search?...  — search/nearby (public)
  static String get searchStations => '$baseUrl/api/stations/search';

  // ── Token storage keys ──────────────────────────────────────────────────────
  static const String kAccessToken  = 'cs_access_token';
  static const String kRefreshToken = 'cs_refresh_token';
  static const String kUserJson     = 'cs_user';
}
