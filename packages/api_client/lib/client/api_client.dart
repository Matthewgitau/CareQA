import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../interceptors/auth_interceptor.dart';
import '../interceptors/logging_interceptor.dart';
import '../interceptors/retry_interceptor.dart';
import '../interceptors/error_interceptor.dart';
import 'endpoints.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late Dio _dio;
  final Logger logger = Logger();
  bool _initialized = false;

  String? _baseUrl;
  String? get baseUrl => _baseUrl;

  void init({String? baseUrl}) {
    if (_initialized) return;

    _baseUrl = baseUrl ?? const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000');

    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl!,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      contentType: 'application/json',
      responseType: ResponseType.json,
    ));

    // Add interceptors
    _dio.interceptors.add(AuthInterceptor(_dio));
    _dio.interceptors.add(LoggingInterceptor());
    _dio.interceptors.add(RetryInterceptor(_dio));
    _dio.interceptors.add(ErrorInterceptor());

    _initialized = true;
  }

  Dio get dio {
    if (!_initialized) {
      init();
    }
    return _dio;
  }

  // Generic request methods
  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters, Options? options}) {
    return dio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> post<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) {
    return dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> put<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) {
    return dio.put<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> patch<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) {
    return dio.patch<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> delete<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) {
    return dio.delete<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  // Auth methods
  void setToken(String? token) {
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  void clearToken() {
    _dio.options.headers.remove('Authorization');
  }

  // Convenience methods for common endpoints
  Future<Response<Map<String, dynamic>>> login(String email, String password) {
    return post<Map<String, dynamic>>(Endpoints.login, data: {'email': email, 'password': password});
  }

  Future<Response<Map<String, dynamic>>> register(Map<String, dynamic> data) {
    return post<Map<String, dynamic>>(Endpoints.register, data: data);
  }

  Future<Response<Map<String, dynamic>>> refreshToken(String refreshToken) {
    return post<Map<String, dynamic>>(Endpoints.refresh, data: {'refresh_token': refreshToken});
  }

  Future<Response<Map<String, dynamic>>> logout() {
    return post<Map<String, dynamic>>(Endpoints.logout);
  }

  Future<Response<Map<String, dynamic>>> getCurrentUser() {
    return get<Map<String, dynamic>>(Endpoints.me);
  }
}
</arg_value>
<task_progress>
- [x] Create shared packages (core, api_client, ui_kit)
- [ ] Build client app structure
- [ ] Build carer app structure  
- [ ] Build API gateway
- [ ] Build shift service
</task_progress>
</write_to_file></tool_call>