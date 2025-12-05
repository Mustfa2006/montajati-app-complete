import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../providers/theme_provider.dart';
import 'product_card.dart';

/// حالة التحميل الرئيسية - مطابقة 100% للملف القديم
class ProductsLoading extends StatelessWidget {
  const ProductsLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    return ProductsLoadingSkeleton(isDark: isDark);
  }
}

/// Skeleton loading للمنتجات - مطابق تماماً لـ _buildSkeletonLoader في الملف القديم
class ProductsLoadingSkeleton extends StatelessWidget {
  final bool isDark;
  final int itemCount;

  const ProductsLoadingSkeleton({super.key, required this.isDark, this.itemCount = 10});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final columnCount = ProductCard.getSmartColumnCount(screenWidth);
    final aspectRatio = ProductCard.calculateOptimalAspectRatio(context, columnCount);

    final horizontalMargin = screenWidth > 600 ? 16.0 : (screenWidth > 400 ? 12.0 : 8.0);
    final crossAxisSpacing = screenWidth > 600 ? 14.0 : (screenWidth > 400 ? 10.0 : 6.0);
    final mainAxisSpacing = screenWidth > 600 ? 18.0 : (screenWidth > 400 ? 16.0 : 12.0);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: aspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => _SkeletonCard(isDark: isDark),
    );
  }
}

/// بطاقة Skeleton - مطابقة تماماً لـ _buildSkeletonLoader في الملف القديم
class _SkeletonCard extends StatelessWidget {
  final bool isDark;

  const _SkeletonCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.04),
          width: 1,
        ),
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          // منطقة الصورة مع CircularProgressIndicator ذهبي
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF5F5F7),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(17), topRight: Radius.circular(17)),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  color: const Color(0xFFffd700).withValues(alpha: 0.3),
                  strokeWidth: 1.5,
                ),
              ),
            ),
          ),
          // منطقة النص
          Expanded(
            flex: 2,
            child: Container(
              color: isDark ? Colors.transparent : Colors.white,
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // اسم المنتج
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  // السعر
                  Container(
                    height: 10,
                    width: 100,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// مؤشر تحميل المزيد
class LoadMoreIndicator extends StatelessWidget {
  const LoadMoreIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Center(child: CircularProgressIndicator(color: Color(0xFFffd700), strokeWidth: 2)),
    );
  }
}
