import 'dart:convert';

// ── AuthUser ──────────────────────────────────────────────────────────────────
/// Mirrors backend: AuthUser(Guid Id, string FullName, string Email, string Role)
class AuthUser {
  final String id;
  final String fullName;
  final String email;
  final String role;

  const AuthUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id:       json['id']       as String,
        fullName: json['fullName'] as String,
        email:    json['email']    as String,
        role:     json['role']     as String,
      );

  Map<String, dynamic> toJson() => {
        'id':       id,
        'fullName': fullName,
        'email':    email,
        'role':     role,
      };

  String toJsonString() => jsonEncode(toJson());
  factory AuthUser.fromJsonString(String s) => AuthUser.fromJson(jsonDecode(s) as Map<String, dynamic>);
}

// ── AuthResult ────────────────────────────────────────────────────────────────
/// Mirrors backend: AuthResult(string AccessToken, DateTimeOffset AccessTokenExpiresAtUtc,
///                             string RefreshToken, DateTimeOffset RefreshTokenExpiresAtUtc, AuthUser User)
class AuthResult {
  final String accessToken;
  final DateTime accessTokenExpiresAtUtc;
  final String refreshToken;
  final DateTime refreshTokenExpiresAtUtc;
  final AuthUser user;

  const AuthResult({
    required this.accessToken,
    required this.accessTokenExpiresAtUtc,
    required this.refreshToken,
    required this.refreshTokenExpiresAtUtc,
    required this.user,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        accessToken:               json['accessToken']               as String,
        accessTokenExpiresAtUtc:   DateTime.parse(json['accessTokenExpiresAtUtc']  as String),
        refreshToken:              json['refreshToken']              as String,
        refreshTokenExpiresAtUtc:  DateTime.parse(json['refreshTokenExpiresAtUtc'] as String),
        user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      );
}

// ── LoginRequest ──────────────────────────────────────────────────────────────
/// Mirrors backend: LoginRequest(string Email, string Password)
class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

// ── RegisterRequest ───────────────────────────────────────────────────────────
/// Mirrors backend: RegisterRequest(string FullName, string Email, string Password,
///                                  UserRole Role, string? PhoneNumber)
class RegisterRequest {
  final String fullName;
  final String email;
  final String password;
  final String role;       // 'Driver' | 'StationOwner'
  final String? phoneNumber;

  const RegisterRequest({
    required this.fullName,
    required this.email,
    required this.password,
    this.role = 'Driver',
    this.phoneNumber,
  });

  Map<String, dynamic> toJson() => {
        'fullName':    fullName,
        'email':       email,
        'password':    password,
        'role':        role,
        if (phoneNumber != null && phoneNumber!.isNotEmpty)
          'phoneNumber': phoneNumber,
      };
}

// ── RefreshRequest ────────────────────────────────────────────────────────────
class RefreshRequest {
  final String refreshToken;
  const RefreshRequest(this.refreshToken);
  Map<String, dynamic> toJson() => {'refreshToken': refreshToken};
}

// ── ApiException ──────────────────────────────────────────────────────────────
class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';

  /// Human-readable message suitable for showing to the user.
  String get userMessage {
    switch (statusCode) {
      case 400: return message.isNotEmpty ? message : 'Invalid request. Please check your input.';
      case 401: return 'Incorrect email or password.';
      case 409: return 'An account with this email already exists.';
      case 0:   return 'Cannot connect to server. Please check your connection.';
      default:  return 'Something went wrong (error $statusCode). Please try again.';
    }
  }
}
