import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'auth_api_client.dart';
import 'auth_models.dart';

/// App-level auth state — holds current user and session.
/// Use [AuthService.instance] everywhere.
class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _api = AuthApiClient.instance;

  AuthUser? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;

  AuthUser? get currentUser  => _currentUser;
  bool get isLoading         => _isLoading;
  bool get isAuthenticated   => _currentUser != null;
  bool get isInitialized     => _isInitialized;
  bool get isDriver          => _currentUser?.role == 'Driver';
  bool get isStaff           => _currentUser?.role == 'StationStaff' || _currentUser?.role == 'StationOwner';
  Future<String?> get token  => _api.getAccessToken();

  // ── Bootstrap (call once at app start) ───────────────────────────────────────

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final cached = await _api.getCachedUser();
      if (cached != null) {
        // Validate the stored token is still good, auto-refresh if needed
        final user = await _api.me();
        _currentUser = user;
      }
    } catch (_) {
      // Token expired / no stored session — stay logged out
      _currentUser = null;
      await _api.clearTokens();
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  // ── Login ────────────────────────────────────────────────────────────────────

  /// Throws [ApiException] on failure — caller handles UI error display.
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _api.login(LoginRequest(email: email, password: password));
      _currentUser = result.user;
      notifyListeners();
      return result;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Triggers the native Google Sign-in flow and sends the ID token to the backend.
  Future<AuthResult> loginWithGoogle({String role = 'Driver'}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        throw ApiException(400, 'Sign in aborted');
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw ApiException(400, 'Failed to get Google ID token');
      }

      final result = await _api.googleLogin(idToken, role: role);
      _currentUser = result.user;
      notifyListeners();
      return result;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(500, 'Google Sign-in failed: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Register ─────────────────────────────────────────────────────────────────

  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String password,
    String role = 'Driver',
    String? phoneNumber,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _api.register(RegisterRequest(
        fullName:    fullName,
        email:       email,
        password:    password,
        role:        role,
        phoneNumber: phoneNumber,
      ));
      _currentUser = result.user;
      notifyListeners();
      return result;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Logout ───────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    final refreshToken = await _api.getRefreshToken();
    if (refreshToken != null) {
      await _api.logout(refreshToken);
    } else {
      await _api.clearTokens();
    }
    _currentUser = null;
    notifyListeners();
  }
}
