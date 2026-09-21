/// Central config for all backend API calls.
/// Change [baseUrl] to your actual running backend URL.
class ApiConfig {
  ApiConfig._();

  /// Local dev backend — update this to your machine's IP if running on a real device.
  /// For Chrome (web) use localhost directly.
  static const String baseUrl = 'http://localhost:5035';

  // ── Auth endpoints ──────────────────────────────────────────────────────────
  static const String login    = '$baseUrl/api/auth/login';
  static const String register = '$baseUrl/api/auth/register';
  static const String refresh  = '$baseUrl/api/auth/refresh';
  static const String logout   = '$baseUrl/api/auth/logout';
  static const String me       = '$baseUrl/api/auth/me';

  // ── Token storage keys ──────────────────────────────────────────────────────
  static const String kAccessToken  = 'cs_access_token';
  static const String kRefreshToken = 'cs_refresh_token';
  static const String kUserJson     = 'cs_user';
}
