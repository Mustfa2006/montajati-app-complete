import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// مساعد لمعالجة الأخطاء وإظهار رسائل مناسبة للمستخدم
class ErrorHandler {
  
  /// تحويل الخطأ التقني إلى رسالة مفهومة للمستخدم
  static String getReadableErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // أخطاء الاتصال بالإنترنت
    if (errorString.contains('failed to fetch') ||
        errorString.contains('clientexception') ||
        errorString.contains('socketexception') ||
        errorString.contains('network error') ||
        errorString.contains('connection refused') ||
        errorString.contains('connection timeout') ||
        errorString.contains('timeoutexception')) {
      return 'لا يوجد اتصال بالإنترنت. يرجى التحقق من الاتصال والمحاولة مرة أخرى.';
    }
    
    // أخطاء الخادم
    if (errorString.contains('500') || errorString.contains('server error')) {
      return 'خطأ في الخادم. يرجى المحاولة مرة أخرى لاحقاً.';
    }
    
    // أخطاء التفويض
    if (errorString.contains('401') || errorString.contains('unauthorized')) {
      return 'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى.';
    }
    
    // أخطاء عدم العثور على البيانات
    if (errorString.contains('404') || errorString.contains('not found')) {
      return 'البيانات المطلوبة غير موجودة.';
    }
    
    // أخطاء قاعدة البيانات
    if (errorString.contains('postgrestexception') || 
        errorString.contains('database') ||
        errorString.contains('supabase')) {
      return 'خطأ في قاعدة البيانات. يرجى المحاولة مرة أخرى.';
    }
    
    // أخطاء التحقق من البيانات
    if (errorString.contains('validation') || errorString.contains('invalid')) {
      return 'البيانات المدخلة غير صحيحة. يرجى التحقق والمحاولة مرة أخرى.';
    }
    
    // رسالة عامة للأخطاء غير المعروفة
    return 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';
  }
  
  /// إظهار رسالة خطأ مع إمكانية إعادة المحاولة
  static void showErrorSnackBar(
    BuildContext context,
    dynamic error, {
    String? customMessage,
    VoidCallback? onRetry,
    String retryLabel = 'إعادة المحاولة',
    Duration duration = const Duration(seconds: 4),
  }) {
    final message = customMessage ?? getReadableErrorMessage(error);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFdc3545),
        duration: duration,
        action: onRetry != null
            ? SnackBarAction(
                label: retryLabel,
                textColor: const Color(0xFFffd700),
                onPressed: onRetry,
              )
            : null,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  /// إظهار رسالة نجاح
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF28a745),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  /// إظهار رسالة تحذير
  static void showWarningSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFffc107),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  /// إظهار حوار خطأ مع تفاصيل
  static void showErrorDialog(
    BuildContext context,
    dynamic error, {
    String? title,
    String? customMessage,
    VoidCallback? onRetry,
  }) {
    final message = customMessage ?? getReadableErrorMessage(error);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title ?? 'خطأ',
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFdc3545),
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.cairo(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: Text(
                'إعادة المحاولة',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF007bff),
                ),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'موافق',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6c757d),
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
  
  /// التحقق من نوع الخطأ
  static bool isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('failed to fetch') ||
           errorString.contains('clientexception') ||
           errorString.contains('socketexception') ||
           errorString.contains('network error') ||
           errorString.contains('connection refused') ||
           errorString.contains('timeoutexception');
  }
  
  /// التحقق من خطأ الخادم
  static bool isServerError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('500') || 
           errorString.contains('server error') ||
           errorString.contains('internal server error');
  }
  
  /// التحقق من خطأ التفويض
  static bool isAuthError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('401') ||
           errorString.contains('unauthorized') ||
           errorString.contains('authentication');
  }

  /// معالجة أخطاء HTTP وإرجاع رسالة مناسبة
  static String handleHttpError(dynamic error, {String? context}) {
    if (isNetworkError(error)) {
      return 'لا يوجد اتصال بالإنترنت. يرجى التحقق من الاتصال والمحاولة مرة أخرى.';
    }

    if (isServerError(error)) {
      return context != null
          ? 'خطأ في الخادم أثناء $context. يرجى المحاولة مرة أخرى لاحقاً.'
          : 'خطأ في الخادم. يرجى المحاولة مرة أخرى لاحقاً.';
    }

    if (isAuthError(error)) {
      return 'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى.';
    }

    return context != null
        ? 'حدث خطأ أثناء $context. يرجى المحاولة مرة أخرى.'
        : getReadableErrorMessage(error);
  }

  /// تسجيل الخطأ مع معلومات إضافية
  static void logError(dynamic error, {String? context, Map<String, dynamic>? additionalInfo}) {
    final errorInfo = {
      'error': error.toString(),
      'context': context,
      'timestamp': DateTime.now().toIso8601String(),
      'isNetworkError': isNetworkError(error),
      'isServerError': isServerError(error),
      'isAuthError': isAuthError(error),
      ...?additionalInfo,
    };

    debugPrint('❌ خطأ مسجل: ${errorInfo.toString()}');
  }
}
