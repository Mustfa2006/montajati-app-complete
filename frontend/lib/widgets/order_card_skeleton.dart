import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton Loader لبطاقة الطلب
/// يظهر أثناء تحميل البيانات لتحسين UX
/// ✅ مطابق تماماً لتصميم بطاقة الطلب الحقيقية
class OrderCardSkeleton extends StatelessWidget {
  final bool isDark;

  const OrderCardSkeleton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // ✅ ألوان Shimmer - نفس التصميم للوضعين
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    // ✅ لون العناصر - واضح في الوضعين (أبيض في الليلي، رمادي في النهاري)
    final shimmerElementColor = isDark ? Colors.white : Colors.grey[400]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: 145,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          // خلفية بيضاء في الوضع النهاري، شفافة في الوضع الليلي
          color: isDark ? Colors.transparent : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            width: isDark ? 2.5 : 2.0, // ✅ تثخين الإطار مثل البطاقة الحقيقية
          ),
          // ظلال محسّنة
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: Colors.grey[800]!.withValues(alpha: 0.15),
                    blurRadius: 0,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                    spreadRadius: 1,
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الصف الأول - معلومات الزبون مع الصورة
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // معلومات الزبون
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // اسم الزبون (Shimmer)
                        Container(
                          width: double.infinity,
                          height: 14,
                          decoration: BoxDecoration(color: shimmerElementColor, borderRadius: BorderRadius.circular(4)),
                        ),
                        const SizedBox(height: 6),

                        // رقم الهاتف (Shimmer)
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(color: shimmerElementColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 100,
                              height: 12,
                              decoration: BoxDecoration(
                                color: shimmerElementColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // العنوان (Shimmer)
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(color: shimmerElementColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 120,
                              height: 11,
                              decoration: BoxDecoration(
                                color: shimmerElementColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // صورة المنتج (Shimmer)
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(color: shimmerElementColor, borderRadius: BorderRadius.circular(8)),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // الصف الثاني - حالة الطلب (Shimmer)
              Center(
                child: Container(
                  width: 100,
                  height: 24,
                  decoration: BoxDecoration(color: shimmerElementColor, borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const Spacer(),

              // الصف الثالث - المعلومات المالية والتاريخ (Shimmer)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // السعر (Shimmer)
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(color: shimmerElementColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 70,
                        height: 13,
                        decoration: BoxDecoration(color: shimmerElementColor, borderRadius: BorderRadius.circular(4)),
                      ),
                    ],
                  ),

                  // التاريخ (Shimmer)
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(color: shimmerElementColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 80,
                        height: 13,
                        decoration: BoxDecoration(color: shimmerElementColor, borderRadius: BorderRadius.circular(4)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
