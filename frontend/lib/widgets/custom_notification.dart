import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// نظام الإشعارات المخصص الجميل
class CustomNotification {
  static OverlayEntry? _currentOverlay;
  static Timer? _currentTimer;

  /// عرض إشعار نجاح
  static void showSuccess(BuildContext context, String message) {
    _showNotification(
      context: context,
      message: message,
      icon: Icons.check_circle,
      color: Colors.green,
      duration: const Duration(seconds: 3),
    );
  }

  /// عرض إشعار خطأ
  static void showError(BuildContext context, String message) {
    _showNotification(
      context: context,
      message: message,
      icon: Icons.error,
      color: Colors.red,
      duration: const Duration(seconds: 4),
    );
  }

  /// عرض إشعار تحذير
  static void showWarning(BuildContext context, String message) {
    _showNotification(
      context: context,
      message: message,
      icon: Icons.warning,
      color: Colors.orange,
      duration: const Duration(seconds: 3),
    );
  }

  /// عرض إشعار معلومات
  static void showInfo(BuildContext context, String message) {
    _showNotification(
      context: context,
      message: message,
      icon: Icons.info,
      color: Colors.blue,
      duration: const Duration(seconds: 3),
    );
  }

  /// الدالة الأساسية لعرض الإشعار
  static void _showNotification({
    required BuildContext context,
    required String message,
    required IconData icon,
    required Color color,
    required Duration duration,
  }) {
    // إزالة الإشعار السابق إن وجد
    _removeCurrentNotification();

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _NotificationWidget(
        message: message,
        icon: icon,
        color: color,
        onDismiss: () {
          _removeCurrentNotification();
        },
      ),
    );

    // إدراج الإشعار
    overlay.insert(overlayEntry);
    _currentOverlay = overlayEntry;

    // إزالة الإشعار تلقائياً بعد المدة المحددة
    _currentTimer = Timer(duration, () {
      _removeCurrentNotification();
    });
  }

  /// إزالة الإشعار الحالي
  static void _removeCurrentNotification() {
    _currentTimer?.cancel();
    _currentTimer = null;

    if (_currentOverlay?.mounted == true) {
      _currentOverlay?.remove();
    }
    _currentOverlay = null;
  }
}

/// Widget الإشعار المخصص
class _NotificationWidget extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color color;
  final VoidCallback onDismiss;

  const _NotificationWidget({required this.message, required this.icon, required this.color, required this.onDismiss});

  @override
  State<_NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<_NotificationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.elasticOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    // بدء الانيميشن
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 30, // رفع الإشعار للأعلى قليلاً
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {
                _animationController.reverse().then((_) {
                  widget.onDismiss();
                });
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), // تضبيب أقوى
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      // خلفية شفافة مضببة
                      color: Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      // إطار ذهبي جميل
                      border: Border.all(
                        color: const Color(0xFFFFD700), // لون ذهبي
                        width: 2,
                      ),
                      boxShadow: [
                        // ظل ذهبي خفيف
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                        // ظل أسود للعمق
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            // خلفية ذهبية شفافة للأيقونة
                            color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.4), width: 1),
                          ),
                          child: Icon(widget.icon, color: const Color(0xFFFFD700), size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                              shadows: [
                                // ظل للنص لجعله أوضح
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.8),
                                  offset: const Offset(1, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.close, color: const Color(0xFFFFD700), size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
