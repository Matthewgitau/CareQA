import 'package:dio/dio.dart';
import 'package:core/core.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;
  bool _isRefreshing = false;
  final List<QueuedRequest> _queuedRequests = [];

  AuthInterceptor(this.dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = AuthService().token;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !err.requestOptions.path.contains('/auth/')) {
      if (_isRefreshing) {
        _queuedRequests.add(QueuedRequest(err.requestOptions, handler));
        return;
      }

      _isRefreshing = true;

      try {
        final refreshed = await AuthService().refreshToken();
        if (refreshed) {
          final token = AuthService().token;
          err.requestOptions.headers['Authorization'] = 'Bearer $token';
          final response = await dio.fetch(err.requestOptions);
          handler.resolve(response);
        } else {
          for (final queued in _queuedRequests) {
            queued.handler.reject(DioException(
              requestOptions: queued.options,
              error: 'Authentication failed',
            ));
          }
          _queuedRequests.clear();
          handler.reject(err);
        }
      } catch (e) {
        for (final queued in _queuedRequests) {
          queued.handler.reject(DioException(
            requestOptions: queued.options,
            error: 'Authentication failed',
          ));
        }
        _queuedRequests.clear();
        handler.reject(err);
      } finally {
        _isRefreshing = false;
      }
    } else {
      handler.next(err);
    }
  }
}

class QueuedRequest {
  final RequestOptions options;
  final ErrorInterceptorHandler handler;

  QueuedRequest(this.options, this.handler);
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