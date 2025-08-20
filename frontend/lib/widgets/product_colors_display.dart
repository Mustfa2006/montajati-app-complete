import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
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
  bool _isLoading = true;
  ProductColor? _selectedColor;

  late AnimationController _mainAnimationController;
  late AnimationController _shimmerAnimationController;

  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.selectedColor;
    
    // إعداد الأنيميشن الرئيسي
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // تم حذف أنيميشن النبض
    
    // إعداد أنيميشن التألق
    _shimmerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
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

    // تم حذف أنيميشن النبض

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerAnimationController,
      curve: Curves.easeInOut,
    ));

    _loadColors();
    _startAnimations();
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _shimmerAnimationController.dispose();
    super.dispose();
  }

  void _startAnimations() {
    _mainAnimationController.forward();
    _shimmerAnimationController.repeat();
  }

  Future<void> _loadColors() async {
    setState(() => _isLoading = true);
    
    final colors = await SmartColorsService.getProductColors(
      productId: widget.productId,
      includeUnavailable: false, // إخفاء الألوان غير المتوفرة
    );
    
    setState(() {
      _colors = colors;
      _isLoading = false;
      
      // اختيار أول لون متاح تلقائياً إذا لم يكن هناك لون مختار
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
    
    // تأثير اهتزاز خفيف
    _mainAnimationController.reset();
    _mainAnimationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

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
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF16213e),
                    const Color(0xFF1a1a2e),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: const Color(0xFFffd700).withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFffd700).withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الصف الذي يحتوي على العنوان والألوان
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // الألوان على اليسار
                      Expanded(
                        child: _buildColorsGrid(),
                      ),
                      const SizedBox(width: 20),
                      // عنوان "الألوان" على اليمين في الوسط
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFFffd700).withValues(alpha: 0.15),
                              const Color(0xFFffd700).withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFFffd700).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'الألوان',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFffd700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }





  Widget _buildColorsGrid() {
    return AnimationLimiter(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5, // 5 مستطيلات صغيرة في الصف
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.6, // مستطيلات صغيرة وعريضة
        ),
        itemCount: _colors.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 800),
            columnCount: 3,
            child: SlideAnimation(
              verticalOffset: 100.0,
              child: FadeInAnimation(
                child: ScaleAnimation(
                  scale: 0.8,
                  child: _buildFantasticColorItem(_colors[index], index),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 🎨 تصميم خيالي وفخم للمستطيل اللوني
  Widget _buildFantasticColorItem(ProductColor color, int index) {
    final isSelected = _selectedColor?.id == color.id;
    final isAvailable = color.isAvailable;

    return GestureDetector(
      onTap: isAvailable ? () => _selectColor(color) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(isSelected ? 0.02 : 0.0)
          ..scale(isSelected ? 1.02 : 1.0),
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
            stops: const [0.0, 0.5, 1.0],
          ),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFffd700)
                : Colors.white.withValues(alpha: 0.2),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            // ظل ناعم ومريح للعين
            BoxShadow(
              color: color.flutterColor.withValues(alpha: 0.25),
              blurRadius: isSelected ? 12 : 6,
              offset: Offset(0, isSelected ? 6 : 3),
            ),
            // ظل بسيط للمختار
            if (isSelected)
              BoxShadow(
                color: const Color(0xFFffd700).withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Stack(
          children: [
            // تأثير لمعة ناعمة
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.08),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.05),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),

            // مؤشر التحديد البسيط والأنيق
            if (isSelected)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFffd700),
                        Color(0xFFffed4e),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFffd700).withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.star,
                    color: Colors.black,
                    size: 12,
                  ),
                ),
              ),

            // تأثير عدم التوفر البسيط والواضح
            if (!isAvailable)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.black.withValues(alpha: 0.75),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        FontAwesomeIcons.xmark,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const CircularProgressIndicator(color: Color(0xFFffd700)),
          const SizedBox(height: 15),
          Text(
            'جاري تحميل الألوان...',
            style: GoogleFonts.cairo(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            FontAwesomeIcons.palette,
            color: Colors.white54,
            size: 40,
          ),
          const SizedBox(height: 15),
          Text(
            'لا توجد ألوان متاحة',
            style: GoogleFonts.cairo(
              color: Colors.white54,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'سيتم إضافة الألوان قريباً',
            style: GoogleFonts.cairo(
              color: Colors.white38,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
