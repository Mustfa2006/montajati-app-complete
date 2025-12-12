import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/edit_order_provider.dart';

class SaveButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const SaveButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    // Listen to changes (isLoading, isSaving) for UI state
    final provider = Provider.of<EditOrderProvider>(context);

    // If saving, disable button logic is handled by parent passing null or us checking state?
    // Parent should pass logic. We just render state.
    // If provider is saving, we show loading.

    final isEnabled = !provider.isSaving && !provider.isLoadingOrder;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: const Color(0xFFffd700).withValues(alpha: 0.1), blurRadius: 5, spreadRadius: 1)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(
              decoration: BoxDecoration(color: const Color(0xFFffd700), borderRadius: BorderRadius.circular(15)),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: isEnabled ? onPressed : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (provider.isSaving) ...[
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1a1a2e)),
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 15),
                        ] else ...[
                          const Icon(Icons.save, color: Color(0xFF1a1a2e), size: 24),
                          const SizedBox(width: 15),
                        ],
                        Text(
                          provider.isSaving ? 'جاري الحفظ...' : 'حفظ التعديلات',
                          style: GoogleFonts.cairo(
                            color: const Color(0xFF1a1a2e),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
