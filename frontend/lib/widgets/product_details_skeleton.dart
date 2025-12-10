// 🦴 Skeleton Loading لصفحة تفاصيل المنتج
// Product Details Skeleton Loader Widget

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton Loader لصفحة تفاصيل المنتج
/// يظهر أثناء تحميل البيانات لتحسين تجربة المستخدم
/// ✅ مطابق تماماً لتصميم صفحة تفاصيل المنتج الحقيقية
class ProductDetailsSkeleton extends StatelessWidget {
  final bool isDark;

  const ProductDetailsSkeleton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // ✅ ألوان Shimmer - نفس التصميم للوضعين
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;
    final shimmerElementColor = isDark ? Colors.white : Colors.grey[400]!;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          children: [
            const SizedBox(height: 10),

            // 📷 منطقة الصورة - Skeleton
            _buildImageSkeleton(screenWidth, screenHeight, shimmerElementColor),

            const SizedBox(height: 10),

            // 📦 بطاقة تفاصيل المنتج - Skeleton
            _buildDetailsCardSkeleton(screenWidth, shimmerElementColor),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 📷 Skeleton لمنطقة الصورة
  Widget _buildImageSkeleton(double screenWidth, double screenHeight, Color shimmerColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: screenHeight * 0.42,
      decoration: BoxDecoration(
        color: shimmerColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!, width: 1.5),
      ),
      child: Stack(
        children: [
          // مؤشرات الصور (النقاط)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: index == 0 ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.grey[400],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 📦 Skeleton لبطاقة التفاصيل
  Widget _buildDetailsCardSkeleton(double screenWidth, Color shimmerColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        color: isDark ? Colors.transparent : Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(50), topRight: Radius.circular(50)),
        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(50), topRight: Radius.circular(50)),
        child: isDark
            ? BackdropFilter(filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3), child: _buildDetailsContent(shimmerColor))
            : _buildDetailsContent(shimmerColor),
      ),
    );
  }

  // محتوى التفاصيل
  Widget _buildDetailsContent(Color shimmerColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان المنتج - Skeleton
          _buildTitleSkeleton(shimmerColor),

          const SizedBox(height: 20),

          // شريط الألوان والكمية - Skeleton
          _buildColorQuantityBarSkeleton(shimmerColor),

          const SizedBox(height: 20),

          // قسم السعر - Skeleton
          _buildPriceSectionSkeleton(shimmerColor),

          const SizedBox(height: 20),

          // الوصف - Skeleton
          _buildDescriptionSkeleton(shimmerColor),

          const SizedBox(height: 80), // مساحة للزر
        ],
      ),
    );
  }

  // عنوان المنتج - Skeleton
  Widget _buildTitleSkeleton(Color shimmerColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // اسم المنتج
        Container(
          width: double.infinity,
          height: 22,
          decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(6)),
        ),
        const SizedBox(height: 8),
        // سطر ثاني من العنوان
        Container(
          width: 200,
          height: 18,
          decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(6)),
        ),
      ],
    );
  }

  // شريط الألوان والكمية - Skeleton
  Widget _buildColorQuantityBarSkeleton(Color shimmerColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!, width: 1),
      ),
      child: Row(
        children: [
          // قسم الألوان
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // عنوان "الألوان"
                Container(
                  width: 60,
                  height: 14,
                  decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(height: 10),
                // دوائر الألوان
                Row(
                  children: List.generate(
                    4,
                    (index) => Container(
                      margin: const EdgeInsets.only(left: 8),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(color: shimmerColor, shape: BoxShape.circle),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // فاصل
          Container(width: 1, height: 50, color: isDark ? Colors.grey[700] : Colors.grey[300]),

          // قسم الكمية
          Expanded(
            child: Column(
              children: [
                // عنوان "الكمية"
                Container(
                  width: 50,
                  height: 14,
                  decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(height: 10),
                // أزرار الكمية
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // زر -
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(6)),
                    ),
                    const SizedBox(width: 12),
                    // الرقم
                    Container(
                      width: 24,
                      height: 20,
                      decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4)),
                    ),
                    const SizedBox(width: 12),
                    // زر +
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(6)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // قسم السعر - Skeleton
  Widget _buildPriceSectionSkeleton(Color shimmerColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // بطاقة نطاق الأسعار
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!, width: 1),
          ),
          child: Column(
            children: [
              // سعر الجملة
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(color: shimmerColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 80,
                    height: 14,
                    decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 60,
                    height: 14,
                    decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // الحد الأدنى والأعلى
              Row(
                children: [
                  Expanded(child: _buildPriceBoxSkeleton(shimmerColor)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildPriceBoxSkeleton(shimmerColor)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // عنوان "سعر البيع للزبون"
        Container(
          width: 120,
          height: 16,
          decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(height: 12),

        // حقل إدخال السعر
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!, width: 1),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(color: shimmerColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              // زر التثبيت
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // الأسعار المثبتة
        Container(
          width: 100,
          height: 14,
          decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(
            3,
            (index) => Container(
              margin: const EdgeInsets.only(left: 8),
              width: 80,
              height: 28,
              decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  // مربع السعر الصغير - Skeleton
  Widget _buildPriceBoxSkeleton(Color shimmerColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(color: shimmerColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Container(
                width: 60,
                height: 12,
                decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            width: 70,
            height: 16,
            decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4)),
          ),
        ],
      ),
    );
  }

  // الوصف - Skeleton
  Widget _buildDescriptionSkeleton(Color shimmerColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان "الوصف"
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(color: shimmerColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Container(
                width: 50,
                height: 16,
                decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // سطور الوصف
          ...List.generate(
            4,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                width: index == 3 ? 150 : double.infinity,
                height: 14,
                decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
