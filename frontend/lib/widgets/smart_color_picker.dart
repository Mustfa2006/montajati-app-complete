import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/product_color.dart';
import '../services/smart_colors_service.dart';

/// 🎨 أداة اختيار الألوان الذكية - التصميم الأقوى والأكثر تطوراً
class SmartColorPicker extends StatefulWidget {
  final Function(List<ProductColorInput>) onColorsChanged;
  final List<ProductColorInput>? initialColors;

  const SmartColorPicker({
    super.key,
    required this.onColorsChanged,
    this.initialColors,
  });

  @override
  State<SmartColorPicker> createState() => _SmartColorPickerState();
}

class _SmartColorPickerState extends State<SmartColorPicker>
    with TickerProviderStateMixin {
  List<ProductColorInput> _selectedColors = [];
  List<PredefinedColor> _predefinedColors = [];
  List<PredefinedColor> _filteredColors = [];
  bool _isLoading = true;
  // String _searchQuery = ''; // غير مستخدم حالياً
  bool _showPopularOnly = true;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _selectedColors = widget.initialColors ?? [];
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _loadPredefinedColors();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPredefinedColors() async {
    setState(() => _isLoading = true);
    
    final colors = await SmartColorsService.getPredefinedColors(
      popularOnly: _showPopularOnly,
    );
    
    setState(() {
      _predefinedColors = colors;
      _filteredColors = colors;
      _isLoading = false;
    });
  }

  void _filterColors(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredColors = _predefinedColors;
      } else {
        _filteredColors = _predefinedColors
            .where((color) =>
                color.colorArabicName.contains(query) ||
                color.colorName.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _addColor(PredefinedColor predefinedColor) {
    // التحقق من عدم تكرار اللون
    if (_selectedColors.any((c) => c.colorCode == predefinedColor.colorCode)) {
      _showMessage('هذا اللون مضاف بالفعل', Colors.orange);
      return;
    }

    setState(() {
      _selectedColors.add(ProductColorInput(
        colorName: predefinedColor.colorName,
        colorCode: predefinedColor.colorCode,
        colorArabicName: predefinedColor.colorArabicName,
        quantity: 10, // كمية افتراضية
      ));
    });

    widget.onColorsChanged(_selectedColors);
    _showMessage('تم إضافة اللون ${predefinedColor.colorArabicName}', Colors.green);
  }

  void _removeColor(int index) {
    setState(() {
      _selectedColors.removeAt(index);
    });
    widget.onColorsChanged(_selectedColors);
    _showMessage('تم حذف اللون', Colors.red);
  }

  void _updateColorQuantity(int index, int quantity) {
    setState(() {
      _selectedColors[index] = _selectedColors[index].copyWith(quantity: quantity);
    });
    widget.onColorsChanged(_selectedColors);
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.cairo(color: Colors.white),
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF16213e),
                borderRadius: BorderRadius.circular(20),
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
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildSearchAndFilter(),
                  const SizedBox(height: 20),
                  _buildSelectedColors(),
                  const SizedBox(height: 20),
                  _buildColorGrid(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFffd700).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            FontAwesomeIcons.palette,
            color: Color(0xFFffd700),
            size: 24,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ألوان المنتج',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFffd700),
                ),
              ),
              Text(
                'اختر الألوان المتاحة وحدد كمية كل لون',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFffd700).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFffd700).withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            '${_selectedColors.length} لون',
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFffd700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a2e),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: const Color(0xFFffd700).withValues(alpha: 0.3),
              ),
            ),
            child: TextField(
              style: GoogleFonts.cairo(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'البحث في الألوان...',
                hintStyle: GoogleFonts.cairo(color: Colors.white54),
                prefixIcon: const Icon(
                  FontAwesomeIcons.magnifyingGlass,
                  color: Color(0xFFffd700),
                  size: 18,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(15),
              ),
              onChanged: _filterColors,
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            setState(() {
              _showPopularOnly = !_showPopularOnly;
            });
            _loadPredefinedColors();
          },
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: _showPopularOnly
                  ? const Color(0xFFffd700).withValues(alpha: 0.2)
                  : const Color(0xFF1a1a2e),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: const Color(0xFFffd700).withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              FontAwesomeIcons.star,
              color: _showPopularOnly
                  ? const Color(0xFFffd700)
                  : Colors.white54,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedColors() {
    if (_selectedColors.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a2e),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              FontAwesomeIcons.circleInfo,
              color: Colors.white54,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              'لم يتم اختيار أي ألوان بعد',
              style: GoogleFonts.cairo(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الألوان المختارة',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _selectedColors.asMap().entries.map((entry) {
            final index = entry.key;
            final color = entry.value;
            return _buildSelectedColorChip(color, index);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSelectedColorChip(ProductColorInput color, int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: color.flutterColor.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.flutterColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    color.colorArabicName.substring(0, 1),
                    style: GoogleFonts.cairo(
                      color: color.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                color.colorArabicName,
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _removeColor(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    FontAwesomeIcons.xmark,
                    color: Colors.red,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  if (color.quantity > 1) {
                    _updateColorQuantity(index, color.quantity - 1);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    FontAwesomeIcons.minus,
                    color: Colors.red,
                    size: 10,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFffd700).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${color.quantity}',
                  style: GoogleFonts.cairo(
                    color: const Color(0xFFffd700),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _updateColorQuantity(index, color.quantity + 1),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    FontAwesomeIcons.plus,
                    color: Colors.green,
                    size: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorGrid() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFffd700)),
      );
    }

    if (_filteredColors.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              FontAwesomeIcons.palette,
              color: Colors.white54,
              size: 40,
            ),
            const SizedBox(height: 10),
            Text(
              'لا توجد ألوان متاحة',
              style: GoogleFonts.cairo(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: _filteredColors.length,
      itemBuilder: (context, index) {
        final color = _filteredColors[index];
        final isSelected = _selectedColors.any((c) => c.colorCode == color.colorCode);
        
        return GestureDetector(
          onTap: isSelected ? null : () => _addColor(color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: color.flutterColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFffd700)
                    : Colors.white.withValues(alpha: 0.3),
                width: isSelected ? 3 : 1,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: const Color(0xFFffd700).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    color.colorArabicName,
                    style: GoogleFonts.cairo(
                      color: color.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFffd700),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        FontAwesomeIcons.check,
                        color: Color(0xFF1a1a2e),
                        size: 10,
                      ),
                    ),
                  ),
                if (color.isPopular)
                  Positioned(
                    top: 5,
                    left: 5,
                    child: Icon(
                      FontAwesomeIcons.star,
                      color: Colors.yellow.withValues(alpha: 0.8),
                      size: 12,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 🎨 نموذج إدخال لون المنتج
class ProductColorInput {
  final String colorName;
  final String colorCode;
  final String colorArabicName;
  final int quantity;

  ProductColorInput({
    required this.colorName,
    required this.colorCode,
    required this.colorArabicName,
    required this.quantity,
  });

  Color get flutterColor {
    try {
      String hexColor = colorCode.replaceAll('#', '');
      if (hexColor.length == 6) {
        return Color(int.parse('FF$hexColor', radix: 16));
      }
      return Colors.grey;
    } catch (e) {
      return Colors.grey;
    }
  }

  Color get textColor {
    final color = flutterColor;
    final brightness = ThemeData.estimateBrightnessForColor(color);
    return brightness == Brightness.dark ? Colors.white : Colors.black;
  }

  ProductColorInput copyWith({
    String? colorName,
    String? colorCode,
    String? colorArabicName,
    int? quantity,
  }) {
    return ProductColorInput(
      colorName: colorName ?? this.colorName,
      colorCode: colorCode ?? this.colorCode,
      colorArabicName: colorArabicName ?? this.colorArabicName,
      quantity: quantity ?? this.quantity,
    );
  }
}
