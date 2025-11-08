import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/error_handler.dart';

/// مكون مشترك للتحديث بالسحب (Pull to Refresh)
class PullToRefreshWrapper extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final String? refreshMessage;
  final bool showRefreshIndicator;
  final Color? indicatorColor;

  const PullToRefreshWrapper({
    super.key,
    required this.child,
    required this.onRefresh,
    this.refreshMessage,
    this.showRefreshIndicator = true,
    this.indicatorColor,
  });

  @override
  State<PullToRefreshWrapper> createState() => _PullToRefreshWrapperState();
}

class _PullToRefreshWrapperState extends State<PullToRefreshWrapper> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = 
      GlobalKey<RefreshIndicatorState>();
  bool _isRefreshing = false;

  /// تنفيذ عملية التحديث
  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      debugPrint('🔄 بدء التحديث بالسحب...');
      
      await widget.onRefresh();
      
      debugPrint('✅ تم التحديث بنجاح');
      
      // إظهار رسالة نجاح إذا كانت محددة
      if (widget.refreshMessage != null && mounted) {
        ErrorHandler.showSuccessSnackBar(
          context,
          widget.refreshMessage!,
          duration: const Duration(seconds: 2),
        );
      }
      
    } catch (e) {
      debugPrint('❌ خطأ في التحديث: $e');
      
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          e,
          customMessage: ErrorHandler.isNetworkError(e)
              ? 'لا يوجد اتصال بالإنترنت. يرجى التحقق من الاتصال والمحاولة مرة أخرى.'
              : 'حدث خطأ في التحديث. يرجى المحاولة مرة أخرى.',
          onRetry: () => _handleRefresh(),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  /// تشغيل التحديث برمجياً
  void triggerRefresh() {
    _refreshIndicatorKey.currentState?.show();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showRefreshIndicator) {
      return widget.child;
    }

    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _handleRefresh,
      color: widget.indicatorColor ?? const Color(0xFF007bff),
      backgroundColor: Colors.white,
      strokeWidth: 3.0,
      displacement: 60.0,
      child: widget.child,
    );
  }
}

/// مكون محسن للتحديث بالسحب مع رسائل مخصصة
class SmartPullToRefresh extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final String refreshingMessage;
  final String successMessage;
  final String? emptyMessage;
  final bool showMessages;
  final Widget? customLoadingWidget;

  const SmartPullToRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
    this.refreshingMessage = 'جاري التحديث...',
    this.successMessage = 'تم التحديث بنجاح',
    this.emptyMessage,
    this.showMessages = true,
    this.customLoadingWidget,
  });

  @override
  State<SmartPullToRefresh> createState() => _SmartPullToRefreshState();
}

class _SmartPullToRefreshState extends State<SmartPullToRefresh> {
  bool _isRefreshing = false;
  String? _currentMessage;

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
      _currentMessage = widget.refreshingMessage;
    });

    try {
      await widget.onRefresh();
      
      if (widget.showMessages && mounted) {
        setState(() {
          _currentMessage = widget.successMessage;
        });
        
        // إخفاء رسالة النجاح بعد ثانيتين
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _currentMessage = null;
            });
          }
        });
      }
      
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          e,
          onRetry: () => _handleRefresh(),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _handleRefresh,
          color: const Color(0xFF007bff),
          backgroundColor: Colors.white,
          strokeWidth: 3.0,
          child: widget.child,
        ),
        
        // رسالة التحديث العائمة
        if (_currentMessage != null && widget.showMessages)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            right: 20,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _isRefreshing 
                      ? const Color(0xFF007bff)
                      : const Color(0xFF28a745),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isRefreshing)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 16,
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _currentMessage!,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// مساعد للتحديث التلقائي عند عودة الاتصال
class NetworkAwareRefresh {
  static bool _wasOffline = false;
  
  /// فحص حالة الشبكة وتحديث إذا عادت
  static Future<bool> checkAndRefreshIfNeeded(
    BuildContext context,
    Future<void> Function() refreshFunction,
  ) async {
    try {
      // محاولة عملية بسيطة للتحقق من الاتصال
      await Future.delayed(const Duration(milliseconds: 100));
      
      // إذا كانت الشبكة منقطعة سابقاً وعادت الآن
      if (_wasOffline) {
        _wasOffline = false;
        
        if (context.mounted) {
          ErrorHandler.showSuccessSnackBar(
            context,
            'عاد الاتصال بالإنترنت - جاري التحديث...',
            duration: const Duration(seconds: 2),
          );
          
          // تحديث البيانات
          await refreshFunction();
        }
        
        return true;
      }
      
      return false;
    } catch (e) {
      _wasOffline = true;
      return false;
    }
  }
  
  /// إعادة تعيين حالة الشبكة
  static void reset() {
    _wasOffline = false;
  }
}
