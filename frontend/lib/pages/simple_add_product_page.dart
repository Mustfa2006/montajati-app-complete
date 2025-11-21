import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../services/basic_product_service.dart';
import '../services/simple_product_service.dart';
import '../services/smart_colors_service.dart';
import '../services/smart_inventory_manager.dart';
import '../widgets/smart_color_picker.dart';

class SimpleAddProductPage extends StatefulWidget {
  const SimpleAddProductPage({super.key});

  @override
  State<SimpleAddProductPage> createState() => _SimpleAddProductPageState();
}

class _SimpleAddProductPageState extends State<SimpleAddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _wholesalePriceController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  final _stockQuantityController = TextEditingController(text: '100');
  final _availableFromController = TextEditingController(text: '90');
  final _availableToController = TextEditingController(text: '80');

  String _selectedCategory = 'عام';
  List<XFile> _selectedImages = [];
  bool _isLoading = false;
  List<ProductColorInput> _selectedColors = []; // الألوان المختارة

  // 🎯 نظام التبليغات الذكي
  final List<String> _notificationTags = []; // قائمة التبليغات
  final TextEditingController _notificationController = TextEditingController();

  final List<String> _categories = [
    'عام',
    'إلكترونيات',
    'ملابس',
    'طعام ومشروبات',
    'منزل وحديقة',
    'رياضة',
    'جمال وعناية',
    'كتب',
    'ألعاب',
    'أخرى',
  ];

  @override
  void initState() {
    super.initState();

    // إضافة مستمع لحقل الكمية الإجمالية لحساب النطاق الذكي
    _stockQuantityController.addListener(_calculateSmartRange);
  }

  @override
  void dispose() {
    _stockQuantityController.removeListener(_calculateSmartRange);
    super.dispose();
  }

  // 🎯 إضافة تبليغ جديد
  void _addNotificationTag() {
    final tag = _notificationController.text.trim();
    if (tag.isNotEmpty && !_notificationTags.contains(tag) && _notificationTags.length < 5) {
      setState(() {
        _notificationTags.add(tag);
        _notificationController.clear();
      });
    }
  }

  // 🎯 حذف تبليغ
  void _removeNotificationTag(int index) {
    setState(() {
      _notificationTags.removeAt(index);
    });
  }

  /// حساب النطاق الذكي تلقائياً عند تغيير الكمية الإجمالية
  void _calculateSmartRange() {
    final totalQuantityText = _stockQuantityController.text;
    if (totalQuantityText.isNotEmpty) {
      final totalQuantity = int.tryParse(totalQuantityText);
      if (totalQuantity != null && totalQuantity > 0) {
        // استخدام النظام الذكي لحساب النطاق
        final smartRange = SmartInventoryManager.calculateSmartRange(totalQuantity);

        // تحديث الحقول تلقائياً
        setState(() {
          _availableFromController.text = smartRange['min'].toString();
          _availableToController.text = smartRange['max'].toString();
        });

        debugPrint('🧠 تم حساب النطاق الذكي: من ${smartRange['min']} إلى ${smartRange['max']}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        title: Text(
          'إضافة منتج جديد',
          style: GoogleFonts.cairo(color: const Color(0xFFffd700), fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF16213e),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFffd700)),
          onPressed: () => context.go('/admin'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // اسم المنتج
              _buildTextField(
                controller: _nameController,
                label: 'اسم المنتج',
                icon: FontAwesomeIcons.tag,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'يرجى إدخال اسم المنتج';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // الوصف
              _buildTextField(
                controller: _descriptionController,
                label: 'وصف المنتج • يتوسع تلقائياً مع النص',
                icon: FontAwesomeIcons.alignLeft,
                expandable: true,
                minLines: 3,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'يرجى إدخال وصف المنتج';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // الأسعار
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _wholesalePriceController,
                      label: 'سعر الجملة',
                      icon: FontAwesomeIcons.dollarSign,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'مطلوب';
                        if (double.tryParse(value!) == null) {
                          return 'رقم غير صحيح';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _minPriceController,
                      label: 'الحد الأدنى',
                      icon: FontAwesomeIcons.arrowDown,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _maxPriceController,
                      label: 'الحد الأعلى',
                      icon: FontAwesomeIcons.arrowUp,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // الفئة
              _buildDropdown(),
              const SizedBox(height: 20),

              // الكمية المخزونة مع النظام الذكي
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213e),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF4CAF50), width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(FontAwesomeIcons.boxesStacked, color: const Color(0xFF4CAF50), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'الكمية الإجمالية في المخزون',
                          style: GoogleFonts.cairo(
                            color: const Color(0xFF4CAF50),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'سيتم حساب النطاق الذكي تلقائياً عند تغيير هذا الرقم',
                      style: GoogleFonts.cairo(color: Colors.grey[400], fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _stockQuantityController,
                      label: 'أدخل العدد الكامل (مثال: 100)',
                      icon: FontAwesomeIcons.hashtag,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'مطلوب';
                        if (int.tryParse(value!) == null) return 'رقم غير صحيح';
                        final quantity = int.parse(value);
                        if (quantity <= 0) return 'يجب أن يكون أكبر من صفر';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // الكمية المتاحة للعرض (من - إلى)
              _buildAvailableQuantitySection(),
              const SizedBox(height: 20),

              // اختيار الصور
              _buildImagePicker(),
              const SizedBox(height: 20),

              // قسم الألوان - النظام الذكي المتطور
              SmartColorPicker(
                onColorsChanged: (colors) {
                  setState(() {
                    _selectedColors = colors;
                  });
                },
                initialColors: _selectedColors,
              ),
              const SizedBox(height: 20),

              // 🎯 قسم التبليغات الذكي
              _buildNotificationSection(),
              const SizedBox(height: 30),

              // زر الحفظ
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFffd700),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Color(0xFF1a1a2e))
                      : Text(
                          'حفظ المنتج',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1a1a2e),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    int? minLines,
    bool expandable = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: TextFormField(
        controller: controller,
        maxLines: expandable ? null : maxLines,
        minLines: expandable ? (minLines ?? 3) : null,
        keyboardType: keyboardType,
        validator: validator,
        style: GoogleFonts.cairo(color: Colors.white),
        textAlignVertical: expandable ? TextAlignVertical.top : TextAlignVertical.center,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.cairo(color: const Color(0xFFffd700)),
          prefixIcon: Icon(icon, color: const Color(0xFFffd700)),
          filled: true,
          fillColor: const Color(0xFF16213e),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFFffd700)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFFffd700)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFFffd700), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFffd700)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          dropdownColor: const Color(0xFF16213e),
          style: GoogleFonts.cairo(color: Colors.white),
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFffd700)),
          items: _categories.map((category) {
            return DropdownMenuItem(value: category, child: Text(category));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value!;
            });
          },
        ),
      ),
    );
  }

  // 🎯 بناء قسم التبليغات الذكي
  Widget _buildNotificationSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF6B73FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.campaign_rounded, color: const Color(0xFF6B73FF), size: 20),
              const SizedBox(width: 8),
              Text(
                'التبليغات الذكية',
                style: GoogleFonts.cairo(color: const Color(0xFF6B73FF), fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'أضف تبليغات تظهر على بطاقة المنتج (مثل: قابل للتجديد، عليها طلب، جديد)',
            style: GoogleFonts.cairo(color: Colors.grey[400], fontSize: 12),
          ),
          const SizedBox(height: 15),

          // حقل إضافة تبليغ جديد
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _notificationController,
                  style: GoogleFonts.cairo(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'اكتب التبليغ هنا...',
                    hintStyle: GoogleFonts.cairo(color: Colors.grey[500]),
                    filled: true,
                    fillColor: const Color(0xFF1a1a2e),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[600]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[600]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF6B73FF)),
                    ),
                  ),
                  maxLength: 20, // حد أقصى للطول
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _addNotificationTag,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B73FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // عرض التبليغات المضافة
          if (_notificationTags.isNotEmpty) ...[
            Text(
              'التبليغات المضافة:',
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _notificationTags.asMap().entries.map((entry) {
                final index = entry.key;
                final tag = entry.value;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6B73FF).withValues(alpha: 0.8),
                        const Color(0xFF9D4EDD).withValues(alpha: 0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tag,
                        style: GoogleFonts.cairo(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _removeNotificationTag(index),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[800]?.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[600]!),
              ),
              child: Center(
                child: Text(
                  'لم يتم إضافة تبليغات بعد',
                  style: GoogleFonts.cairo(color: Colors.grey[400], fontSize: 14),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            '💡 ملاحظة: إذا أضفت أكثر من تبليغ، ستتقلب كل 4 ثواني على بطاقة المنتج',
            style: GoogleFonts.cairo(color: Colors.orange, fontSize: 11, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableQuantitySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFffd700)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FontAwesomeIcons.brain, color: const Color(0xFFffd700), size: 20),
              const SizedBox(width: 10),
              Text(
                'النطاق الذكي للمخزون',
                style: GoogleFonts.cairo(color: const Color(0xFFffd700), fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'يتم حساب النطاق تلقائياً بناءً على الكمية الإجمالية',
            style: GoogleFonts.cairo(color: Colors.grey[400], fontSize: 12),
          ),
          const SizedBox(height: 15),

          // مؤشر النطاق الذكي
          if (_stockQuantityController.text.isNotEmpty && int.tryParse(_stockQuantityController.text) != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(FontAwesomeIcons.lightbulb, color: const Color(0xFF4CAF50), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'تم حساب النطاق تلقائياً بناءً على ${_stockQuantityController.text} قطعة',
                      style: GoogleFonts.cairo(
                        color: const Color(0xFF4CAF50),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _availableFromController,
                  label: 'من',
                  icon: FontAwesomeIcons.arrowRight,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'مطلوب';
                    if (int.tryParse(value!) == null) return 'رقم غير صحيح';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 15),
              Text(
                'إلى',
                style: GoogleFonts.cairo(color: const Color(0xFFffd700), fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildTextField(
                  controller: _availableToController,
                  label: 'إلى',
                  icon: FontAwesomeIcons.arrowLeft,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'مطلوب';
                    if (int.tryParse(value!) == null) {
                      return 'رقم غير صحيح';
                    }

                    // تم إزالة التحقق من العلاقة بين "من" و "إلى" للسماح بأي قيم
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '💡 ملاحظة: يمكنك تحديد أي نطاق تريده - النظام مرن ويدعم جميع القيم',
            style: GoogleFonts.cairo(color: Colors.orange, fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFffd700)),
      ),
      child: Column(
        children: [
          Text(
            'صور المنتج',
            style: GoogleFonts.cairo(color: const Color(0xFFffd700), fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(FontAwesomeIcons.camera),
            label: Text('اختيار الصور', style: GoogleFonts.cairo()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFffd700),
              foregroundColor: const Color(0xFF1a1a2e),
            ),
          ),
          if (_selectedImages.isNotEmpty) ...[
            const SizedBox(height: 15),
            Row(
              children: [
                Icon(FontAwesomeIcons.images, color: const Color(0xFFffd700), size: 16),
                const SizedBox(width: 8),
                Text(
                  'الصور المختارة (${_selectedImages.length})',
                  style: GoogleFonts.cairo(color: const Color(0xFFffd700), fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFffd700).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.3)),
              ),
              child: Text(
                '💡 الصورة الأولى ستكون الصورة الرئيسية للمنتج',
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            _buildImagePreview(),
          ] else ...[
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[600]!, style: BorderStyle.solid),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(FontAwesomeIcons.images, size: 30, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'لم يتم اختيار صور بعد',
                      style: GoogleFonts.cairo(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'اضغط على "اختيار الصور" أعلاه',
                      style: GoogleFonts.cairo(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages = images;
      });
    }
  }

  // دالة معاينة الصور
  Widget _buildImagePreview() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _selectedImages.asMap().entries.map((entry) {
        final index = entry.key;
        final image = entry.value;
        final isMainImage = index == 0;

        return GestureDetector(
          onTap: () => _setAsMainImage(index),
          child: Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isMainImage ? const Color(0xFFffd700) : Colors.grey[300]!,
                    width: isMainImage ? 2 : 1,
                  ),
                  boxShadow: isMainImage
                      ? [
                          BoxShadow(
                            color: const Color(0xFFffd700).withValues(alpha: 0.3),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: ClipRRect(borderRadius: BorderRadius.circular(8), child: _buildImageWidget(image)),
              ),

              // شارة الصورة الرئيسية
              if (isMainImage)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFffd700), borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      'رئيسية',
                      style: GoogleFonts.cairo(fontSize: 8, color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

              // زر الحذف
              Positioned(
                top: 4,
                left: 4,
                child: GestureDetector(
                  onTap: () => _removeImage(index),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: const Icon(FontAwesomeIcons.xmark, color: Colors.white, size: 10),
                  ),
                ),
              ),

              // رقم الصورة
              Positioned(
                bottom: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.cairo(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // دالة بناء عنصر الصورة
  Widget _buildImageWidget(XFile image) {
    if (image.path.startsWith('http')) {
      return Image.network(
        image.path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Icon(FontAwesomeIcons.image, color: Colors.grey),
          );
        },
      );
    } else {
      // صورة محلية - استخدام FutureBuilder لقراءة البيانات
      return FutureBuilder<Uint8List>(
        future: image.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Icon(FontAwesomeIcons.image, color: Colors.grey),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Container(
              color: Colors.grey[300],
              child: const Icon(FontAwesomeIcons.image, color: Colors.grey),
            );
          } else {
            return Container(
              color: Colors.grey[100],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFffd700)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('تحميل...', style: GoogleFonts.cairo(fontSize: 8, color: Colors.grey[600])),
                  ],
                ),
              ),
            );
          }
        },
      );
    }
  }

  // دالة تحديد الصورة الرئيسية
  void _setAsMainImage(int index) {
    if (index == 0) return;

    setState(() {
      final selectedImage = _selectedImages.removeAt(index);
      _selectedImages.insert(0, selectedImage);
    });

    // طباعة معلومات تشخيصية
    debugPrint('🔄 تم تحديد الصورة رقم ${index + 1} كصورة رئيسية');
    debugPrint('📋 ترتيب الصور الحالي:');
    for (int i = 0; i < _selectedImages.length; i++) {
      debugPrint('  ${i + 1}. ${_selectedImages[i].name} ${i == 0 ? '(رئيسية)' : ''}');
    }

    _showSuccessSnackBar('✅ تم تحديد الصورة كصورة رئيسية');
  }

  // دالة حذف صورة
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });

    _showSuccessSnackBar('تم حذف الصورة');
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('يرجى ملء جميع الحقول المطلوبة');
      return;
    }

    if (_selectedImages.isEmpty) {
      _showErrorSnackBar('يرجى اختيار صورة واحدة على الأقل');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // طباعة ترتيب الصور قبل الحفظ
      debugPrint('📋 ترتيب الصور قبل الحفظ:');
      for (int i = 0; i < _selectedImages.length; i++) {
        debugPrint('  ${i + 1}. ${_selectedImages[i].name} ${i == 0 ? '(رئيسية)' : ''}');
      }
      final wholesalePrice = double.parse(_wholesalePriceController.text);
      final minPrice = _minPriceController.text.isNotEmpty ? double.parse(_minPriceController.text) : wholesalePrice;
      final maxPrice = _maxPriceController.text.isNotEmpty
          ? double.parse(_maxPriceController.text)
          : wholesalePrice * 1.5;
      final stockQuantity = int.parse(_stockQuantityController.text);
      final availableFrom = int.parse(_availableFromController.text);
      final availableTo = int.parse(_availableToController.text);

      // جرب الخدمة الجديدة أولاً، وإذا فشلت استخدم الخدمة الأساسية
      Map<String, dynamic> result;

      try {
        result = await SimpleProductService.addProduct(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          wholesalePrice: wholesalePrice,
          minPrice: minPrice,
          maxPrice: maxPrice,
          images: _selectedImages,
          category: _selectedCategory,
          stockQuantity: stockQuantity,
          availableFrom: availableFrom,
          availableTo: availableTo,
          notificationTags: _notificationTags.isNotEmpty ? _notificationTags : null, // 🎯 إضافة التبليغات
        );
      } catch (e) {
        // إذا فشلت الخدمة الجديدة، استخدم الخدمة الأساسية
        debugPrint('⚠️ فشل في الخدمة الجديدة، التبديل للخدمة الأساسية: $e');
        result = await BasicProductService.addProduct(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          wholesalePrice: wholesalePrice,
          minPrice: minPrice,
          maxPrice: maxPrice,
          images: _selectedImages,
          category: _selectedCategory,
          stockQuantity: stockQuantity,
        );
      }

      if (result['success']) {
        // إضافة الألوان إذا كانت متوفرة
        if (_selectedColors.isNotEmpty && result['product_id'] != null) {
          await _saveProductColors(result['product_id']);
        }

        _showSuccessSnackBar('✅ تم إضافة المنتج بنجاح!');
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) context.go('/admin');
        });
      } else {
        _showErrorSnackBar('❌ ${result['message']}');
      }
    } catch (e) {
      _showErrorSnackBar('❌ خطأ: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// حفظ ألوان المنتج بعد إنشاء المنتج
  Future<void> _saveProductColors(String productId) async {
    try {
      debugPrint('🎨 بدء حفظ ${_selectedColors.length} لون للمنتج $productId');

      for (final color in _selectedColors) {
        final result = await SmartColorsService.addColorToProduct(
          productId: productId,
          colorName: color.colorName,
          colorCode: color.colorCode,
          colorArabicName: color.colorArabicName,
          totalQuantity: color.quantity,
        );

        if (result['success']) {
          debugPrint('✅ تم حفظ اللون: ${color.colorArabicName}');
        } else {
          debugPrint('❌ فشل في حفظ اللون: ${color.colorArabicName} - ${result['error']}');
        }
      }

      debugPrint('🎨 تم الانتهاء من حفظ الألوان');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ الألوان: $e');
    }
  }
}
