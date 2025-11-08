import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product_color.dart';
import '../services/smart_colors_service.dart';

/// 🎨 عرض ألوان المنتج - التصميم الأكثر إبداعاً وتطوراً في العالم
class ProductColorsDisplay extends StatefulWidget {
  final String productId;
  final Function(ProductColor)? onColorSelected;
  final ProductColor? selectedColor;

  const ProductColorsDisplay({
    super.key,
    required this.productId,
    this.onColorSelected,
    this.selectedColor,
  });

  @override
  State<ProductColorsDisplay> createState() => _ProductColorsDisplayState();
}

class _ProductColorsDisplayState extends State<ProductColorsDisplay>
    with TickerProviderStateMixin {
  List<ProductColor> _colors = [];
  ProductColor? _selectedColor;

  late AnimationController _mainAnimationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.selectedColor;

    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: Curves.easeInOut,
    ));

    _loadColors();
    _startAnimations();
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    super.dispose();
  }

  void _startAnimations() {
    _mainAnimationController.forward();
  }

  Future<void> _loadColors() async {
    final colors = await SmartColorsService.getProductColors(
      productId: widget.productId,
      includeUnavailable: false,
    );

    setState(() {
      _colors = colors;

      if (_selectedColor == null && colors.isNotEmpty) {
        _selectedColor = colors.first;
        widget.onColorSelected?.call(colors.first);
      }
    });
  }

  void _selectColor(ProductColor color) {
    if (!color.isAvailable) return;

    setState(() {
      _selectedColor = color;
    });

    widget.onColorSelected?.call(color);

    _mainAnimationController.reset();
    _mainAnimationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    if (_colors.isEmpty) {
      return _buildEmptyState();
    }

    return AnimatedBuilder(
      animation: _mainAnimationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: _buildColorsGrid(),
          ),
        );
      },
    );
  }

  Widget _buildColorsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.6,
      ),
      itemCount: _colors.length,
      itemBuilder: (context, index) {
        return _buildFantasticColorItem(_colors[index], index);
      },
    );
  }

  Widget _buildFantasticColorItem(ProductColor color, int index) {
    final isSelected = _selectedColor?.id == color.id;

    return GestureDetector(
      onTap: () => _selectColor(color),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.flutterColor.withValues(alpha: 0.95),
              color.flutterColor,
              color.flutterColor.withValues(alpha: 0.9),
            ],
          ),
          border: Border.all(
            color: isSelected ? const Color(0xFFffd700) : Colors.white,
            width: isSelected ? 2.5 : 1,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'لا توجد ألوان متاحة',
        style: GoogleFonts.cairo(
          color: Colors.white54,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
