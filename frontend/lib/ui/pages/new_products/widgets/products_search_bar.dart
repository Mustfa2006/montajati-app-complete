import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../providers/products_provider.dart';
import '../../../../core/design_system.dart';

/// شريط البحث في المنتجات
class ProductsSearchBar extends StatefulWidget {
  final bool isDark;

  const ProductsSearchBar({super.key, required this.isDark});

  @override
  State<ProductsSearchBar> createState() => _ProductsSearchBarState();
}

class _ProductsSearchBarState extends State<ProductsSearchBar> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      context.read<ProductsProvider>().search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFFFFD700).withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.15),
          width: 1.2,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: TextField(
        controller: _controller,
        onChanged: _onSearchChanged,
        textAlign: TextAlign.right,
        style: GoogleFonts.cairo(
          fontSize: 13,
          color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
          height: 1.3,
        ),
        decoration: InputDecoration(
          hintText: 'ابحث عن منتج...',
          hintStyle: GoogleFonts.cairo(
            color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey,
            fontSize: 12,
            height: 1.3,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 8, right: 12),
            child: Icon(
              Icons.search_rounded,
              color: isDark
                  ? const Color(0xFFFFD700).withValues(alpha: 0.7)
                  : AppDesignSystem.goldColor.withValues(alpha: 0.6),
              size: 22,
            ),
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? Colors.white54 : Colors.grey,
                    size: 20,
                  ),
                  onPressed: () {
                    _controller.clear();
                    context.read<ProductsProvider>().clearSearch();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

