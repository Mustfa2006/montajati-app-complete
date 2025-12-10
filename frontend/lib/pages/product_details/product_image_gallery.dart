// 🖼️ معرض صور المنتج
// Product Image Gallery Widget

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';

/// معرض الصور للمنتج مع مؤشرات التنقل
class ProductImageGallery extends StatelessWidget {
  final List<String> images;
  final int currentIndex;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;

  const ProductImageGallery({
    super.key,
    required this.images,
    required this.currentIndex,
    required this.pageController,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return SizedBox(
      height: 320,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // الصورة الرئيسية
          Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: PageView.builder(
                controller: pageController,
                onPageChanged: (index) {
                  onPageChanged(index);
                  HapticFeedback.selectionClick();
                },
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      // ظل بسيط أسفل المنتج
                      Positioned(
                        bottom: 60,
                        left: 60,
                        right: 60,
                        child: Container(
                          height: 20,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.3),
                                Colors.black.withValues(alpha: 0.1),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.6, 1.0],
                            ),
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),
                      // الصورة النظيفة
                      Center(
                        child: SizedBox(
                          width: 500,
                          height: 500,
                          child: CachedNetworkImage(
                            imageUrl: images[index],
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFD4AF37),
                                strokeWidth: 2,
                              ),
                            ),
                            errorWidget: (context, url, error) => Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.white.withValues(alpha: 0.3),
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // مؤشر الصور البسيط
          if (images.length > 1)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (index) => GestureDetector(
                    onTap: () {
                      pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: currentIndex == index ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: currentIndex == index
                            ? const Color(0xFFD4AF37)
                            : Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // زر الرجوع
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: _buildBackButton(context, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.go('/products');
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? Colors.black.withValues(alpha: 0.5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : Colors.black87,
            size: 20,
          ),
        ),
      ),
    );
  }
}

