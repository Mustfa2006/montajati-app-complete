// 🎯 Cart Bottom Section - القسم السفلي الثابت
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/number_formatter.dart';

class CartBottomSection extends StatelessWidget {
  final Map<String, int> totals;
  final bool isDark;
  final VoidCallback onCompleteOrder;
  final VoidCallback onScheduleOrder;

  const CartBottomSection({
    super.key,
    required this.totals,
    required this.isDark,
    required this.onCompleteOrder,
    required this.onScheduleOrder,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.white,
            border: Border(
              top: BorderSide(color: const Color(0xFFffd700).withValues(alpha: isDark ? 0.4 : 0.5), width: 2),
            ),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // المجموع والربح
                  _buildTotalsRow(),
                  const SizedBox(height: 12),
                  // الأزرار
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Labels
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'المجموع',
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'الربح',
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),

        // Values
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              NumberFormatter.formatCurrency(totals['total'] ?? 0),
              style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFFffd700)),
            ),
            const SizedBox(height: 2),
            Text(
              NumberFormatter.formatCurrency(totals['profit'] ?? 0),
              style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF28a745)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // زر إتمام الطلب
        Expanded(
          flex: 3,
          child: _buildButton(
            onTap: onCompleteOrder,
            color: Colors.green,
            icon: FontAwesomeIcons.check,
            label: 'إتمام الطلب',
            iconColor: Colors.white,
            textColor: Colors.white,
          ),
        ),

        const SizedBox(width: 10),

        // زر جدولة الطلب
        Expanded(
          flex: 2,
          child: _buildButton(
            onTap: onScheduleOrder,
            color: const Color(0xFFffd700),
            icon: FontAwesomeIcons.calendar,
            label: 'جدولة',
            iconColor: Colors.black,
            textColor: Colors.black,
            iconSize: 13,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildButton({
    required VoidCallback onTap,
    required Color color,
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color textColor,
    double iconSize = 14,
    double fontSize = 14,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: iconSize),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.cairo(fontSize: fontSize, fontWeight: FontWeight.w700, color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
