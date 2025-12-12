import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/theme_provider.dart';

class EditOrderHeader extends StatelessWidget {
  const EditOrderHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1a1a2e) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.2), width: 1),
            boxShadow: isDark
                ? []
                : [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              // Back Button
              GestureDetector(
                onTap: () => GoRouter.of(context).go('/orders'),
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : const Color(0xFFffd700).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.3)
                          : const Color(0xFFffd700).withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Icon(Icons.arrow_back, color: isDark ? Colors.white : const Color(0xFFffd700), size: 18),
                ),
              ),

              // Title
              Expanded(
                child: Center(
                  child: Text(
                    'تعديل الطلب',
                    style: GoogleFonts.cairo(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Balance Space
              const SizedBox(width: 45),
            ],
          ),
        ),
      ),
    );
  }
}
