import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../providers/products_provider.dart';

/// شريط البحث - نفس تصميم صفحة سجل السحب بالضبط
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.white.withValues(alpha: 0.08), Colors.white.withValues(alpha: 0.03)]
                    : [Colors.white.withValues(alpha: 0.9), Colors.white.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: _controller,
              onChanged: (value) {
                setState(() {});
                _onSearchChanged(value);
              },
              style: GoogleFonts.cairo(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'ابحث عن منتج...',
                hintStyle: GoogleFonts.cairo(color: isDark ? Colors.grey[400] : Colors.grey[500], fontSize: 14),
                prefixIcon: Container(
                  padding: const EdgeInsets.all(12),
                  child: const Icon(FontAwesomeIcons.magnifyingGlass, color: Color(0xFFFFC107), size: 18),
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(FontAwesomeIcons.xmark, color: Color(0xFFFFC107), size: 16),
                        onPressed: () {
                          _controller.clear();
                          context.read<ProductsProvider>().clearSearch();
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
