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
  bool _isProfileLoaded = false;

  User? get currentUser => _currentUser;
  String? get userRole => _userRole;
  String? get organisationId => _organisationId;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  /// Whether the profile load has completed (success or failure).
  /// Used by the AuthWrapper to avoid showing an infinite spinner.
  bool get isProfileLoaded => _isProfileLoaded;

  SupabaseAuthService(this._supabase) {
    _supabase.auth.onAuthStateChange.listen((data) {
      _currentUser = data.session?.user;
      if (_currentUser != null) {
        _loadUserProfile();
      } else {
        _userRole = null;
        _organisationId = null;
        _isProfileLoaded = false;
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

  // ─── Staff Self Sign-Up ─────────────────────────────────────────────────────

  /// Finds active carer records matching an email (for identity confirmation).
  Future<List<Map<String, dynamic>>> findCarersByEmail(String email) async {
    try {
      final response = await _supabase.rpc(
        'find_carers_by_email',
        params: {'p_email': email.trim()},
      );
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error finding carers: $e');
      return [];
    }
  }

  /// Creates a staff account linked to the selected carer record.
  Future<AuthResult> signUpAsStaff({
    required String email,
    required String password,
    required String carerId,
    required String fullName,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase.rpc(
        'staff_signup',
        params: {
          'p_email': email.trim(),
          'p_password': password,
          'p_carer_id': carerId,
          'p_full_name': fullName,
        },
      );

      // Auto sign-in after successful sign-up
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        return AuthResult.failure('Account created but auto sign-in failed. Please log in.');
      }

      await _loadUserProfile();
      await _cacheSessionFlag(true);
      return AuthResult.success(response.user!, message: 'Account created successfully!');
    } on AuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e.message));
    } catch (e) {
      return AuthResult.failure(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Password Reset ─────────────────────────────────────────────────────────

  /// Returns the correct redirect URL for the current platform (web vs mobile).
  String get _passwordResetRedirectUrl {
    if (kIsWeb) {
      // On web the password-reset link must point back to an http(s) URL.
      // Use path-based routing (not hash) so the PKCE code is in query params.
      return '${Uri.base.origin}/reset-password';
    }
    // Mobile / desktop uses the custom scheme.
    return 'careqa://reset-password';
  }

  Future<AuthResult> resetPassword(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: _passwordResetRedirectUrl,
      );
      return AuthResult.success(
        null,
        message: 'Password reset link sent to $email',
      );
    } on AuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e.message));
    } catch (_) {
      return AuthResult.failure('Failed to send reset link. Please try again.');
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
      // Use platform-specific redirect URL
      String redirectUrl;
      if (kIsWeb) {
        // On web, use the current origin with /auth/callback path
        redirectUrl = '${Uri.base.origin}/auth/callback';
      } else if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        // On mobile, use the custom scheme
        redirectUrl = 'careqa://auth/callback';
      } else {
        // Fallback for other platforms (desktop, etc.)
        redirectUrl = 'careqa://auth/callback';
      }

      await _supabase.auth.signInWithOtp(
        email: email.trim(),
        emailRedirectTo: redirectUrl,
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

  /// PERFORMANCE FIX (-d edge / web hot restarts):
  /// `local_auth` has no Flutter-web implementation. On web, every call into
  /// it drops onto a platform channel with no registered handler, so it fails
  /// slowly (or times out) instead of returning instantly. Because
  /// AuthWrapper._checkSessionOnStartup() awaits this on EVERY hot restart
  /// while logged in, that stall was the main cause of laggy post-login hot
  /// restarts under `flutter run -d edge`.
  ///
  /// Sustainability note: biometrics only ever apply to device builds
  /// (Android/iOS/Windows hello etc.), so short-circuiting on web is not just
  /// the quick win — it is the CORRECT long-term behaviour. No code path on
  /// web can ever use biometrics, so returning `false` early is semantically
  /// exact, not a workaround.
  Future<bool> isBiometricAvailable() async {
    // Web has no biometric hardware path; skip the unsupported plugin call.
    if (kIsWeb) return false;
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
    _isProfileLoaded = false;
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
          .maybeSingle();

      if (profile != null) {
        _userRole = profile['role'] as String?;
        _organisationId = profile['organisation_id'] as String?;
      } else {
        // No profile exists — create one with default 'carer' role
        // Try to get organisation_id from user metadata or use a default
        String? orgId;
        try {
          final meta = _currentUser!.userMetadata;
          if (meta != null && meta['organisation_id'] != null) {
            orgId = meta['organisation_id'] as String?;
          }
        } catch (_) {}

        await _supabase.from('profiles').insert({
          'id': _currentUser!.id,
          'email': _currentUser!.email,
          'full_name': _currentUser!.userMetadata?['full_name'] ?? _currentUser!.email?.split('@').first ?? 'Staff',
          'name': _currentUser!.userMetadata?['full_name'] ?? _currentUser!.email?.split('@').first ?? 'Staff',
          'role': 'carer',
          'organisation_id': orgId,
          'is_active': true,
        });

        _userRole = 'carer';
        _organisationId = orgId;
      }

      // Cache role and org for quick access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userRoleKey, _userRole ?? '');
      await prefs.setString(_userOrgKey, _organisationId ?? '');
    } catch (e) {
      debugPrint('Error loading/creating user profile: $e');

      // Fall back to cached role/org
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedRole = prefs.getString(_userRoleKey);
        final cachedOrg = prefs.getString(_userOrgKey);
        if (cachedRole != null && cachedRole.isNotEmpty) {
          _userRole = cachedRole;
          _organisationId = (cachedOrg != null && cachedOrg.isNotEmpty) ? cachedOrg : null;
        }
      } catch (cacheErr) {
        debugPrint('Error reading cached profile: $cacheErr');
      }
    } finally {
      _isProfileLoaded = true;
      notifyListeners();
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