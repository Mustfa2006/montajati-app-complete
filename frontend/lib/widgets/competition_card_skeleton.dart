import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../utils/theme_colors.dart';

/// Skeleton Loader �?�?���?�?�? �?�?�?�?�?�?�?�?
/// �?�?�?�? ���?�?�? �?�?�?�?�? �?�?�?�?�?�?�?�? �?�?�?�?�?�? UX
/// �?? �?���?�?�? �?�?�?�?�?�? �?�?���?�?�? �?���?�?�? �?�?�?�?�?�?�?�? �?�?�?�?�?�?�?�?
class CompetitionCardSkeleton extends StatelessWidget {
  final bool isDark;

  const CompetitionCardSkeleton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // �?? ��?�?�?�? Shimmer - �?�?�? �?�?�?���?�?�? �?�?�?�?�?�?�?
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    // �?? �?�?�? �?�?�?�?�?���? - �?�?�?�? �?�? �?�?�?�?�?�?�? (��?�?�? �?�? �?�?�?�?�?�?�? �?�?�?�?�? �?�? �?�?�?�?�?�?�?)
    final shimmerElementColor = isDark ? Colors.white : Colors.grey[400]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ThemeColors.cardBackground(isDark),
        boxShadow: [
          BoxShadow(color: ThemeColors.shadowColor(isDark), blurRadius: 8, offset: const Offset(0, 2)),
        ],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ThemeColors.cardBorder(isDark),
          width: 1,
        ),
      ),
      constraints: const BoxConstraints(minHeight: 104),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Optional shimmer badge to mirror "ended" chip placement
          Positioned(
            top: 0,
            left: 0,
            child: Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(16), bottomRight: Radius.circular(10)),
                ),
                child: Container(width: 46, height: 8, color: Colors.white.withValues(alpha: 0.5)),
              ),
            ),
          ),
          Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Progress Circle (Shimmer)
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: shimmerElementColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Details Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Competition Name (Shimmer)
                        Container(
                          width: double.infinity,
                          height: 13,
                          decoration: BoxDecoration(
                            color: shimmerElementColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Prize and Target Row (Shimmer)
                        Row(
                          children: [
                            // Prize Icon (Shimmer)
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: shimmerElementColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 3),
                            // Prize Text (Shimmer)
                            Container(
                              width: 60,
                              height: 12,
                              decoration: BoxDecoration(
                                color: shimmerElementColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Target Icon (Shimmer)
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: shimmerElementColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 3),
                            // Target Text (Shimmer)
                            Container(
                              width: 50,
                              height: 12,
                              decoration: BoxDecoration(
                                color: shimmerElementColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Product Row (Shimmer)
                        Row(
                          children: [
                            // Product Icon (Shimmer)
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: shimmerElementColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Product Text (Shimmer)
                            Container(
                              width: 100,
                              height: 11,
                              decoration: BoxDecoration(
                                color: shimmerElementColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // End Date Row (Shimmer)
                        Row(
                          children: [
                            // Date Icon (Shimmer)
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: shimmerElementColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Date Text (Shimmer)
                            Container(
                              width: 80,
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
