class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;
  final Map<String, dynamic>? headers;
  final List<ApiError>? errors;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
    this.headers,
    this.errors,
  });

  factory ApiResponse.success(T data, {int? statusCode, Map<String, dynamic>? headers}) {
    return ApiResponse<T>(
      success: true,
      data: data,
      statusCode: statusCode,
      headers: headers,
    );
  }

  factory ApiResponse.error(String message, {int? statusCode, List<ApiError>? errors}) {
    return ApiResponse<T>(
      success: false,
      message: message,
      statusCode: statusCode,
      errors: errors,
    );
  }
}

class ApiError {
  final String code;
  final String message;
  final Map<String, dynamic>? details;

  ApiError({
    required this.code,
    required this.message,
    this.details,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: json['code'] as String? ?? 'UNKNOWN_ERROR',
      message: json['message'] as String? ?? 'An unknown error occurred',
      details: json['details'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'message': message,
      if (details != null) 'details': details,
    };
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