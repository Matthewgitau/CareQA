class CacheKeys {
  // Auth
  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String userData = 'user_data';
  static const String lastLogin = 'last_login';

  // User preferences
  static const String themeMode = 'theme_mode';
  static const String language = 'language';
  static const String notificationsEnabled = 'notifications_enabled';
  static const String biometricsEnabled = 'biometrics_enabled';

  // Data caching
  static const String shiftsCache = 'shifts_cache';
  static const String carersCache = 'carers_cache';
  static const String serviceUsersCache = 'service_users_cache';
  static const String clientsCache = 'clients_cache';
  static const String invoicesCache = 'invoices_cache';
  static const String visitsCache = 'visits_cache';

  // App state
  static const String onboardingCompleted = 'onboarding_completed';
  static const String appVersion = 'app_version';
  static const String lastSyncTimestamp = 'last_sync_timestamp';

  // Settings
  static const String apiBaseUrl = 'api_base_url';
  static const String debugMode = 'debug_mode';
  static const String analyticsEnabled = 'analytics_enabled';

  // Temporary data
  static const String draftShift = 'draft_shift';
  static const String draftInvoice = 'draft_invoice';
  static const String draftVisit = 'draft_visit';

  // Search history
  static const String searchHistory = 'search_history';
  static const String recentSearches = 'recent_searches';

  // Cache expiry times (in seconds)
  static const int shiftsCacheTTL = 300; // 5 minutes
  static const int carersCacheTTL = 600; // 10 minutes
  static const int serviceUsersCacheTTL = 600; // 10 minutes
  static const int clientsCacheTTL = 1800; // 30 minutes
  static const int invoicesCacheTTL = 3600; // 1 hour
  static const int visitsCacheTTL = 300; // 5 minutes
}