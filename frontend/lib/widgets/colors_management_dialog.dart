import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/product_color.dart';
import '../services/smart_colors_service.dart';

/// 🎨 نافذة إدارة الألوان المتطورة - الأقوى في العالم
class ColorsManagementDialog extends StatefulWidget {
  final String productId;
  final String productName;
  final List<ProductColor> initialColors;
  final VoidCallback? onColorsUpdated;

  const ColorsManagementDialog({
    super.key,
    required this.productId,
    required this.productName,
    required this.initialColors,
    this.onColorsUpdated,
  });

  @override
  State<ColorsManagementDialog> createState() => _ColorsManagementDialogState();
}

class _ColorsManagementDialogState extends State<ColorsManagementDialog>
    with TickerProviderStateMixin {
  List<ProductColor> _colors = [];
  List<PredefinedColor> _predefinedColors = [];
  bool _isLoading = false;
  // String _searchQuery = ''; // غير مستخدم حالياً

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _colors = List.from(widget.initialColors);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
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
    
    final colors = await SmartColorsService.getPredefinedColors();
    
    setState(() {
      _predefinedColors = colors;
      _isLoading = false;
    });
  }

  Future<void> _addColor(PredefinedColor predefinedColor) async {
    // التحقق من عدم تكرار اللون
    if (_colors.any((c) => c.colorCode == predefinedColor.colorCode)) {
      _showMessage('هذا اللون موجود بالفعل', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    final result = await SmartColorsService.addColorToProduct(
      productId: widget.productId,
      colorName: predefinedColor.colorName,
      colorCode: predefinedColor.colorCode,
      colorArabicName: predefinedColor.colorArabicName,
      totalQuantity: 10, // كمية افتراضية
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      // إعادة تحميل الألوان
      await _refreshColors();
      _showMessage('تم إضافة اللون ${predefinedColor.colorArabicName}', Colors.green);
    } else {
      _showMessage('فشل في إضافة اللون: ${result['error']}', Colors.red);
    }
  }

  Future<void> _updateColorQuantity(ProductColor color, int newQuantity) async {
    setState(() => _isLoading = true);

    final result = await SmartColorsService.updateColorQuantity(
      colorId: color.id,
      newQuantity: newQuantity,
      reason: 'تحديث من لوحة التحكم',
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      await _refreshColors();
      _showMessage('تم تحديث كمية ${color.colorArabicName}', Colors.green);
    } else {
      _showMessage('فشل في تحديث الكمية: ${result['error']}', Colors.red);
    }
  }

  Future<void> _deleteColor(ProductColor color) async {
    // تأكيد الحذف
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: Text(
          'تأكيد الحذف',
          style: GoogleFonts.cairo(color: const Color(0xFFffd700)),
        ),
        content: Text(
          'هل أنت متأكد من حذف اللون "${color.colorArabicName}"؟',
          style: GoogleFonts.cairo(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('حذف', style: GoogleFonts.cairo(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    final result = await SmartColorsService.deleteProductColor(
      colorId: color.id,
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      await _refreshColors();
      _showMessage('تم حذف اللون ${color.colorArabicName}', Colors.green);
    } else {
      _showMessage('فشل في حذف اللون: ${result['error']}', Colors.red);
    }
  }

  Future<void> _refreshColors() async {
    final colors = await SmartColorsService.getProductColors(
      productId: widget.productId,
      includeUnavailable: true,
    );
    
    setState(() {
      _colors = colors;
    });
    
    widget.onColorsUpdated?.call();
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
        return ScaleTransition(
          scale: _scaleAnimation,
          child: AlertDialog(
            backgroundColor: const Color(0xFF1a1a2e),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFffd700).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    FontAwesomeIcons.palette,
                    color: Color(0xFFffd700),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إدارة الألوان',
                        style: GoogleFonts.cairo(
                          color: const Color(0xFFffd700),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        widget.productName,
                        style: GoogleFonts.cairo(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 600,
              height: 500,
              child: Column(
                children: [
                  _buildCurrentColors(),
                  const SizedBox(height: 20),
                  _buildAddColorSection(),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'إغلاق',
                  style: GoogleFonts.cairo(color: Colors.grey),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentColors() {
    return Expanded(
      flex: 2,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFF16213e),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFffd700).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الألوان الحالية (${_colors.length})',
              style: GoogleFonts.cairo(
                color: const Color(0xFFffd700),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 15),
            
            if (_colors.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        FontAwesomeIcons.palette,
                        color: Colors.grey[400],
                        size: 40,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'لا توجد ألوان',
                        style: GoogleFonts.cairo(
                          color: Colors.grey[400],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _colors.length,
                  itemBuilder: (context, index) {
                    final color = _colors[index];
                    return _buildColorItem(color);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorItem(ProductColor color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.flutterColor.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          // عينة اللون
          Container(
            width: 40,
            height: 40,
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
                  fontSize: 14,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // معلومات اللون
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  color.colorArabicName,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'متوفر: ${color.availableQuantity} | المجموع: ${color.totalQuantity}',
                  style: GoogleFonts.cairo(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // أزرار التحكم
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _showQuantityDialog(color),
                icon: const Icon(
                  FontAwesomeIcons.penToSquare,
                  color: Color(0xFFffd700),
                  size: 16,
                ),
                tooltip: 'تعديل الكمية',
              ),
              IconButton(
                onPressed: () => _deleteColor(color),
                icon: const Icon(
                  FontAwesomeIcons.trash,
                  color: Colors.red,
                  size: 16,
                ),
                tooltip: 'حذف اللون',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddColorSection() {
    return Expanded(
      flex: 1,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFF16213e),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFffd700).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إضافة لون جديد',
              style: GoogleFonts.cairo(
                color: const Color(0xFFffd700),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 15),
            
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Color(0xFFffd700)),
              )
            else
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: _predefinedColors.length,
                  itemBuilder: (context, index) {
                    final color = _predefinedColors[index];
                    final isAlreadyAdded = _colors.any((c) => c.colorCode == color.colorCode);
                    
                    return GestureDetector(
                      onTap: isAlreadyAdded ? null : () => _addColor(color),
                      child: Container(
                        decoration: BoxDecoration(
                          color: color.flutterColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isAlreadyAdded
                                ? Colors.grey
                                : Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Text(
                                color.colorArabicName.substring(0, 1),
                                style: GoogleFonts.cairo(
                                  color: color.textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            if (isAlreadyAdded)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Icon(
                                    FontAwesomeIcons.check,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showQuantityDialog(ProductColor color) {
    final controller = TextEditingController(text: color.totalQuantity.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: Text(
          'تعديل كمية ${color.colorArabicName}',
          style: GoogleFonts.cairo(color: const Color(0xFFffd700)),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: GoogleFonts.cairo(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'الكمية الجديدة',
            labelStyle: GoogleFonts.cairo(color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFffd700)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final newQuantity = int.tryParse(controller.text);
              if (newQuantity != null && newQuantity >= 0) {
                Navigator.pop(context);
                _updateColorQuantity(color, newQuantity);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFffd700),
            ),
            child: Text('حفظ', style: GoogleFonts.cairo(color: const Color(0xFF1a1a2e))),
          ),
        ],
      ),
    );
  }
}
