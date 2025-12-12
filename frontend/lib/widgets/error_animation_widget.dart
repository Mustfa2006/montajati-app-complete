import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';

/// ❌ أنيميشن الخطا بتصميم داكن فاخر (Glassmorphism)
class ErrorAnimationWidget extends StatelessWidget {
  const ErrorAnimationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // ضبابية 5 درجات
          child: Container(
            width: 320,
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            decoration: BoxDecoration(
              // خلفية شفافة داكنة
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30, spreadRadius: 10)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // الأنيميشن
                SizedBox(
                  width: 180,
                  height: 180,
                  child: Lottie.asset('assets/animations/error_animation.json', repeat: false, fit: BoxFit.contain),
                ),
                const SizedBox(height: 20),

                // النص الرئيسي
                Text(
                  "عذراً، حدث خطأ ما",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2),
                ),

                const SizedBox(height: 10),

                // نص فرعي
                Text(
                  "لم نتمكن من إتمام الطلب، يرجى المحاولة مرة أخرى",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    color: Colors.white70, // لون رمادي فاتح جيد للوضع الليلي
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
