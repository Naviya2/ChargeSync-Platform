import 'package:flutter/foundation.dart';

/// Central config for all backend API calls.
class ApiConfig {
  ApiConfig._();

  /// Dynamically use 10.0.2.2 for Android emulators, and localhost for Web/iOS/Desktop.
  /// When hosting in production, pass the API_URL via:
  /// flutter build apk --dart-define=API_URL=https://api.chargesync.network
  static String get baseUrl {
    // 1. Check for production URL passed during build
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }

    // 2. Fallback to local development URLs
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5035';
    }
    return 'http://localhost:5035';
  }

  // ── Auth endpoints ──────────────────────────────────────────────────────────
  static String get login => '$baseUrl/api/auth/login';
  static String get googleLogin => '$baseUrl/api/auth/google';
  static String get register => '$baseUrl/api/auth/register';
  static String get refresh => '$baseUrl/api/auth/refresh';
  static String get logout => '$baseUrl/api/auth/logout';
  static String get me => '$baseUrl/api/auth/me';

  // ── Token storage keys ──────────────────────────────────────────────────────
  static const String kAccessToken = 'cs_access_token';
  static const String kRefreshToken = 'cs_refresh_token';
  static const String kUserJson = 'cs_user';
}
