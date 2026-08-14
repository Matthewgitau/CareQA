import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService extends ChangeNotifier {
  final SupabaseClient _supabase;
  final LocalAuthentication _localAuth = LocalAuthentication();

  static const String _sessionCachedKey = 'session_cached';
  static const String _userRoleKey = 'user_role';
  static const String _userOrgKey = 'user_org_id';

  User? _currentUser;
  String? _userRole;
  String? _organisationId;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  String? get userRole => _userRole;
  String? get organisationId => _organisationId;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  SupabaseAuthService(this._supabase) {
    _supabase.auth.onAuthStateChange.listen((data) {
      _currentUser = data.session?.user;
      if (_currentUser != null) {
        _loadUserProfile();
      } else {
        _userRole = null;
        _organisationId = null;
      }
      notifyListeners();
    });
  }

  // ─── Email + Password Sign In ───────────────────────────────────────────────

  Future<AuthResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        return AuthResult.failure('Sign in failed. Please check your credentials.');
      }

      await _loadUserProfile();
      await _cacheSessionFlag(true);
      return AuthResult.success(response.user!);

    } on AuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e.message));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred. Please try again.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Magic Link Sign In ─────────────────────────────────────────────────────

  Future<AuthResult> sendMagicLink(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase.auth.signInWithOtp(
        email: email.trim(),
        emailRedirectTo: 'careqa://auth/callback',
      );
      return AuthResult.success(null, message: 'Magic link sent to $email');
    } on AuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e.message));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Biometric Session Unlock ───────────────────────────────────────────────

  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable || isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasSessionCached() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getBool(_sessionCachedKey) ?? false;
    // Also verify the Supabase session is still valid
    final session = _supabase.auth.currentSession;
    return cached && session != null;
  }

  Future<AuthResult> unlockWithBiometric() async {
    try {
      final hasCachedSession = await hasSessionCached();
      if (!hasCachedSession) {
        return AuthResult.failure('No cached session found. Please sign in again.');
      }

      final biometricAvailable = await isBiometricAvailable();
      if (!biometricAvailable) {
        // Fall back to refreshing the existing session without biometric
        final session = _supabase.auth.currentSession;
        if (session != null) {
          _currentUser = session.user;
          await _loadUserProfile();
          return AuthResult.success(_currentUser!);
        }
        return AuthResult.failure('No valid session found.');
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Unlock CareQA to continue',
        options: const AuthenticationOptions(
          biometricOnly: false, // allows PIN/pattern fallback
          stickyAuth: true,
        ),
      );

      if (!authenticated) {
        return AuthResult.failure('Biometric authentication failed.');
      }

      // Biometric passed — restore the Supabase session
      final session = _supabase.auth.currentSession;
      if (session == null) {
        await _cacheSessionFlag(false);
        return AuthResult.failure('Session expired. Please sign in again.');
      }

      _currentUser = session.user;
      await _loadUserProfile();
      notifyListeners();
      return AuthResult.success(_currentUser!);

    } catch (e) {
      return AuthResult.failure('Biometric error: ${e.toString()}');
    }
  }

  // ─── Sign Out ───────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    await _cacheSessionFlag(false);
    _currentUser = null;
    _userRole = null;
    _organisationId = null;
    notifyListeners();
  }

  // ─── Profile Loading ────────────────────────────────────────────────────────

  Future<void> _loadUserProfile() async {
    if (_currentUser == null) return;

    try {
      final profile = await _supabase
          .from('profiles')
          .select('role, organisation_id')
          .eq('id', _currentUser!.id)
          .single();

      _userRole = profile['role'] as String?;
      _organisationId = profile['organisation_id'] as String?;

      // Cache role and org for quick access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userRoleKey, _userRole ?? '');
      await prefs.setString(_userOrgKey, _organisationId ?? '');

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  // ─── Role Helpers ───────────────────────────────────────────────────────────

  bool get isCarer => _userRole == 'carer' || _userRole == 'senior_carer';
  bool get isTeamLeader => _userRole == 'team_leader';
  bool get isManager => _userRole == 'manager';
  bool get isAdmin => _userRole == 'admin';
  bool get isSuperAdmin => _userRole == 'super_admin';

  bool hasMinimumRole(String minimumRole) {
    const roleHierarchy = {
      'carer': 0,
      'senior_carer': 1,
      'team_leader': 2,
      'manager': 3,
      'admin': 4,
      'super_admin': 5,
    };
    final userLevel = roleHierarchy[_userRole] ?? 0;
    final requiredLevel = roleHierarchy[minimumRole] ?? 0;
    return userLevel >= requiredLevel;
  }

  // ─── Private Helpers ────────────────────────────────────────────────────────

  Future<void> _cacheSessionFlag(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionCachedKey, value);
  }

  String _mapAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Incorrect email or password.';
    }
    if (message.contains('Email not confirmed')) {
      return 'Please verify your email before signing in.';
    }
    if (message.contains('Too many requests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    return message;
  }
}

// ─── Result Type ─────────────────────────────────────────────────────────────

class AuthResult {
  final bool success;
  final String? errorMessage;
  final String? message;
  final User? user;

  AuthResult._({
    required this.success,
    this.errorMessage,
    this.message,
    this.user,
  });

  factory AuthResult.success(User? user, {String? message}) =>
      AuthResult._(success: true, user: user, message: message);

  factory AuthResult.failure(String error) =>
      AuthResult._(success: false, errorMessage: error);
}