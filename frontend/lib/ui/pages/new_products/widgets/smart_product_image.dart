import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'bouncing_dots_loader.dart';

/// صورة منتج ذكية مع إعادة المحاولة التلقائية ومراقبة الاتصال
class SmartProductImage extends StatefulWidget {
  final String imageUrl;
  final double height;
  final bool isDark;
  final BoxFit fit;

  const SmartProductImage({
    super.key,
    required this.imageUrl,
    required this.height,
    required this.isDark,
    this.fit = BoxFit.cover,
  });

  @override
  State<SmartProductImage> createState() => _SmartProductImageState();
}

class _SmartProductImageState extends State<SmartProductImage> with WidgetsBindingObserver {
  static const int _maxRetries = 5;
  static const Duration _retryDelay = Duration(seconds: 3);
  static const Duration _connectivityCheckDelay = Duration(seconds: 2);

  int _retryCount = 0;
  bool _hasFailed = false;
  bool _imageLoaded = false;

  // مفتاح فريد لإجبار إعادة بناء الـ Widget
  Key _imageKey = UniqueKey();

  Timer? _retryTimer;
  Timer? _connectivityTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startConnectivityCheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _retryTimer?.cancel();
    _connectivityTimer?.cancel();
    super.dispose();
  }

  /// مراقبة حالة التطبيق - عند العودة للتطبيق يفحص الاتصال
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_imageLoaded && mounted) {
      _checkAndReload();
    }
  }

  /// فحص دوري للاتصال إذا الصورة لم تحمل
  void _startConnectivityCheck() {
    _connectivityTimer?.cancel();
    _connectivityTimer = Timer.periodic(_connectivityCheckDelay, (_) {
      if (!_imageLoaded && mounted && !_hasFailed) {
        _checkAndReload();
      } else if (_imageLoaded) {
        _connectivityTimer?.cancel();
      }
    });
  }

  /// فحص الاتصال وإعادة التحميل إذا أصبح متاحاً
  Future<void> _checkAndReload() async {
    if (_imageLoaded || !mounted) return;

    try {
      final result = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 2));

      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        // الإنترنت متاح - إعادة التحميل
        if (!_imageLoaded && mounted) {
          debugPrint('🌐 الإنترنت متاح! إعادة تحميل الصورة');
          _forceReload();
        }
      }
    } catch (_) {
      // لا يوجد اتصال - الاستمرار في الفحص
    }
  }

  /// إعادة تحميل إجبارية مع مفتاح جديد
  void _forceReload() {
    if (!mounted) return;

    _retryTimer?.cancel();
    setState(() {
      _retryCount = 0;
      _hasFailed = false;
      _imageKey = UniqueKey();
    });
  }

  /// إعادة المحاولة مع تأخير
  void _scheduleRetry() {
    if (!mounted || _retryCount >= _maxRetries) {
      if (mounted) {
        setState(() => _hasFailed = true);
      }
      return;
    }

    _retryTimer?.cancel();
    _retryTimer = Timer(_retryDelay, () {
      if (mounted && !_imageLoaded) {
        setState(() {
          _retryCount++;
          _imageKey = UniqueKey();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasFailed) {
      return _buildFailedState();
    }

    return CachedNetworkImage(
      key: _imageKey,
      imageUrl: widget.imageUrl,
      cacheKey: '${widget.imageUrl}_v$_retryCount',
      fit: widget.fit,
      width: double.infinity,
      height: widget.height,
      httpHeaders: const {'Connection': 'keep-alive', 'Cache-Control': 'no-cache'},
      useOldImageOnUrlChange: false,

      placeholder: (context, url) => _buildLoadingState(),

      imageBuilder: (context, imageProvider) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_imageLoaded) {
            _imageLoaded = true;
            _connectivityTimer?.cancel();
            _retryTimer?.cancel();
          }
        });

        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            image: DecorationImage(image: imageProvider, fit: widget.fit),
          ),
        );
      },

      errorWidget: (context, url, error) {
        debugPrint('❌ فشل تحميل الصورة: ${_retryCount + 1}/$_maxRetries');

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scheduleRetry();
        });

        return _buildRetryingState();
      },

      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: widget.height,
      color: widget.isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.withValues(alpha: 0.05),
      child: Center(child: BouncingDotsLoader(isDark: widget.isDark)),
    );
  }

  Widget _buildRetryingState() {
    return Container(
      height: widget.height,
      color: widget.isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.withValues(alpha: 0.05),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BouncingDotsLoader(isDark: widget.isDark, size: 6),
          const SizedBox(height: 6),
          Text(
            'جاري المحاولة ${_retryCount + 1}/$_maxRetries',
            style: TextStyle(fontSize: 8, color: widget.isDark ? Colors.white30 : Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedState() {
    return Container(
      height: widget.height,
      color: widget.isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.withValues(alpha: 0.05),
      child: Center(
        child: GestureDetector(
          onTap: _forceReload,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.refresh_rounded, color: widget.isDark ? Colors.white38 : Colors.grey[400], size: 24),
              const SizedBox(height: 4),
              Text(
                'اضغط للتحديث',
                style: TextStyle(fontSize: 9, color: widget.isDark ? Colors.white38 : Colors.grey[400]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
