// استثناءات التطبيق المخصصة

/// استثناء API عام
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => 'ApiException: $message (code: $statusCode)';
}

/// استثناء الشبكة
class NetworkException implements Exception {
  final String message;

  NetworkException([this.message = 'خطأ في الاتصال بالشبكة']);

  @override
  String toString() => 'NetworkException: $message';
}

/// استثناء الكاش
class CacheException implements Exception {
  final String message;

  CacheException([this.message = 'خطأ في الكاش']);

  @override
  String toString() => 'CacheException: $message';
}

/// استثناء التحقق
class ValidationException implements Exception {
  final String message;
  final Map<String, String>? errors;

  ValidationException(this.message, {this.errors});

  @override
  String toString() => 'ValidationException: $message';
}

/// استثناء عدم العثور
class NotFoundException implements Exception {
  final String message;

  NotFoundException([this.message = 'العنصر غير موجود']);

  @override
  String toString() => 'NotFoundException: $message';
}

/// استثناء انتهاء الوقت
class TimeoutException implements Exception {
  final String message;

  TimeoutException([this.message = 'انتهى وقت الاتصال']);

  @override
  String toString() => 'TimeoutException: $message';
}
