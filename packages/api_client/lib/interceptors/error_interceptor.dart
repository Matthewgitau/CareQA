import 'package:dio/dio.dart';
import 'package:core/core.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    ApiException apiException;

    if (err.response != null) {
      final statusCode = err.response!.statusCode!;
      final data = err.response!.data;
      String message = 'An error occurred';

      if (data is Map<String, dynamic>) {
        message = data['message'] ?? data['error'] ?? 'Unknown error';
      } else if (data is String) {
        message = data;
      }

      apiException = ApiException(
        message: message,
        statusCode: statusCode,
        errorType: _getErrorType(statusCode),
      );
    } else if (err.type == DioExceptionType.connectionTimeout) {
      apiException = ApiException(
        message: 'Connection timeout. Please check your internet connection.',
        statusCode: 0,
        errorType: ApiExceptionType.network,
      );
    } else if (err.type == DioExceptionType.connectionError) {
      apiException = ApiException(
        message: 'No internet connection. Please check your network settings.',
        statusCode: 0,
        errorType: ApiExceptionType.network,
      );
    } else {
      apiException = ApiException(
        message: 'An unexpected error occurred. Please try again.',
        statusCode: 0,
        errorType: ApiExceptionType.unknown,
      );
    }

    handler.reject(err.copyWith(error: apiException));
  }

  ApiExceptionType _getErrorType(int statusCode) {
    if (statusCode == 401 || statusCode == 403) {
      return ApiExceptionType.unauthorized;
    } else if (statusCode == 404) {
      return ApiExceptionType.notFound;
    } else if (statusCode == 400) {
      return ApiExceptionType.badRequest;
    } else if (statusCode >= 500) {
      return ApiExceptionType.server;
    }
    return ApiExceptionType.unknown;
  }
}
</arg_value></tool_call>