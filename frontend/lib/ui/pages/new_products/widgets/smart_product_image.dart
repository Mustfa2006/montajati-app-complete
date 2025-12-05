import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'bouncing_dots_loader.dart';

/// صورة منتج ذكية مع إعادة المحاولة التلقائية
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

class _SmartProductImageState extends State<SmartProductImage> {
  static const int _maxRetries = 3;
  int _retryCount = 0;
  bool _hasFailed = false;

  void _retry() {
    if (!mounted || _retryCount >= _maxRetries) {
      if (mounted) setState(() => _hasFailed = true);
      return;
    }
    setState(() => _retryCount++);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasFailed) {
      return Container(
        height: widget.height,
        color: widget.isDark
            ? Colors.white.withValues(alpha: 0.02)
            : Colors.grey.withValues(alpha: 0.05),
        child: Center(
          child: GestureDetector(
            onTap: () => setState(() {
              _retryCount = 0;
              _hasFailed = false;
            }),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.refresh_rounded,
                  color: widget.isDark ? Colors.white38 : Colors.grey[400],
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  'اضغط للتحديث',
                  style: TextStyle(
                    fontSize: 9,
                    color: widget.isDark ? Colors.white38 : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      cacheKey: widget.imageUrl,
      fit: widget.fit,
      width: double.infinity,
      height: widget.height,
      httpHeaders: const {'Connection': 'keep-alive'},
      placeholder: (context, url) => Container(
        height: widget.height,
        color: widget.isDark
            ? Colors.white.withValues(alpha: 0.02)
            : Colors.grey.withValues(alpha: 0.05),
        child: Center(child: BouncingDotsLoader(isDark: widget.isDark)),
      ),
      errorWidget: (context, url, error) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _retry();
        });
        return Container(
          height: widget.height,
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.02)
              : Colors.grey.withValues(alpha: 0.05),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BouncingDotsLoader(isDark: widget.isDark, size: 6),
              const SizedBox(height: 6),
              Text(
                'جاري المحاولة ${_retryCount + 1}/$_maxRetries',
                style: TextStyle(
                  fontSize: 8,
                  color: widget.isDark ? Colors.white30 : Colors.grey[400],
                ),
              ),
            ],
          ),
        );
      },
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
    );
  }
}

