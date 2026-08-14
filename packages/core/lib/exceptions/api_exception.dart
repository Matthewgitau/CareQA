class ApiException implements Exception {
  final String message;
  final int statusCode;
  final ApiExceptionType errorType;

  ApiException({
    required this.message,
    required this.statusCode,
    required this.errorType,
  });

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

enum ApiExceptionType {
  network,
  unauthorized,
  badRequest,
  notFound,
  server,
  unknown,
}
</arg_value></tool_call>