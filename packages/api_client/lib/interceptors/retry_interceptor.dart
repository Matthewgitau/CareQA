import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration retryDelay;

  RetryInterceptor(this.dio, {this.maxRetries = 3, this.retryDelay = const Duration(seconds: 2)});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final attempt = (err.requestOptions.extra['retry_attempt'] as int? ?? 0) + 1;

    if (attempt <= maxRetries && _shouldRetry(err)) {
      err.requestOptions.extra['retry_attempt'] = attempt;
      Future.delayed(retryDelay, () {
        dio.fetch(err.requestOptions).then(
          (response) => handler.resolve(response),
          onError: (e) => handler.next(e as DioException),
        );
      });
    } else {
      handler.next(err);
    }
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.response?.statusCode != null && err.response!.statusCode! >= 500);
  }
}
</arg_value></tool_call>