import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/product.dart';

/// ويدجت شريط التبليغات
class NotificationBar extends StatelessWidget {
  final Product product;

  const NotificationBar({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final tags = product.notificationTags;
    if (tags.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6B73FF).withValues(alpha: 0.9),
            const Color(0xFF9D4EDD).withValues(alpha: 0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(17),
          bottomLeft: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B73FF).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.campaign_rounded, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            tags.first,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

